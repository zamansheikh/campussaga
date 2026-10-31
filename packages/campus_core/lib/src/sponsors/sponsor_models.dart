/// Sponsored content the team creates in the admin panel (docs/SPONSORS.md).
library;

Map<String, Object?>? _map(Object? v) => v as Map<String, Object?>?;

DateTime? _time(Object? v) =>
    v is String && v.isNotEmpty ? DateTime.tryParse(v)?.toLocal() : null;

/// Where an ad can show.
abstract final class PromoPlacement {
  static const deals = 'deals';
  static const today = 'today';
  static const campus = 'campus';
  static const lineBus = 'line:bus';
  static const lineGroups = 'line:groups';
  static const lineCgpa = 'line:cgpa';
  static const lineBlood = 'line:blood';
}

/// What an ad looks like.
enum PromoKind {
  deal,
  card,
  feed,
  line,
  campaign;

  static PromoKind parse(Object? v) =>
      PromoKind.values.firstWhere((k) => k.name == v, orElse: () => card);
}

/// The brand behind an ad.
class PromoSponsor {
  const PromoSponsor({required this.name, this.logoUrl, this.health = false});

  factory PromoSponsor.fromJson(Map<String, Object?> json) => PromoSponsor(
    name: json['name'] as String? ?? '',
    logoUrl: json['logoUrl'] as String?,
    health: json['category'] == 'health',
  );

  final String name;

  /// A path under the API base (`/sponsors/{id}/logo?v=…`), or null.
  final String? logoUrl;
  final bool health;
}

/// Where tapping an ad goes: a website, or a screen in the app.
class PromoLink {
  const PromoLink({required this.web, required this.url});

  /// Null when the ad doesn't link anywhere.
  static PromoLink? fromJson(Map<String, Object?>? json) {
    final kind = json?['kind'];
    final url = json?['url'] as String? ?? '';
    if (json == null || url.isEmpty || (kind != 'web' && kind != 'app')) {
      return null;
    }
    return PromoLink(web: kind == 'web', url: url);
  }

  /// A https website; otherwise an app route ("/deals").
  final bool web;
  final String url;
}

/// One ad (`GET /promos`). Text comes in the student's language.
class Promo {
  const Promo({
    required this.id,
    required this.kind,
    required this.placement,
    required this.sponsor,
    this.title = '',
    this.body = '',
    this.cta = '',
    this.imageUrl,
    this.link,
    this.code,
    this.expiresAt,
    this.terms = '',
    this.why = '',
    this.targeted = false,
  });

  factory Promo.fromJson(Map<String, Object?> json) => Promo(
    id: json['id']! as String,
    kind: PromoKind.parse(json['kind']),
    placement: json['placement'] as String? ?? '',
    sponsor: PromoSponsor.fromJson(_map(json['sponsor']) ?? const {}),
    title: json['title'] as String? ?? '',
    body: json['body'] as String? ?? '',
    cta: json['cta'] as String? ?? '',
    imageUrl: json['imageUrl'] as String?,
    link: PromoLink.fromJson(_map(json['link'])),
    code: (json['code'] as String?)?.trim().isEmpty ?? true
        ? null
        : (json['code']! as String).trim(),
    expiresAt: _time(json['expiresAt']),
    terms: json['terms'] as String? ?? '',
    why: json['why'] as String? ?? '',
    targeted: json['targeted'] as bool? ?? false,
  );

  final String id;
  final PromoKind kind;
  final String placement;
  final PromoSponsor sponsor;
  final String title;
  final String body;

  /// The button ("Get offer"); empty: none.
  final String cta;

  /// A path under the API base (`/promos/{id}/image?v=…`), or null.
  final String? imageUrl;
  final PromoLink? link;

  /// A deal's promo code and its last day.
  final String? code;
  final DateTime? expiresAt;
  final String terms;

  /// "Shown to students at Dhaka University".
  final String why;

  /// Shown to my university or city only (not to every student).
  final bool targeted;
}

/// What a student did with an ad.
enum PromoEventType { view, tap, copy, hide }

class PromoEvent {
  const PromoEvent({
    required this.promoId,
    required this.type,
    required this.at,
  });

  final String promoId;
  final PromoEventType type;
  final DateTime at;

  Map<String, Object?> toJson() => {
    'promoId': promoId,
    'type': type.name,
    'at': at.toUtc().toIso8601String(),
  };
}

/// The sponsor of a prize campaign ("Powered by"), on the campaign JSON.
class CampaignSponsor {
  const CampaignSponsor({required this.name, this.logoUrl, this.link});

  static CampaignSponsor? fromJson(Object? json) {
    final m = _map(json);
    if (m == null) return null;
    final name = m['name'] as String? ?? '';
    if (name.isEmpty) return null;
    final link = m['link'];
    return CampaignSponsor(
      name: name,
      logoUrl: m['logoUrl'] as String?,
      link: link is Map<String, Object?>
          ? PromoLink.fromJson(link)
          : link is String && link.isNotEmpty
          ? PromoLink(web: link.startsWith('http'), url: link)
          : null,
    );
  }

  final String name;
  final String? logoUrl;
  final PromoLink? link;
}
