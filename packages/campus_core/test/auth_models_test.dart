import 'package:campus_core/campus_core.dart';
import 'package:test/test.dart';

void main() {
  test('a profile saved on the phone reads back the same', () {
    const u = UserProfile(
      id: 'u1',
      email: 'a@diu.edu.bd',
      university: University(
        id: 'x',
        slug: 'diu',
        name: 'DIU',
        domains: ['diu.edu.bd'],
      ),
      role: 'student',
      displayName: 'Rafi',
      department: 'CSE',
      batch: '61',
      verified: true,
      photoVersion: 'avatar-1.jpg',
    );
    final back = UserProfile.fromJson(u.toJson());
    expect(back.toJson(), u.toJson());
    expect(back.university?.domains, ['diu.edu.bd']);
    expect(back.verified, isTrue);
  });
}
