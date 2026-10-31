import 'blood_models.dart';

/// Blood donation API (docs/BLOOD_DONATION.md §3). Every call throws a
/// `Failure`.
abstract interface class BloodRepository {
  /// The caller's donor profile, or null.
  Future<Donor?> me();

  Future<Donor> saveDonor(DonorInput input);

  /// Stop being a donor.
  Future<void> leaveDonors();

  /// Gave blood on [date] (default today).
  Future<Donor> donated({DateTime? date});

  /// Open requests at the university (urgent first, then soonest), or the
  /// caller's own ([mine]).
  Future<BloodRequestList> requests({
    bool mine = false,
    BloodGroup? group,
    String? cursor,
  });

  Future<BloodRequest> request(String id);

  Future<BloodRequest> create(BloodRequestDraft draft);

  /// "I can donate": [phone] goes to the requester.
  Future<BloodRequest> respond(String id, String phone);

  Future<BloodRequest> withdraw(String id);

  /// The requester: got blood ([fulfilled]) or cancelled.
  Future<BloodRequest> close(String id, {required bool fulfilled});
}
