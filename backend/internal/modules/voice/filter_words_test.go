package voice

import (
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
)

func TestLanguageCheckHolds(t *testing.T) {
	for _, text := range []string{
		// English, plain and inflected
		"fuck this hostel", "What the FUCK", "fucking useless", "motherfucker",
		"bullshit rules", "you dumbass", "stupid bitches", "Bastard!", "asshole guard",
		// slurs
		"nigga please", "chinki girls", "malaun",
		// disguised
		"f*ck", "F**KING", "sh*t", "fuuuuck", "shiiiiit", "f u c k", "f.u.c.k", "f-u-c-k",
		"fu ck you", "sh1t", "$hit", "b!tch", "B1TCH", "a$$hole", "@ss", "fcuk", "phuck",
		"b i t c h", "a s s",
		// Banglish
		"khanki", "Khankir pola", "khankir-pola", "madarchod", "Bokachoda",
		"tor maire chudi", "chudir bhai", "chodna", "haramjada", "haramzada",
		"shuorer baccha", "kuttar baccha", "magi", "khanki'r pola", "khanki-r", "behenchod",
		// Bangla
		"ও একটা হারামজাদা", "খানকির পোলা", "বোকাচোদা", "চুদির ভাই", "মাগি",
		"শুয়োরের বাচ্চা", "কুত্তার বাচ্চা", "বেশ্যা", "মালাউন", "চু দি",
		"শু\u200dয়োরের বাচ্চা",     // a zero-width joiner hidden inside
		"শু\u09df\u09cbরের বাচ্চা",  // য় typed as one character
		"শুয\u09bc\u09cbরের বাচ্চা", // য় typed as য + nukta
	} {
		assert.Equal(t, HoldLanguage, checkText(text), text)
	}
}

func TestLanguageCheckLetsThrough(t *testing.T) {
	for _, text := range []string{
		// English words that contain listed letters
		"Classic class assignment", "The assistant registrar", "bass guitar club",
		"Dickens novel in the library", "cocktail of chemicals", "cockroaches in the canteen",
		"Scunthorpe", "Sussex", "therapist", "analysis of the analyst", "passport office",
		"The pond near Hall 2 is dirty", "Shiite and Sunni students", "assess the assets",
		"embarrassment", "pussycat", "Matsushita", "shitake mushrooms",
		"construction and erection of the new gate",
		// complaints and safety reports must go through
		"A teacher sexually harassed a student", "rape threat in the bus",
		"someone leaked nude photos of me", "drugs sold near the gate",
		// courses, numbers, places, names
		"CSE 101 and EEE 3rd semester", "Room 402, 2nd floor", "4th year", "1st term",
		"Comilla University", "Cumilla", "Gandaria", "Magura district", "Pakistan embassy",
		"Chandpur", "Randiya", "Malaysia trip", "Fakir Lalon", "Dhanmondi",
		// short words typed apart that make nothing
		"is it ok to go", "I am at it", "grades A B C D", "u r late",
		// Bangla words that look similar
		"চৌদ্দ জন ছাত্র", "চোদ্দ জন ছাত্র", "বালতি নেই", "নতুন বালিশ", "বালু উঠছে",
		"ধন্যবাদ", "ধনী গরিব", "গুদাম ঘর", "মালামাল চুরি", "পোদ্দার স্যার",
		"কুকুর কামড়েছে", "মাগুরা জেলা", "হারানো বিজ্ঞপ্তি", "বাংলা বিভাগ",
	} {
		assert.Equal(t, "", checkText(text), text)
	}
}

func TestLanguageCheckIsFast(t *testing.T) {
	long := strings.Repeat("The water pump in Hall 2 is broken again, ক্লাস হয়নি আজ। f u n 1 2 3 ", 200)
	start := time.Now()
	for range 20 {
		checkText(long)
	}
	// Catches runaway matching (seconds), not small slowdowns: CI runs with
	// the race detector, several times slower than production (~10 ms here).
	assert.Less(t, time.Since(start)/20, 500*time.Millisecond, "a long post checks quickly")
}
