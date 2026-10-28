import 'transport_models.dart';

/// Editing helpers for bus stops. The server stores each stop's minutes from
/// the start of a trip (one number per direction); people think in "minutes
/// from the stop before", so the editors show legs and convert back.
///
/// Stops are in to-campus order: the first stop starts the trip to campus,
/// the last stop (campus) starts the trip back. A null time means the stop
/// has no time that way (shown as "—").

/// Most stops a route may have (the server's limit).
const maxBusStops = 60;

/// Stop and landmark length limits (the server's).
const maxStopName = 60;
const maxStopLandmark = 100;

/// Minutes from the last timed stop before each stop, from [offsets] (minutes
/// from the start). The first entry is the start, always 0.
List<int?> legsFromOffsets(List<int?> offsets) {
  final legs = <int?>[];
  int? last;
  for (final (i, o) in offsets.indexed) {
    if (i == 0) {
      legs.add(0);
      last = o ?? 0;
    } else if (o == null) {
      legs.add(null);
    } else {
      final from = last ?? 0;
      legs.add(o < from ? 0 : o - from);
      last = o;
    }
  }
  return legs;
}

/// The inverse of [legsFromOffsets]: running totals, with the first stop at 0
/// and untimed stops left null.
List<int?> offsetsFromLegs(List<int?> legs) {
  final out = <int?>[];
  var total = 0;
  for (final (i, l) in legs.indexed) {
    if (i == 0) {
      out.add(0);
    } else if (l == null) {
      out.add(null);
    } else {
      total += l;
      out.add(total);
    }
  }
  return out;
}

/// The way back as the reverse of the way there: minutes after leaving campus
/// (the last stop) for each stop, from its minutes going to campus.
List<int?> mirroredFromCampus(List<int?> toCampus) {
  if (toCampus.isEmpty) return const [];
  final end = toCampus.last;
  return [
    for (final (i, t) in toCampus.indexed)
      if (i == toCampus.length - 1)
        0
      else if (end == null || t == null)
        null
      else
        end - t,
  ];
}

/// Whether [stops] have the way back as the exact reverse of the way there
/// (also true when no stop has a time back yet).
bool isMirrored(List<BusStop> stops) {
  if (stops.isEmpty) return true;
  final back = [for (final s in stops) s.fromCampusMin];
  if (back.every((b) => b == null)) return true;
  final mirror = mirroredFromCampus([for (final s in stops) s.toCampusMin]);
  for (final (i, b) in back.indexed) {
    if (b != mirror[i]) return false;
  }
  return true;
}

/// Stops with times from legs: [toLegs] in to-campus order (first = start),
/// [backLegs] in the way-back order (campus first) or null for the reverse
/// of the way there.
List<BusStop> stopsWithLegs(
  List<BusStop> stops, {
  required List<int?> toLegs,
  List<int?>? backLegs,
}) {
  final to = offsetsFromLegs(toLegs);
  final List<int?> from;
  if (backLegs == null) {
    from = mirroredFromCampus(to);
  } else {
    from = offsetsFromLegs(backLegs).reversed.toList();
  }
  return [
    for (final (i, s) in stops.indexed)
      BusStop(
        id: s.id,
        name: s.name,
        landmark: s.landmark,
        toCampusMin: to[i],
        fromCampusMin: from[i],
        lat: s.lat,
        lng: s.lng,
      ),
  ];
}

/// A stop typed or pasted by a transport rep.
class StopDraft {
  const StopDraft(this.name, [this.landmark = '']);

  final String name;
  final String landmark;

  @override
  bool operator ==(Object other) =>
      other is StopDraft && other.name == name && other.landmark == landmark;

  @override
  int get hashCode => Object.hash(name, landmark);

  @override
  String toString() => landmark.isEmpty ? name : '$name ($landmark)';
}

final _numbering = RegExp(r'^\s*(?:[0-9০-৯]{1,3}\s*[.)।:-]\s+|[-•*·]\s*)');
final _spaces = RegExp(r'\s+');

/// Stops from pasted text such as a transport notice: one per line, or
/// separated by commas, semicolons, "।" or dashes ("Gabtoli --- Campus").
/// "Name (landmark)" keeps the bracketed part as the landmark, and list
/// numbering ("1.", "২)") is dropped. Single hyphens stay ("Mirpur-10").
List<StopDraft> parseStopList(String text) {
  final parts = <String>[];
  final buf = StringBuffer();
  var depth = 0;
  void cut() {
    parts.add(buf.toString());
    buf.clear();
  }

  final chars = text.split('');
  for (var i = 0; i < chars.length; i++) {
    final c = chars[i];
    if (c == '(') depth++;
    if (c == ')' && depth > 0) depth--;
    final dashRun = c == '-' && i + 1 < chars.length && chars[i + 1] == '-';
    if (c == '\n' ||
        (depth == 0 && (c == ',' || c == ';' || c == '،' || c == '।')) ||
        c == '–' ||
        c == '—' ||
        dashRun) {
      cut();
      while (i + 1 < chars.length && chars[i + 1] == '-') {
        i++;
      }
      if (c == '\n') depth = 0;
      continue;
    }
    buf.write(c);
  }
  cut();

  final out = <StopDraft>[];
  for (var p in parts) {
    p = p.replaceAll(_spaces, ' ').trim().replaceFirst(_numbering, '').trim();
    // A full stop or "|" left at the end of a notice line.
    p = p.replaceFirst(RegExp(r'[.|।]+$'), '').trim();
    if (p.isEmpty) continue;
    var name = p;
    var landmark = '';
    final open = p.indexOf('(');
    if (open > 0 && p.endsWith(')')) {
      name = p.substring(0, open).trim();
      landmark = p.substring(open + 1, p.length - 1).trim();
    }
    if (name.isEmpty) continue;
    out.add(
      StopDraft(_clip(name, maxStopName), _clip(landmark, maxStopLandmark)),
    );
  }
  return out;
}

String _clip(String s, int max) =>
    s.length <= max ? s : s.substring(0, max).trimRight();

/// Day sets reps pick most often (ISO weekdays).
abstract final class BusDays {
  /// Saturday to Thursday: the usual week in Bangladesh.
  static const satToThu = {6, 7, 1, 2, 3, 4};
  static const friSat = {5, 6};
  static const everyDay = {1, 2, 3, 4, 5, 6, 7};
}

final _phone = RegExp(r'^\+?[0-9]{6,15}$');

/// A phone number as the server stores it: Bangla digits as ASCII, spaces,
/// dashes, dots and brackets dropped. Null when it isn't one; '' for none.
String? cleanPhone(String s) {
  final b = StringBuffer();
  for (final r in s.trim().runes) {
    if (r >= 0x09E6 && r <= 0x09EF) {
      b.writeCharCode(0x30 + r - 0x09E6);
    } else if (!' -.()'.runes.contains(r)) {
      b.writeCharCode(r);
    }
  }
  final p = b.toString();
  return p.isEmpty || _phone.hasMatch(p) ? p : null;
}
