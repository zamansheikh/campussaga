// Blood donation (docs/BLOOD_DONATION.md): students post requests; donors
// of the same group at the university are told and can respond.

/// The eight ABO/Rh groups (wire: "A+", "O-", …).
enum BloodGroup {
  aPos('A+'),
  aNeg('A-'),
  bPos('B+'),
  bNeg('B-'),
  abPos('AB+'),
  abNeg('AB-'),
  oPos('O+'),
  oNeg('O-');

  const BloodGroup(this.wire);

  final String wire;

  /// "A−" with a real minus sign, for display.
  String get label => wire.replaceAll('-', '−');

  static BloodGroup? parse(String? v) {
    for (final g in values) {
      if (g.wire == v) return g;
    }
    return null;
  }

  /// Who can give red cells to a patient of this group (spec §1 table).
  List<BloodGroup> get canReceiveFrom => switch (this) {
    oNeg => const [oNeg],
    oPos => const [oPos, oNeg],
    aNeg => const [aNeg, oNeg],
    aPos => const [aPos, aNeg, oPos, oNeg],
    bNeg => const [bNeg, oNeg],
    bPos => const [bPos, bNeg, oPos, oNeg],
    abNeg => const [abNeg, aNeg, bNeg, oNeg],
    abPos => values,
  };
}

/// Days between two donations (Bangladesh: every 4 months).
const donationGapDays = 120;

DateTime _time(Object? v) =>
    DateTime.tryParse(v as String? ?? '')?.toLocal() ??
    DateTime.fromMillisecondsSinceEpoch(0);

DateTime? _date(Object? v) {
  if (v is! String || v.isEmpty) return null;
  final d = DateTime.tryParse(v);
  return d == null ? null : DateTime(d.year, d.month, d.day);
}

String _dateWire(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// The caller's own donor profile.
class Donor {
  const Donor({
    required this.bloodGroup,
    this.available = true,
    this.phone = '',
    this.lastDonated,
    this.donations = 0,
    this.canDonateFrom,
    this.eligible = true,
  });

  factory Donor.fromJson(Map<String, Object?> json) => Donor(
    bloodGroup:
        BloodGroup.parse(json['bloodGroup'] as String?) ?? BloodGroup.oPos,
    available: json['available'] as bool? ?? true,
    phone: json['phone'] as String? ?? '',
    lastDonated: _date(json['lastDonated']),
    donations: (json['donations'] as num?)?.toInt() ?? 0,
    canDonateFrom: _date(json['canDonateFrom']),
    eligible: json['eligible'] as bool? ?? true,
  );

  final BloodGroup bloodGroup;

  /// Wants to hear about requests.
  final bool available;
  final String phone;
  final DateTime? lastDonated;
  final int donations;

  /// The day they can give again; null = now.
  final DateTime? canDonateFrom;

  /// Available and enough time since the last donation.
  final bool eligible;

  Map<String, Object?> toJson() => {
    'bloodGroup': bloodGroup.wire,
    'available': available,
    'phone': phone,
    'lastDonated': lastDonated == null ? null : _dateWire(lastDonated!),
    'donations': donations,
    'canDonateFrom': canDonateFrom == null ? null : _dateWire(canDonateFrom!),
    'eligible': eligible,
  };
}

/// What the student sends to become (or edit) a donor.
class DonorInput {
  const DonorInput({
    required this.bloodGroup,
    this.available = true,
    this.phone = '',
    this.lastDonated,
  });

  final BloodGroup bloodGroup;
  final bool available;
  final String phone;
  final DateTime? lastDonated;

  Map<String, Object?> toJson() => {
    'bloodGroup': bloodGroup.wire,
    'available': available,
    'phone': phone.trim(),
    'lastDonated': lastDonated == null ? null : _dateWire(lastDonated!),
  };
}

enum BloodRequestStatus {
  open,
  fulfilled,
  closed,
  expired;

  static BloodRequestStatus parse(String? v) =>
      values.firstWhere((s) => s.name == v, orElse: () => closed);
}

/// A donor who said "I can donate" (only the requester sees these).
class BloodResponse {
  const BloodResponse({
    required this.name,
    required this.phone,
    required this.createdAt,
    this.bloodGroup,
  });

  factory BloodResponse.fromJson(Map<String, Object?> json) => BloodResponse(
    name: json['name'] as String? ?? '',
    bloodGroup: BloodGroup.parse(json['bloodGroup'] as String?),
    phone: json['phone'] as String? ?? '',
    createdAt: _time(json['createdAt']),
  );

  final String name;
  final BloodGroup? bloodGroup;
  final String phone;
  final DateTime createdAt;
}

/// A request for blood at the university.
class BloodRequest {
  const BloodRequest({
    required this.id,
    required this.bloodGroup,
    required this.hospital,
    required this.neededBy,
    required this.contactName,
    required this.contactPhone,
    required this.createdAt,
    this.units = 1,
    this.area = '',
    this.urgent = false,
    this.note = '',
    this.status = BloodRequestStatus.open,
    this.responseCount = 0,
    this.notified = 0,
    this.matchingDonors = 0,
    this.mine = false,
    this.responded = false,
    this.responses = const [],
  });

  factory BloodRequest.fromJson(Map<String, Object?> json) => BloodRequest(
    id: json['id']! as String,
    bloodGroup:
        BloodGroup.parse(json['bloodGroup'] as String?) ?? BloodGroup.oPos,
    units: (json['units'] as num?)?.toInt() ?? 1,
    hospital: json['hospital'] as String? ?? '',
    area: json['area'] as String? ?? '',
    neededBy: _time(json['neededBy']),
    urgent: json['urgent'] as bool? ?? false,
    contactName: json['contactName'] as String? ?? '',
    contactPhone: json['contactPhone'] as String? ?? '',
    note: json['note'] as String? ?? '',
    status: BloodRequestStatus.parse(json['status'] as String?),
    createdAt: _time(json['createdAt']),
    responseCount: (json['responseCount'] as num?)?.toInt() ?? 0,
    notified: (json['notified'] as num?)?.toInt() ?? 0,
    matchingDonors: (json['matchingDonors'] as num?)?.toInt() ?? 0,
    mine: json['mine'] as bool? ?? false,
    responded: json['responded'] as bool? ?? false,
    responses: [
      for (final r in json['responses'] as List<Object?>? ?? const [])
        if (r is Map<String, Object?>) BloodResponse.fromJson(r),
    ],
  );

  final String id;
  final BloodGroup bloodGroup;
  final int units;
  final String hospital;
  final String area;
  final DateTime neededBy;
  final bool urgent;
  final String contactName;
  final String contactPhone;

  /// Why (thalassemia, surgery…).
  final String note;
  final BloodRequestStatus status;
  final DateTime createdAt;
  final int responseCount;

  /// Donors told by push (shown to the requester).
  final int notified;

  /// Donors of this group at the university (a count only).
  final int matchingDonors;
  final bool mine;

  /// The caller said "I can donate".
  final bool responded;

  /// Only for the requester.
  final List<BloodResponse> responses;

  bool get isOpen => status == BloodRequestStatus.open;
}

/// A new request.
class BloodRequestDraft {
  const BloodRequestDraft({
    required this.bloodGroup,
    required this.hospital,
    required this.neededBy,
    required this.contactName,
    required this.contactPhone,
    this.units = 1,
    this.area = '',
    this.urgent = false,
    this.note = '',
  });

  final BloodGroup bloodGroup;
  final int units;
  final String hospital;
  final String area;
  final DateTime neededBy;
  final bool urgent;
  final String contactName;
  final String contactPhone;
  final String note;

  static const maxUnits = 10;
  static const maxHospital = 120;
  static const maxArea = 80;
  static const maxNote = 500;

  Map<String, Object?> toJson() => {
    'bloodGroup': bloodGroup.wire,
    'units': units,
    'hospital': hospital.trim(),
    'area': area.trim(),
    'neededBy': neededBy.toUtc().toIso8601String(),
    'urgent': urgent,
    'contactName': contactName.trim(),
    'contactPhone': contactPhone.trim(),
    'note': note.trim(),
  };
}

/// One page of requests; [nextCursor] null = the end.
class BloodRequestList {
  const BloodRequestList(this.items, [this.nextCursor]);

  final List<BloodRequest> items;
  final String? nextCursor;
}
