import 'package:campus_core/campus_core.dart';
import 'package:test/test.dart';

void main() {
  group('legs', () {
    test('turn minutes from the start into minutes from the stop before', () {
      expect(legsFromOffsets([0, 20, 50]), [0, 20, 30]);
      expect(offsetsFromLegs([0, 20, 30]), [0, 20, 50]);
    });

    test('skip stops with no time', () {
      // Agargaon has no time: Campus counts from Mirpur 10.
      expect(legsFromOffsets([0, null, 50]), [0, null, 50]);
      expect(offsetsFromLegs([0, null, 50]), [0, null, 50]);
      expect(offsetsFromLegs([0, 10, null, 15]), [0, 10, null, 25]);
    });

    test('the first stop always starts the trip', () {
      expect(offsetsFromLegs([7, 10]), [0, 10]);
      expect(legsFromOffsets([null, 10]), [0, 10]);
    });

    test('round-trip', () {
      const offsets = [0, 5, null, 25, 40];
      expect(offsetsFromLegs(legsFromOffsets(offsets)), offsets);
    });
  });

  group('the way back', () {
    test('mirrors the way there', () {
      expect(mirroredFromCampus([0, 20, 50]), [50, 30, 0]);
      expect(mirroredFromCampus([0, null, 50]), [50, null, 0]);
      // Campus has no time going: only campus is timed coming back.
      expect(mirroredFromCampus([0, null, null]), [null, null, 0]);
    });

    test('isMirrored', () {
      const same = [
        BusStop(id: 'a', name: 'A', toCampusMin: 0, fromCampusMin: 50),
        BusStop(id: 'b', name: 'B', toCampusMin: 20, fromCampusMin: 30),
        BusStop(id: 'c', name: 'C', toCampusMin: 50, fromCampusMin: 0),
      ];
      expect(isMirrored(same), isTrue);
      const other = [
        BusStop(id: 'a', name: 'A', toCampusMin: 0, fromCampusMin: 60),
        BusStop(id: 'b', name: 'B', toCampusMin: 20, fromCampusMin: 30),
        BusStop(id: 'c', name: 'C', toCampusMin: 50, fromCampusMin: 0),
      ];
      expect(isMirrored(other), isFalse);
      const noneBack = [
        BusStop(id: 'a', name: 'A', toCampusMin: 0),
        BusStop(id: 'b', name: 'B', toCampusMin: 20),
      ];
      expect(isMirrored(noneBack), isTrue);
    });

    test('stopsWithLegs: mirrored or set separately', () {
      const stops = [
        BusStop(id: 'a', name: 'A'),
        BusStop(id: 'b', name: 'B'),
        BusStop(id: 'c', name: 'Campus'),
      ];
      final mirrored = stopsWithLegs(stops, toLegs: [0, 20, 30]);
      expect([for (final s in mirrored) s.toCampusMin], [0, 20, 50]);
      expect([for (final s in mirrored) s.fromCampusMin], [50, 30, 0]);

      // Way back legs are in way-back order: Campus, B, A.
      final separate = stopsWithLegs(
        stops,
        toLegs: [0, 20, 30],
        backLegs: [0, 40, 25],
      );
      expect([for (final s in separate) s.fromCampusMin], [65, 40, 0]);
      expect(separate.first.name, 'A');
    });
  });

  group('parseStopList', () {
    test('one per line, with numbering dropped', () {
      expect(parseStopList('1. Mirpur 10\n2) Agargaon\n\n- Campus'), const [
        StopDraft('Mirpur 10'),
        StopDraft('Agargaon'),
        StopDraft('Campus'),
      ]);
    });

    test('a Bangla notice line', () {
      const notice =
          'আব্দুল্লাহপুর, আজমপুর, এয়ারপোর্ট, মহাখালী ফ্লাইওভার (ফ্লাইওভারের নিচ দিয়ে), '
          'মিরপুর ১০ নম্বর, ০২ নম্বর, গাবতলী--- জাবিঃ ক্যাম্পাস।';
      expect(parseStopList(notice), const [
        StopDraft('আব্দুল্লাহপুর'),
        StopDraft('আজমপুর'),
        StopDraft('এয়ারপোর্ট'),
        StopDraft('মহাখালী ফ্লাইওভার', 'ফ্লাইওভারের নিচ দিয়ে'),
        StopDraft('মিরপুর ১০ নম্বর'),
        StopDraft('০২ নম্বর'),
        StopDraft('গাবতলী'),
        StopDraft('জাবিঃ ক্যাম্পাস'),
      ]);
    });

    test('commas inside brackets stay in the landmark', () {
      expect(
        parseStopList('Motijheel (Bangladesh Bank, front gate), Paltan'),
        const [
          StopDraft('Motijheel', 'Bangladesh Bank, front gate'),
          StopDraft('Paltan'),
        ],
      );
    });

    test('single hyphens and dashes', () {
      expect(parseStopList('Mirpur-10 – Kazipara — Campus'), const [
        StopDraft('Mirpur-10'),
        StopDraft('Kazipara'),
        StopDraft('Campus'),
      ]);
    });

    test('long names are clipped to the server limit', () {
      final long = 'A' * 80;
      expect(parseStopList(long).single.name.length, maxStopName);
    });

    test('nothing to add', () {
      expect(parseStopList(' ,\n ; '), isEmpty);
    });
  });
}
