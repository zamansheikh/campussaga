package voice

import (
	"strings"
	"unicode"
	"unicode/utf8"

	"golang.org/x/text/unicode/norm"
)

// wordMatcher finds abusive words (filter_words.txt) in a post, also when
// they are disguised: leetspeak (sh1t, b!tch, a$$), stretched letters
// (fuuuck), letters spaced or dotted apart (f u c k, f.u.c.k, fu ck), and
// masks (f*ck, f**king). Bangla is NFC-normalized and zero-width joiners are
// dropped first, so the same word typed on different keyboards matches.
type wordMatcher struct {
	exact  map[string]bool
	prefix []string
	infix  []string
	// The same lists with repeated letters squeezed ("asshole" → "ashole"),
	// compared only with stretched words.
	exactSq  map[string]bool
	prefixSq []string
}

// zeroWidth: characters that are invisible but split or disguise words.
var zeroWidth = strings.NewReplacer(
	"\u200b", "", "\u200c", "", "\u200d", "", "\u2060", "", "\ufeff", "", "\u00ad", "",
)

// normalizeText: NFC, no zero-width characters, lower case.
func normalizeText(s string) string {
	return strings.ToLower(norm.NFC.String(zeroWidth.Replace(s)))
}

func loadWords(list string) *wordMatcher {
	m := &wordMatcher{exact: map[string]bool{}, exactSq: map[string]bool{}}
	for _, line := range strings.Split(list, "\n") {
		w := normalizeText(strings.TrimSpace(line))
		if w == "" || strings.HasPrefix(w, "#") {
			continue
		}
		switch {
		case len(w) > 2 && strings.HasPrefix(w, "*") && strings.HasSuffix(w, "*"):
			m.infix = append(m.infix, w[1:len(w)-1])
		case strings.HasSuffix(w, "*"):
			p := strings.TrimSuffix(w, "*")
			m.prefix = append(m.prefix, p)
			if sq := squeeze(p); utf8.RuneCountInString(sq) >= 4 {
				m.prefixSq = append(m.prefixSq, sq)
			}
		default:
			m.exact[w] = true
			if sq := squeeze(w); utf8.RuneCountInString(sq) >= 4 {
				m.exactSq[sq] = true
			}
		}
	}
	return m
}

// word: is one (already normalized) word on the list?
func (m *wordMatcher) word(w string) bool {
	if m.exact[w] {
		return true
	}
	for _, p := range m.prefix {
		if strings.HasPrefix(w, p) {
			return true
		}
	}
	for _, i := range m.infix {
		if strings.Contains(w, i) {
			return true
		}
	}
	return false
}

// stretched: a word squeezed after someone stretched it (3+ same letters).
func (m *wordMatcher) stretched(w string) bool {
	sq := squeeze(w)
	if m.exactSq[sq] {
		return true
	}
	for _, p := range m.prefixSq {
		if strings.HasPrefix(sq, p) {
			return true
		}
	}
	return false
}

// masked: "f*ck", "f**king", "sh#t" — '*' or '#' stand for one letter each.
func (m *wordMatcher) masked(w string) bool {
	r := []rune(w)
	letters, masks := 0, 0
	for _, c := range r {
		if c == '*' || c == '#' {
			masks++
		} else {
			letters++
		}
	}
	// At least 4 characters, more letters than masks ("a*s" stays innocent).
	if len(r) < 4 || masks == 0 || letters <= masks {
		return false
	}
	fits := func(entry []rune) bool {
		for i, c := range entry {
			if r[i] != '*' && r[i] != '#' && r[i] != c {
				return false
			}
		}
		return true
	}
	for e := range m.exact {
		if er := []rune(e); len(er) == len(r) && fits(er) {
			return true
		}
	}
	for _, p := range m.prefix {
		if pr := []rune(p); len(pr) >= 4 && len(pr) <= len(r) && fits(pr) {
			return true
		}
	}
	return false
}

// leet turns look-alike digits and symbols into the letters they stand for.
var leet = strings.NewReplacer(
	"0", "o", "1", "i", "3", "e", "4", "a", "5", "s", "7", "t", "8", "b",
	"@", "a", "$", "s", "!", "i", "|", "l",
)

// isWordRune: letters, Bangla vowel signs and digits, plus the symbols
// people use to disguise letters.
func isWordRune(r rune) bool {
	return unicode.IsLetter(r) || unicode.IsMark(r) || unicode.IsDigit(r) || strings.ContainsRune("@$!*#|", r)
}

// letterCount counts base letters (a Bangla letter with its vowel sign is one).
func letterCount(w string) int {
	n := 0
	for _, r := range w {
		if unicode.IsLetter(r) {
			n++
		}
	}
	return n
}

func hasRun(w string, n int) bool {
	var prev rune
	run := 0
	for _, r := range w {
		if r == prev {
			run++
			if run >= n {
				return true
			}
		} else {
			prev, run = r, 1
		}
	}
	return false
}

// squeeze collapses repeated letters: "fuuuuck" → "fuck".
func squeeze(w string) string {
	var b strings.Builder
	var prev rune = -1
	for _, r := range w {
		if r != prev {
			b.WriteRune(r)
		}
		prev = r
	}
	return b.String()
}

// variants of one written word: as typed, with leetspeak read as letters,
// and with disguising symbols dropped.
func variants(t string) []string {
	out := []string{t}
	if l := leet.Replace(t); l != t {
		out = append(out, l)
	}
	if strings.ContainsAny(t, "@$!*#|") {
		out = append(out, strings.Map(func(r rune) rune {
			if strings.ContainsRune("@$!*#|", r) {
				return -1
			}
			return r
		}, t))
	}
	return out
}

// matches: does the text contain a listed word, however disguised?
func (m *wordMatcher) matches(text string) bool {
	raw := strings.FieldsFunc(normalizeText(text), func(r rune) bool { return !isWordRune(r) })
	var chunks []string // the current run of short pieces ("f", "u", "ck")
	checkChunks := func() bool {
		defer func() { chunks = chunks[:0] }()
		if len(chunks) < 2 {
			return false
		}
		// Join whole pieces: "f u c k" → "fuck", "fu ck" → "fuck". Single
		// letters may make a 3-letter word ("a s s"); otherwise 4 or more.
		for i := 0; i < len(chunks); i++ {
			joined, singles := chunks[i], letterCount(chunks[i]) == 1
			for j := i + 1; j < len(chunks); j++ {
				joined += chunks[j]
				singles = singles && letterCount(chunks[j]) == 1
				n := utf8.RuneCountInString(joined) // Bangla vowel signs count
				if n < 3 || (n < 4 && !singles) {
					continue
				}
				if m.exact[joined] || m.prefixHit(joined) || (hasRun(joined, 3) && m.stretched(joined)) {
					return true
				}
			}
		}
		return false
	}
	for _, t := range raw {
		// Symbols around a word are punctuation ("Bastard!", "*sigh*"), but
		// $ and @ at the start stand for letters ("$hit", "@ss").
		t = strings.TrimRight(t, "!*#|")
		t = strings.TrimLeft(t, "!*#|")
		if t == "" || letterCount(t) == 0 {
			// Numbers ("CSE 101") end a run of pieces.
			if checkChunks() {
				return true
			}
			continue
		}
		for _, v := range variants(t) {
			if strings.ContainsAny(v, "*#") {
				if m.masked(v) {
					return true
				}
				continue
			}
			if m.word(v) || (hasRun(v, 3) && m.stretched(v)) {
				return true
			}
		}
		// Short pieces may be one word typed apart.
		if letterCount(t) <= 2 {
			piece := leet.Replace(t)
			chunks = append(chunks, piece)
			continue
		}
		if checkChunks() {
			return true
		}
	}
	return checkChunks()
}

func (m *wordMatcher) prefixHit(w string) bool {
	for _, p := range m.prefix {
		if strings.HasPrefix(w, p) {
			return true
		}
	}
	return false
}
