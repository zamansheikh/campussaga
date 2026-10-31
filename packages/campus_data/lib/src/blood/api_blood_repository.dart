import 'package:campus_core/campus_core.dart';

import '../api_client.dart';

/// Blood donation over HTTP (docs/BLOOD_DONATION.md §3).
class ApiBloodRepository implements BloodRepository {
  ApiBloodRepository(this._api);

  final ApiClient _api;

  static Map<String, Object?> _map(Object? v) => v! as Map<String, Object?>;

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  Future<Donor?> me() async {
    final donor = _map(await _api.get('/blood/me'))['donor'];
    return donor is Map<String, Object?> ? Donor.fromJson(donor) : null;
  }

  @override
  Future<Donor> saveDonor(DonorInput input) async =>
      Donor.fromJson(_map(await _api.put('/blood/me', input.toJson())));

  @override
  Future<void> leaveDonors() => _api.delete('/blood/me');

  @override
  Future<Donor> donated({DateTime? date}) async => Donor.fromJson(
    _map(
      await _api.post('/blood/me/donated', {
        'date': ?date == null ? null : _date(date),
      }),
    ),
  );

  @override
  Future<BloodRequestList> requests({
    bool mine = false,
    BloodGroup? group,
    String? cursor,
  }) async {
    final q = {
      'view': mine ? 'mine' : 'open',
      'group': ?group?.wire,
      'cursor': ?cursor,
    };
    final data = _map(
      await _api.get('/blood/requests?${Uri(queryParameters: q).query}'),
    );
    return BloodRequestList([
      for (final i in data['items'] as List<Object?>? ?? const [])
        BloodRequest.fromJson(_map(i)),
    ], data['nextCursor'] as String?);
  }

  @override
  Future<BloodRequest> request(String id) async =>
      BloodRequest.fromJson(_map(await _api.get('/blood/requests/$id')));

  @override
  Future<BloodRequest> create(BloodRequestDraft draft) async =>
      BloodRequest.fromJson(
        _map(await _api.post('/blood/requests', draft.toJson())),
      );

  @override
  Future<BloodRequest> respond(String id, String phone) async =>
      BloodRequest.fromJson(
        _map(
          await _api.post('/blood/requests/$id/respond', {
            'phone': phone.trim(),
          }),
        ),
      );

  @override
  Future<BloodRequest> withdraw(String id) async => BloodRequest.fromJson(
    _map(await _api.delete('/blood/requests/$id/respond')),
  );

  @override
  Future<BloodRequest> close(String id, {required bool fulfilled}) async =>
      BloodRequest.fromJson(
        _map(
          await _api.post('/blood/requests/$id/close', {
            'fulfilled': fulfilled,
          }),
        ),
      );
}
