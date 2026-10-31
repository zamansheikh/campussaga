import 'sponsor_models.dart';

/// Ads the team runs from the admin panel. Every method throws a `Failure`.
abstract interface class SponsorsRepository {
  /// The ads for me at [placement] (`PromoPlacement`), in [lang].
  Future<List<Promo>> promos(String placement, {String lang = 'en'});

  /// Views, taps, code copies and hides, in a batch (≤ 50).
  Future<void> sendEvents(List<PromoEvent> events);
}
