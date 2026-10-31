import 'package:campus_core/campus_core.dart';
import 'package:test/test.dart';

void main() {
  test('course links read and save by course key', () {
    final g = ClassGroup.fromJson({
      'id': 'g1',
      'department': 'CSE',
      'batch': '40',
      'semester': 'Fall 2026',
      'joinCode': 'ABCDEF',
      'role': 'member',
      'memberCount': 3,
      'courses': [
        {
          'courseKey': 'CSE311',
          'chatLink': 'https://chat.whatsapp.com/x',
          'classroomCode': 'ab3x9kq',
          'materialsLink': '',
          'teacherEmail': 'sir@ju.ac.bd',
          'notes': '',
        },
      ],
    });
    expect(g.courseInfo('cse 311').classroomCode, 'ab3x9kq');
    expect(g.courseInfo('CSE313').isEmpty, isTrue);
    final back = ClassGroup.fromJson(g.toJson());
    expect(back.courseInfo('CSE311').teacherEmail, 'sir@ju.ac.bd');
    expect(
      ClassGroup.fromJson({...g.toJson()..remove('courses')}).courses,
      isEmpty,
      reason: 'saved before course links existed',
    );
  });
}
