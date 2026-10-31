package blood

import "slices"

// compatible lists the groups whose red cells a patient of that group can
// receive (docs/BLOOD_DONATION.md §1). Information only: pushes go to the
// same group.
var compatible = map[string][]string{
	"O-":  {"O-"},
	"O+":  {"O+", "O-"},
	"A-":  {"A-", "O-"},
	"A+":  {"A+", "A-", "O+", "O-"},
	"B-":  {"B-", "O-"},
	"B+":  {"B+", "B-", "O+", "O-"},
	"AB-": {"AB-", "A-", "B-", "O-"},
	"AB+": {"A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"},
}

// CompatibleDonors reports the groups a patient of group can receive from.
func CompatibleDonors(group string) []string { return slices.Clone(compatible[group]) }
