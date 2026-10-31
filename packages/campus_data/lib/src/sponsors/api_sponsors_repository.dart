import 'package:campus_core/campus_core.dart';

import '../api_client.dart';

/// Ads over HTTP (docs/SPONSORS.md §4).
class ApiSponsorsRepository implements SponsorsRepository {
  ApiSponsorsRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Promo>> promos(String placement, {String lang = 'en'}) async {
    final q = Uri(queryParameters: {'placement': placement, 'lang': lang})
        .query;
    final data = await _api.get('/promos?$q');
    final items = (data as Map<String, Object?>?)?['items'];
    return [
      for (final p in (items as List<Object?>?) ?? const [])
        Promo.fromJson(p! as Map<String, Object?>),
    ];
  }

  @override
  Future<void> sendEvents(List<PromoEvent> events) async {
    if (events.isEmpty) return;
    await _api.post('/promos/events', {
      'events': [for (final e in events.take(50)) e.toJson()],
    });
  }
}
