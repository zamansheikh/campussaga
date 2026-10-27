import 'package:bloc_test/bloc_test.dart';
import 'package:campussaga/app/settings/bloc/settings_cubit.dart';
import 'package:campussaga/app/settings/bloc/settings_state.dart';
import 'package:campussaga/app/settings/settings_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  test('starts with the saved settings', () {
    final storage = MemorySettingsStorage(
      const SettingsState(themeMode: ThemeMode.dark, locale: Locale('bn')),
    );
    expect(
      SettingsCubit(storage).state,
      const SettingsState(themeMode: ThemeMode.dark, locale: Locale('bn')),
    );
  });

  blocTest<SettingsCubit, SettingsState>(
    'changes are saved',
    build: () => SettingsCubit(MemorySettingsStorage()),
    act: (c) => c
      ..setThemeMode(ThemeMode.dark)
      ..setLocale(const Locale('bn'))
      ..setLocale(null)
      ..completeOnboarding(),
    expect: () => [
      const SettingsState(themeMode: ThemeMode.dark),
      const SettingsState(themeMode: ThemeMode.dark, locale: Locale('bn')),
      const SettingsState(themeMode: ThemeMode.dark),
      const SettingsState(themeMode: ThemeMode.dark, onboardingDone: true),
    ],
  );

  test('device storage survives a restart', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final first = await PrefsSettingsStorage.open();
    SettingsCubit(first)
      ..setThemeMode(ThemeMode.light)
      ..setLocale(const Locale('bn'))
      ..completeOnboarding();
    await Future<void>.delayed(Duration.zero);

    final afterRestart = await PrefsSettingsStorage.open();
    expect(
      afterRestart.read(),
      const SettingsState(
        themeMode: ThemeMode.light,
        locale: Locale('bn'),
        onboardingDone: true,
      ),
    );
    expect(SharedPreferencesWithCache, isNotNull);
  });
}
