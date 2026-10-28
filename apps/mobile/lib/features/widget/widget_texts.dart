import 'package:campus_core/campus_core.dart';

/// Texts of the home-screen widget, in English and Bangla. (Kept here, not
/// in the ARB files: the widget draws them natively, outside Flutter.)
class WidgetTexts {
  const WidgetTexts._(this.lang, this._t);

  factory WidgetTexts.of(String lang) => lang == 'bn'
      ? const WidgetTexts._('bn', _bn)
      : const WidgetTexts._('en', _en);

  final String lang;
  final Map<String, String> _t;

  /// The labels NextClassWidget.kt reads ("inMin" keeps its {m}).
  Map<String, String> get labels => {
    for (final k in const [
      'nextClass',
      'nextTest',
      'now',
      'inMin',
      'minLeft',
      'inDays',
      'today',
      'tomorrow',
      'noClass',
      'noTest',
      'signedOut',
    ])
      k: _t[k]!,
  };

  String get moved => _t['moved']!;
  String movedFrom(String date) => _t['movedFrom']!.replaceAll('{d}', date);
  String get extra => _t['extra']!;
  String get room => _t['room']!;
  String get due => _t['due']!;

  String kind(AssessmentKind k) => _t['kind.${k.wire}']!;

  static const _en = {
    'nextClass': 'Next class',
    'nextTest': 'Next test',
    'now': 'Now',
    'inMin': 'in {m} min',
    'minLeft': '{m} min left',
    'inDays': 'in {d} days',
    'today': 'Today',
    'tomorrow': 'Tomorrow',
    'noClass': 'No classes in the next 2 weeks',
    'noTest': 'No tests coming up',
    'signedOut': 'Sign in to see your classes',
    'moved': 'Time or room changed',
    'movedFrom': 'Moved from {d}',
    'extra': 'Extra class',
    'room': 'Room',
    'due': 'Due',
    'kind.class_test': 'Class test',
    'kind.quiz': 'Quiz',
    'kind.assignment': 'Assignment',
    'kind.lab_report': 'Lab report',
    'kind.presentation': 'Presentation',
    'kind.midterm': 'Mid exam',
    'kind.final': 'Final exam',
    'kind.other': 'Test',
  };

  static const _bn = {
    'nextClass': 'পরের ক্লাস',
    'nextTest': 'পরের পরীক্ষা',
    'now': 'এখন',
    'inMin': '{m} মিনিট পর',
    'minLeft': '{m} মিনিট বাকি',
    'inDays': '{d} দিন পর',
    'today': 'আজ',
    'tomorrow': 'আগামীকাল',
    'noClass': 'আগামী ২ সপ্তাহে কোনো ক্লাস নেই',
    'noTest': 'সামনে কোনো পরীক্ষা নেই',
    'signedOut': 'ক্লাস দেখতে সাইন ইন করো',
    'moved': 'সময় বা রুম বদলেছে',
    'movedFrom': 'সরানো, আগে ছিল {d}',
    'extra': 'অতিরিক্ত ক্লাস',
    'room': 'রুম',
    'due': 'জমা',
    'kind.class_test': 'ক্লাস টেস্ট',
    'kind.quiz': 'কুইজ',
    'kind.assignment': 'অ্যাসাইনমেন্ট',
    'kind.lab_report': 'ল্যাব রিপোর্ট',
    'kind.presentation': 'প্রেজেন্টেশন',
    'kind.midterm': 'মিড পরীক্ষা',
    'kind.final': 'ফাইনাল পরীক্ষা',
    'kind.other': 'পরীক্ষা',
  };
}
