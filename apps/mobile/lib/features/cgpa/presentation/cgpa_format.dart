import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

String _locale(BuildContext context) =>
    Localizations.localeOf(context).toLanguageTag();

/// "3.62" (Bangla digits in Bangla).
String gpaText(BuildContext context, double gpa) =>
    NumberFormat('0.00', _locale(context)).format(gpa);

/// "15", "1.5".
String creditsText(BuildContext context, double credits) =>
    NumberFormat('0.#', _locale(context)).format(credits);

/// A number typed with English or Bangla digits, or null.
double? parseNumber(String text) {
  final ascii = text.trim().replaceAllMapped(
    RegExp('[০-৯]'),
    (m) => '${m[0]!.codeUnitAt(0) - '০'.codeUnitAt(0)}',
  );
  return double.tryParse(ascii.replaceAll(',', '.'));
}
