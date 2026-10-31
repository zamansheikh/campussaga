package growth

import "encoding/json"

// Scoring is a campaign's point values (docs/GROWTH.md §8.1). A 0 turns one
// off. BusShareDays, SectionSetupMax and PioneerFirst are limits, not points;
// MinOwnCampus and MinOtherCampus are how many counted friends at my own and
// at other universities a student needs to be ranked (§8.5, 0: none).
type Scoring struct {
	Invite          int `json:"invite"`
	OtherCampus     int `json:"otherCampus"`
	Pioneer         int `json:"pioneer"`
	FriendSection   int `json:"friendSection"`
	JoinSection     int `json:"joinSection"`
	BloodDonor      int `json:"bloodDonor"`
	BusShare        int `json:"busShare"`
	BusShareDays    int `json:"busShareDays"`
	SectionSetup    int `json:"sectionSetup"`
	SectionSetupMax int `json:"sectionSetupMax"`
	PioneerFirst    int `json:"pioneerFirst"`
	MinOwnCampus    int `json:"minOwnCampus"`
	MinOtherCampus  int `json:"minOtherCampus"`
}

// eligible: in the prize race (§8.5).
func (sc Scoring) eligible(t tally) bool {
	return t.OwnCampus >= sc.MinOwnCampus && t.OtherCampus >= sc.MinOtherCampus
}

// DefaultScoring matches the column default of 00760_campaign_points.sql.
var DefaultScoring = Scoring{
	Invite: 10, OtherCampus: 5, Pioneer: 5, FriendSection: 3, JoinSection: 2, BloodDonor: 3,
	BusShare: 2, BusShareDays: 10, SectionSetup: 15, SectionSetupMax: 2, PioneerFirst: 20, MinOwnCampus: 3, MinOtherCampus: 2,
}

// Mission rules that aren't point values.
const (
	SectionSlotsNeed   = 5 // routine slots a section needs to count
	SectionMembersNeed = 5 // verified members besides the CR
	BusShareMinMinutes = 10
)

// ScoringInput is a partial Scoring: keys left out keep their value.
type ScoringInput struct {
	Invite          *int `json:"invite"`
	OtherCampus     *int `json:"otherCampus"`
	Pioneer         *int `json:"pioneer"`
	FriendSection   *int `json:"friendSection"`
	JoinSection     *int `json:"joinSection"`
	BloodDonor      *int `json:"bloodDonor"`
	BusShare        *int `json:"busShare"`
	BusShareDays    *int `json:"busShareDays"`
	SectionSetup    *int `json:"sectionSetup"`
	SectionSetupMax *int `json:"sectionSetupMax"`
	PioneerFirst    *int `json:"pioneerFirst"`
	MinOwnCampus    *int `json:"minOwnCampus"`
	MinOtherCampus  *int `json:"minOtherCampus"`
}

// mergeOver sets the given keys on base and checks the ranges.
func (in *ScoringInput) mergeOver(base Scoring) (Scoring, error) {
	out := base
	if in == nil {
		return out, nil
	}
	set := func(dst *int, v *int, lo, hi int) error {
		if v == nil {
			return nil
		}
		if *v < lo || *v > hi {
			return ErrInvalidScoring
		}
		*dst = *v
		return nil
	}
	for _, f := range []struct {
		dst    *int
		v      *int
		lo, hi int
	}{
		{&out.Invite, in.Invite, 0, 100},
		{&out.OtherCampus, in.OtherCampus, 0, 100},
		{&out.Pioneer, in.Pioneer, 0, 100},
		{&out.FriendSection, in.FriendSection, 0, 100},
		{&out.JoinSection, in.JoinSection, 0, 100},
		{&out.BloodDonor, in.BloodDonor, 0, 100},
		{&out.BusShare, in.BusShare, 0, 100},
		{&out.BusShareDays, in.BusShareDays, 0, 60},
		{&out.SectionSetup, in.SectionSetup, 0, 100},
		{&out.SectionSetupMax, in.SectionSetupMax, 0, 10},
		{&out.PioneerFirst, in.PioneerFirst, 1, 1000},
		{&out.MinOwnCampus, in.MinOwnCampus, 0, 20},
		{&out.MinOtherCampus, in.MinOtherCampus, 0, 20},
	} {
		if err := set(f.dst, f.v, f.lo, f.hi); err != nil {
			return out, err
		}
	}
	return out, nil
}

// parseScoring reads a stored value over the defaults (keys added later
// take their default).
func parseScoring(raw []byte) Scoring {
	out := DefaultScoring
	if len(raw) > 0 {
		_ = json.Unmarshal(raw, &out)
	}
	return out
}

// tally is what a participant did that earns points: counts per key.
type tally struct {
	Invites       int // counted invites
	OtherCampus   int // of them, friends at another university
	OwnCampus     int // of them, friends at my university (for eligibility, not points)
	Pioneer       int // of them, among the first students of their university
	FriendSection int // of them, friends in a class group
	JoinSection   int // 0 or 1
	BloodDonor    int // 0 or 1
	BusDays       int // already capped
	Sections      int // already capped
}

func (t tally) score(sc Scoring) int {
	return t.Invites*sc.Invite + t.OtherCampus*sc.OtherCampus + t.Pioneer*sc.Pioneer + t.FriendSection*sc.FriendSection +
		t.JoinSection*sc.JoinSection + t.BloodDonor*sc.BloodDonor + t.BusDays*sc.BusShare + t.Sections*sc.SectionSetup
}

// Points is the points per key, for the admin standings.
type Points struct {
	Invite        int `json:"invite"`
	OtherCampus   int `json:"otherCampus"`
	Pioneer       int `json:"pioneer"`
	FriendSection int `json:"friendSection"`
	JoinSection   int `json:"joinSection"`
	BloodDonor    int `json:"bloodDonor"`
	BusShare      int `json:"busShare"`
	SectionSetup  int `json:"sectionSetup"`
}

func (t tally) points(sc Scoring) Points {
	return Points{
		Invite: t.Invites * sc.Invite, OtherCampus: t.OtherCampus * sc.OtherCampus, Pioneer: t.Pioneer * sc.Pioneer,
		FriendSection: t.FriendSection * sc.FriendSection, JoinSection: t.JoinSection * sc.JoinSection,
		BloodDonor: t.BloodDonor * sc.BloodDonor, BusShare: t.BusDays * sc.BusShare, SectionSetup: t.Sections * sc.SectionSetup,
	}
}

// Mission is one way to earn points, with my progress.
type Mission struct {
	Key    string `json:"key"`
	Points int    `json:"points"`
	// Per: "friend" (each counted invite), "once", "day" (bus days),
	// "section" (each CR section that counts).
	Per    string `json:"per"`
	Count  int    `json:"count"`
	Max    *int   `json:"max"`
	Earned int    `json:"earned"`
}

// missions lists the keys worth points, in §8.1's order.
func missions(sc Scoring, t tally) []Mission {
	one := 1
	busMax, secMax := sc.BusShareDays, sc.SectionSetupMax
	rows := []struct {
		key    string
		points int
		per    string
		count  int
		max    *int
		off    bool
	}{
		{"invite", sc.Invite, "friend", t.Invites, nil, false},
		{"otherCampus", sc.OtherCampus, "friend", t.OtherCampus, nil, false},
		{"pioneer", sc.Pioneer, "friend", t.Pioneer, nil, false},
		{"friendSection", sc.FriendSection, "friend", t.FriendSection, nil, false},
		{"joinSection", sc.JoinSection, "once", t.JoinSection, &one, false},
		{"bloodDonor", sc.BloodDonor, "once", t.BloodDonor, &one, false},
		{"busShare", sc.BusShare, "day", t.BusDays, &busMax, busMax == 0},
		{"sectionSetup", sc.SectionSetup, "section", t.Sections, &secMax, secMax == 0},
	}
	out := []Mission{}
	for _, r := range rows {
		if r.points <= 0 || r.off {
			continue
		}
		out = append(out, Mission{Key: r.key, Points: r.points, Per: r.per, Count: r.count, Max: r.max, Earned: r.count * r.points})
	}
	return out
}
