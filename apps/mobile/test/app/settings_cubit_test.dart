import 'package:bloc_test/bloc_test.dart';
import 'package:campussaga/app/settings/bloc/settings_cubit.dart';
import 'package:campussaga/app/settings/bloc/settings_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts with system theme and phone language', () {
    expect(SettingsCubit().state, const SettingsState());
  });

  blocTest<SettingsCubit, SettingsState>(
    'changes theme',
    build: SettingsCubit.new,
    act: (cubit) => cubit.setThemeMode(ThemeMode.dark),
    expect: () => [const SettingsState(themeMode: ThemeMode.dark)],
  );

  blocTest<SettingsCubit, SettingsState>(
    'sets Bangla, then back to the phone language',
    build: SettingsCubit.new,
    act: (cubit) => cubit
      ..setLocale(const Locale('bn'))
      ..setLocale(null),
    expect: () => [
      const SettingsState(locale: Locale('bn')),
      const SettingsState(),
    ],
  );
}
