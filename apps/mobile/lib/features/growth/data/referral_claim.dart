import 'package:campus_core/campus_core.dart';

import '../../../app/di.dart';
import '../../classes/data/invite_link.dart';

/// Tells the server whose invite brought this student (`POST /me/referral`),
/// once, after sign-in. The server answers 4xx when it's too late, already
/// claimed, their own code or unknown: all ignored. Only when the phone is
/// offline (or the server fails) the code is kept to try again.
Future<void> claimPendingReferral() async {
  final v = PendingReferral.take();
  if (v == null || !getIt.isRegistered<GrowthRepository>()) return;
  try {
    await getIt<GrowthRepository>().claimReferral(v.code, source: v.source);
  } on NetworkFailure {
    PendingReferral.save(v.code, source: v.source);
  } on UnexpectedFailure {
    PendingReferral.save(v.code, source: v.source);
  } on Failure {
    // Too late, already referred, own code, unknown code: nothing to do.
  }
}
