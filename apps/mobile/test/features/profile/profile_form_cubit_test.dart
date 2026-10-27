import 'package:bloc_test/bloc_test.dart';
import 'package:campus_core/campus_core.dart';
import 'package:campussaga/features/profile/presentation/bloc/profile_form_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeProfileRepository repo;
  setUp(() => repo = FakeProfileRepository());

  blocTest<ProfileFormCubit, ProfileFormState>(
    'empty and too-long fields are caught before sending',
    build: () => ProfileFormCubit(repo),
    act: (c) => c.submit(
      displayName: '   ',
      department: 'x' * 81,
      batch: 'ক' * 21, // Bangla counts per character, like the server
    ),
    expect: () => [
      const ProfileFormState(
        fieldErrors: {
          'displayName': ProfileFieldError.required,
          'department': ProfileFieldError.tooLong,
          'batch': ProfileFieldError.tooLong,
        },
      ),
    ],
    verify: (_) => expect(repo.updates, isEmpty),
  );

  blocTest<ProfileFormCubit, ProfileFormState>(
    'saves tidied values',
    build: () => ProfileFormCubit(repo),
    act: (c) => c.submit(
      displayName: '  Mim   Akter ',
      department: ' CSE ',
      batch: '61',
    ),
    expect: () => [
      const ProfileFormState(status: ProfileFormStatus.saving),
      isA<ProfileFormState>()
          .having((s) => s.status, 'status', ProfileFormStatus.saved)
          .having((s) => s.saved?.displayName, 'name', 'Mim Akter'),
    ],
    verify: (_) => expect(repo.updates, [('Mim Akter', 'CSE', '61')]),
  );

  blocTest<ProfileFormCubit, ProfileFormState>(
    'a server failure is shown, the form stays editable',
    setUp: () => repo.failure = const NetworkFailure(),
    build: () => ProfileFormCubit(repo),
    act: (c) => c.submit(displayName: 'Mim', department: 'CSE', batch: '61'),
    expect: () => [
      const ProfileFormState(status: ProfileFormStatus.saving),
      const ProfileFormState(failure: NetworkFailure()),
    ],
  );

  test('suggestions are cached and never throw', () async {
    final cubit = ProfileFormCubit(repo);
    expect(await cubit.suggestDepartments(' c '), ['CSE', 'Computer Science']);
    expect(await cubit.suggestDepartments('C'), ['CSE', 'Computer Science']);
    expect(repo.suggestionQueries, ['c'], reason: 'second lookup cached');

    final broken = ProfileFormCubit(_BrokenRepo());
    expect(await broken.suggestDepartments('x'), isEmpty);
  });
}

class _BrokenRepo extends FakeProfileRepository {
  @override
  Future<List<String>> departmentSuggestions(String query) =>
      throw const NetworkFailure();
}
