import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// A place found by name.
class Place {
  const Place({required this.name, required this.detail, required this.point});

  final String name;

  /// The area it's in ("Mirpur, Dhaka").
  final String detail;
  final LatLng point;
}

/// Finds places by name with OpenStreetMap's Nominatim, for transport reps
/// placing bus stops. Its usage policy asks for one search at a time, made
/// by a person (no search-as-you-type), and an app that says who it is.
class PlaceSearch {
  PlaceSearch({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _userAgent =
      'VarsityKotha/1.0 (+https://varsitykotha.com; hello@silifton.com)';

  /// Up to 8 places in Bangladesh matching [query], the ones near [near]
  /// first. Throws on network or server errors.
  Future<List<Place>> search(String query, {LatLng? near}) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final params = {
      'q': q,
      'format': 'jsonv2',
      'limit': '8',
      'countrycodes': 'bd',
      'accept-language': 'bn,en',
      if (near != null) ...{
        // A box of about 30 km around the route: prefers, doesn't limit.
        'viewbox': [
          near.longitude - 0.3,
          near.latitude + 0.3,
          near.longitude + 0.3,
          near.latitude - 0.3,
        ].join(','),
      },
    };
    final res = await _client
        .get(
          Uri.https('nominatim.openstreetmap.org', '/search', params),
          headers: {'User-Agent': _userAgent},
        )
        .timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) {
      throw http.ClientException('Place search: ${res.statusCode}');
    }
    final list = jsonDecode(utf8.decode(res.bodyBytes)) as List;
    return [
      for (final p in list.cast<Map<String, Object?>>())
        if (_point(p) case final point?)
          Place(
            name: (p['name'] as String?)?.trim().isNotEmpty ?? false
                ? (p['name']! as String).trim()
                : _parts(p).firstOrNull ?? q,
            detail: _parts(p).skip(1).take(3).join(', '),
            point: point,
          ),
    ];
  }

  static List<String> _parts(Map<String, Object?> p) => [
    for (final s in ((p['display_name'] as String?) ?? '').split(','))
      if (s.trim().isNotEmpty) s.trim(),
  ];

  static LatLng? _point(Map<String, Object?> p) {
    final lat = double.tryParse('${p['lat']}');
    final lon = double.tryParse('${p['lon']}');
    return lat == null || lon == null ? null : LatLng(lat, lon);
  }
}
