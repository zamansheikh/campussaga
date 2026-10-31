import 'package:campus_core/campus_core.dart';
import 'package:varsitykotha/app/clock.dart';

/// A request for tests.
BloodRequest sampleBloodRequest({
  String id = 'b1',
  BloodGroup group = BloodGroup.aPos,
  bool urgent = true,
  bool mine = false,
  bool responded = false,
  DateTime? neededBy,
  List<BloodResponse> responses = const [],
}) => BloodRequest(
  id: id,
  bloodGroup: group,
  units: 2,
  hospital: 'Enam Medical College Hospital',
  area: 'Savar',
  neededBy: neededBy ?? DateTime(2026, 10, 27, 15),
  urgent: urgent,
  contactName: 'Nusrat',
  contactPhone: '01812345678',
  note: 'Thalassemia patient',
  createdAt: DateTime(2026, 10, 27, 9),
  matchingDonors: 14,
  mine: mine,
  responded: responded,
  responses: responses,
  responseCount: responses.length,
);

/// In-memory blood donation.
class FakeBloodRepository implements BloodRepository {
  Donor? donor;
  final all = <BloodRequest>[];
  final created = <BloodRequestDraft>[];
  final responses = <(String, String)>[];

  /// Donors "told" about a new request.
  int notifyCount = 14;
  Failure? failure;
  var _ids = 0;

  void _check() {
    if (failure != null) throw failure!;
  }

  BloodRequest _find(String id) => all.firstWhere(
    (r) => r.id == id,
    orElse: () => throw const NotFoundFailure(code: 'BLOOD_REQUEST_NOT_FOUND'),
  );

  void _put(BloodRequest r) {
    final at = all.indexWhere((x) => x.id == r.id);
    if (at < 0) {
      all.insert(0, r);
    } else {
      all[at] = r;
    }
  }

  BloodRequest _copy(
    BloodRequest r, {
    BloodRequestStatus? status,
    bool? responded,
    int? responseCount,
  }) => BloodRequest(
    id: r.id,
    bloodGroup: r.bloodGroup,
    units: r.units,
    hospital: r.hospital,
    area: r.area,
    neededBy: r.neededBy,
    urgent: r.urgent,
    contactName: r.contactName,
    contactPhone: r.contactPhone,
    note: r.note,
    status: status ?? r.status,
    createdAt: r.createdAt,
    responseCount: responseCount ?? r.responseCount,
    notified: r.notified,
    matchingDonors: r.matchingDonors,
    mine: r.mine,
    responded: responded ?? r.responded,
    responses: r.responses,
  );

  @override
  Future<Donor?> me() async {
    _check();
    return donor;
  }

  @override
  Future<Donor> saveDonor(DonorInput input) async {
    _check();
    final last = input.lastDonated;
    final from = last?.add(const Duration(days: donationGapDays));
    final today = appNow();
    final waiting = from != null && from.isAfter(today);
    return donor = Donor(
      bloodGroup: input.bloodGroup,
      available: input.available,
      phone: input.phone,
      lastDonated: last,
      donations: donor?.donations ?? 0,
      canDonateFrom: waiting ? from : null,
      eligible: input.available && !waiting,
    );
  }

  @override
  Future<void> leaveDonors() async {
    _check();
    donor = null;
  }

  @override
  Future<Donor> donated({DateTime? date}) async {
    _check();
    final d = donor!;
    final day = date ?? appNow();
    return donor = Donor(
      bloodGroup: d.bloodGroup,
      available: d.available,
      phone: d.phone,
      lastDonated: day,
      donations: d.donations + 1,
      canDonateFrom: day.add(const Duration(days: donationGapDays)),
      eligible: false,
    );
  }

  @override
  Future<BloodRequestList> requests({
    bool mine = false,
    BloodGroup? group,
    String? cursor,
  }) async {
    _check();
    return BloodRequestList([
      for (final r in all)
        if (mine
            ? r.mine
            : r.isOpen && (group == null || r.bloodGroup == group))
          r,
    ]);
  }

  @override
  Future<BloodRequest> request(String id) async {
    _check();
    return _find(id);
  }

  @override
  Future<BloodRequest> create(BloodRequestDraft draft) async {
    _check();
    created.add(draft);
    final r = BloodRequest(
      id: 'new${++_ids}',
      bloodGroup: draft.bloodGroup,
      units: draft.units,
      hospital: draft.hospital.trim(),
      area: draft.area.trim(),
      neededBy: draft.neededBy,
      urgent: draft.urgent,
      contactName: draft.contactName.trim(),
      contactPhone: draft.contactPhone,
      note: draft.note.trim(),
      createdAt: appNow(),
      notified: notifyCount,
      mine: true,
    );
    _put(r);
    return r;
  }

  @override
  Future<BloodRequest> respond(String id, String phone) async {
    _check();
    if (donor == null) throw const RejectedFailure(code: 'DONOR_REQUIRED');
    responses.add((id, phone));
    final r = _find(id);
    final next = _copy(r, responded: true, responseCount: r.responseCount + 1);
    _put(next);
    return next;
  }

  @override
  Future<BloodRequest> withdraw(String id) async {
    _check();
    final r = _find(id);
    final next = _copy(r, responded: false, responseCount: r.responseCount - 1);
    _put(next);
    return next;
  }

  @override
  Future<BloodRequest> close(String id, {required bool fulfilled}) async {
    _check();
    final next = _copy(
      _find(id),
      status: fulfilled
          ? BloodRequestStatus.fulfilled
          : BloodRequestStatus.closed,
    );
    _put(next);
    return next;
  }
}
