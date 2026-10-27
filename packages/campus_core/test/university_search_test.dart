import 'package:campus_core/campus_core.dart';
import 'package:test/test.dart';

University uni(
  String name, {
  String slug = 'x',
  List<String> domains = const [],
  String? city,
  String? bn,
}) => University(
  id: slug,
  slug: slug,
  name: name,
  nameBn: bn,
  city: city,
  domains: domains,
);

void main() {
  test('short names are the ones students use', () {
    expect(uni('Daffodil International University').shortName, 'DIU');
    expect(
      uni('Bangladesh University of Engineering and Technology').shortName,
      'BUET',
    );
    expect(
      uni('American International University-Bangladesh').shortName,
      'AIUB',
    );
    expect(uni('BRAC University').shortName, 'BRACU');
    expect(uni('Jahangirnagar University').shortName, 'JU');
  });

  test('search ranks exact short names and domains first', () {
    final diu = uni(
      'Daffodil International University',
      slug: 'diu',
      domains: ['diu.edu.bd'],
      city: 'Dhaka',
    );
    final du = uni(
      'University of Dhaka',
      slug: 'du',
      domains: ['du.ac.bd'],
      city: 'Dhaka',
      bn: 'ঢাকা বিশ্ববিদ্যালয়',
    );
    final ju = uni(
      'Jahangirnagar University',
      slug: 'juniv',
      domains: ['juniv.edu'],
      city: 'Savar',
    );

    expect(diu.searchScore('DIU'), 6);
    expect(du.searchScore('du'), 6);
    expect(du.searchScore('dhaka'), greaterThan(diu.searchScore('dhaka')));
    expect(ju.searchScore('ju'), 6, reason: 'short name');
    expect(ju.searchScore('juniv'), 6, reason: 'domain');
    expect(ju.searchScore('jahangir'), 4);
    expect(ju.searchScore('savar'), 1, reason: 'city');
    expect(du.searchScore('ঢাকা'), 4, reason: 'Bangla name');
    expect(diu.searchScore('rajshahi'), 0);
    expect(diu.searchScore('  '), 1, reason: 'empty query shows all');
  });

  test('badges use the familiar short form', () {
    String badge(String name, String domain) =>
        uni(name, domains: [domain]).badge;
    expect(badge('University of Dhaka', 'du.ac.bd'), 'DU');
    expect(badge('East West University', 'ewubd.edu'), 'EWU');
    expect(badge('Jahangirnagar University', 'juniv.edu'), 'JU');
    expect(
      badge(
        'Hajee Mohammad Danesh Science & Technology University',
        'hstu.ac.bd',
      ),
      'HSTU',
    );
    expect(badge('North South University', 'northsouth.edu'), 'NSU');
    expect(
      badge(
        'Chattogram BGMEA University of Fashion and Technology',
        'cbuft.edu.bd',
      ),
      'CBUFT',
    );
    expect(
      uni(
        'University of Dhaka',
        slug: 'du',
        domains: ['du.ac.bd'],
      ).searchScore('du'),
      6,
    );

    final dhaka = uni(
      'University of Dhaka',
      slug: 'du',
      domains: ['cs.du.ac.bd', 'du.ac.bd'],
    );
    expect(dhaka.mainDomain, 'du.ac.bd');
    expect(dhaka.badge, 'DU');
    expect(
      dhaka.searchScore('cs'),
      0,
      reason: 'a department is not the university',
    );
    final demo = uni('Demo University', slug: 'demo', domains: ['demo.ac.bd']);
    expect(demo.searchScore('du'), lessThan(dhaka.searchScore('du')));
    expect(
      uni('Asian University', domains: ['aub.edu.bd']).searchScore('du'),
      0,
      reason: 'not every .edu',
    );
  });
}
