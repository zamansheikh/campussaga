import 'dart:async';

import 'package:campus_core/campus_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../app/clock.dart';
import '../../app/settings/bloc/settings_cubit.dart';
import '../auth/presentation/bloc/auth_bloc.dart';
import '../classes/presentation/bloc/my_classes_cubit.dart';
import 'widget_data.dart';

/// Where the widget's data goes (Android: NextClassWidget, through the
/// "campussaga/widget" channel in MainActivity).
abstract interface class WidgetBridge {
  Future<void> save(String json);
}

class AndroidWidgetBridge implements WidgetBridge {
  static const _channel = MethodChannel('campussaga/widget');

  @override
  Future<void> save(String json) async {
    try {
      await _channel.invokeMethod<void>('save', json);
    } on PlatformException {
      // The widget is a convenience: never let it break the app.
    } on MissingPluginException {
      // Not on Android (or an old build): nothing to update.
    }
  }
}

/// Keeps the Android home-screen widget up to date: the next two weeks of
/// classes and tests, in the app's language, saved whenever the routine,
/// the signed-in student or the language changes. A no-op off Android.
class HomeWidgetSync {
  HomeWidgetSync({
    WidgetBridge? bridge,
    this.debounce = const Duration(milliseconds: 400),
  }) : _bridge =
           bridge ??
           (!kIsWeb && defaultTargetPlatform == TargetPlatform.android
               ? AndroidWidgetBridge()
               : null);

  final WidgetBridge? _bridge;
  final Duration debounce;

  final _subs = <StreamSubscription<Object?>>[];
  Timer? _timer;
  String? _last;
  bool _symbols = false;

  /// Follows the routine, sign-in and language from now on.
  void attach({
    required MyClassesCubit classes,
    required AuthBloc auth,
    required SettingsCubit settings,
  }) {
    if (_bridge == null) return;
    void schedule() => _schedule(
      () => (
        routine: classes.state.routine,
        signedIn: auth.state.status == AuthStatus.signedIn,
        lang: _language(settings.state.locale?.languageCode),
      ),
    );
    _subs
      ..add(classes.stream.listen((_) => schedule()))
      ..add(auth.stream.listen((_) => schedule()))
      ..add(settings.stream.listen((_) => schedule()));
    schedule();
  }

  /// The app's language: its own setting, else the phone's when supported.
  static String _language(String? setting) {
    final code = setting ?? PlatformDispatcher.instance.locale.languageCode;
    return code == 'bn' ? 'bn' : 'en';
  }

  void _schedule(
    ({List<ClassGroup> routine, bool signedIn, String lang}) Function() read,
  ) {
    _timer?.cancel();
    _timer = Timer(debounce, () {
      final v = read();
      unawaited(save(routine: v.routine, signedIn: v.signedIn, lang: v.lang));
    });
  }

  /// Saves now (skipped when nothing changed since the last save).
  Future<void> save({
    required List<ClassGroup> routine,
    required bool signedIn,
    required String lang,
  }) async {
    final bridge = _bridge;
    if (bridge == null) return;
    if (!_symbols) {
      await initializeDateFormatting();
      _symbols = true;
    }
    final json = buildWidgetJson(
      routine: routine,
      now: appNow(),
      lang: lang,
      signedIn: signedIn,
    );
    if (json == _last) return;
    _last = json;
    await bridge.save(json);
  }

  void dispose() {
    _timer?.cancel();
    for (final s in _subs) {
      unawaited(s.cancel());
    }
  }
}
