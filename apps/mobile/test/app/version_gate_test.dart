import 'package:bloc_test/bloc_test.dart';
import 'package:campus_core/campus_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:varsitykotha/app/version/version_gate_cubit.dart';

import '../helpers/fakes.dart';

void main() {
  late FakeAppConfigRepository config;
  late DateTime now;
  setUp(() {
    config = FakeAppConfigRepository();
    now = DateTime(2026, 10, 27, 10);
  });

  VersionGateCubit build(int currentBuild) => VersionGateCubit(
    config: config,
    currentBuild: currentBuild,
    platform: 'android',
    now: () => now,
  );

  blocTest<VersionGateCubit, VersionGateState>(
    'an old build must update, with the store link for its platform',
    setUp: () => config.config = const AppConfig(
      minSupportedBuild: 5,
      storeUrls: {'android': 'https://play.google.com/x'},
    ),
    build: () => build(4),
    act: (c) => c.check(),
    expect: () => [
      const VersionGateState(
        status: VersionStatus.updateRequired,
        storeUrl: 'https://play.google.com/x',
      ),
    ],
  );

  blocTest<VersionGateCubit, VersionGateState>(
    'a supported build passes',
    setUp: () => config.config = const AppConfig(minSupportedBuild: 5),
    build: () => build(5),
    act: (c) => c.check(),
    expect: () => <VersionGateState>[], // already ok
  );

  blocTest<VersionGateCubit, VersionGateState>(
    'offline never locks students out, and retries next time',
    setUp: () => config.failure = const NetworkFailure(),
    build: () => build(1),
    act: (c) async {
      await c.check();
      await c.check();
    },
    expect: () => <VersionGateState>[],
    verify: (_) => expect(config.fetches, 2),
  );

  blocTest<VersionGateCubit, VersionGateState>(
    'checks at most every 10 minutes',
    build: () => build(1),
    act: (c) async {
      await c.check();
      now = now.add(const Duration(minutes: 5));
      await c.check();
      now = now.add(const Duration(minutes: 6));
      await c.check();
    },
    verify: (_) => expect(config.fetches, 2),
  );
}
