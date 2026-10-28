import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:campus_core/campus_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:varsitykotha/features/auth/presentation/bloc/email_sign_in_bloc.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeAuthRepository repo;
  late StreamController<int> ticks;

  setUp(() {
    repo = FakeAuthRepository();
    ticks = StreamController<int>.broadcast();
  });
  tearDown(() => ticks.close());

  EmailSignInBloc build() =>
      EmailSignInBloc(repository: repo, ticker: (_) => ticks.stream);

  const codeStep = EmailSignInState(
    step: EmailSignInStep.code,
    email: 'rafi@diu.edu.bd',
    university: University(
      id: 'uni1',
      slug: 'x',
      name: 'x',
    ), // only the id is compared
    resendIn: 60,
  );

  blocTest<EmailSignInBloc, EmailSignInState>(
    'sends a code and moves to the code step (email normalised)',
    build: build,
    act: (b) => b.add(const EmailSubmitted('  Rafi@DIU.edu.bd ')),
    expect: () => [
      const EmailSignInState(
        status: EmailSignInStatus.submitting,
        email: 'rafi@diu.edu.bd',
      ),
      codeStep,
    ],
    verify: (_) => expect(repo.requested, ['rafi@diu.edu.bd']),
  );

  blocTest<EmailSignInBloc, EmailSignInState>(
    'an obviously wrong email is caught without a request',
    build: build,
    act: (b) => b.add(const EmailSubmitted('not-an-email')),
    expect: () => [
      const EmailSignInState(
        email: 'not-an-email',
        failure: ValidationFailure({}, code: 'VALIDATION_FAILED'),
      ),
    ],
    verify: (_) => expect(repo.requested, isEmpty),
  );

  blocTest<EmailSignInBloc, EmailSignInState>(
    'a non-university email stays on the email step with the reason',
    setUp: () => repo.requestFailure = const RejectedFailure(
      code: 'UNIVERSITY_EMAIL_REQUIRED',
    ),
    build: build,
    act: (b) => b.add(const EmailSubmitted('me@gmail.com')),
    expect: () => [
      const EmailSignInState(
        status: EmailSignInStatus.submitting,
        email: 'me@gmail.com',
      ),
      const EmailSignInState(
        email: 'me@gmail.com',
        failure: RejectedFailure(code: 'UNIVERSITY_EMAIL_REQUIRED'),
      ),
    ],
  );

  blocTest<EmailSignInBloc, EmailSignInState>(
    'if a code was just sent, go straight to entering it',
    setUp: () => repo.requestFailure = const RateLimitedFailure(
      code: 'CODE_RESEND_TOO_SOON',
      retryAfter: Duration(seconds: 42),
    ),
    build: build,
    act: (b) => b.add(const EmailSubmitted('rafi@diu.edu.bd')),
    skip: 1,
    expect: () => [
      const EmailSignInState(
        step: EmailSignInStep.code,
        email: 'rafi@diu.edu.bd',
        resendIn: 42,
      ),
    ],
  );

  blocTest<EmailSignInBloc, EmailSignInState>(
    'wrong code shows attempts left; right code signs in',
    seed: () => codeStep,
    build: build,
    act: (b) async {
      b.add(const CodeSubmitted('000000'));
      await Future<void>.delayed(Duration.zero);
      b.add(const CodeSubmitted('123456'));
    },
    expect: () => [
      codeStep.copyWith(status: EmailSignInStatus.submitting),
      codeStep.copyWith(
        failure: () => const RejectedFailure(code: 'CODE_INVALID'),
      ),
      codeStep.copyWith(status: EmailSignInStatus.submitting),
      codeStep.copyWith(
        status: EmailSignInStatus.success,
        result: const SignInResult(user: testUser, isNewUser: false),
      ),
    ],
    verify: (_) => expect(repo.verified.last, ('rafi@diu.edu.bd', '123456')),
  );

  blocTest<EmailSignInBloc, EmailSignInState>(
    'resend is blocked during the countdown and allowed after it',
    build: build,
    act: (b) async {
      b.add(const EmailSubmitted('rafi@diu.edu.bd')); // starts the countdown
      await Future<void>.delayed(Duration.zero);
      b.add(const ResendRequested()); // ignored: resendIn = 60
      await Future<void>.delayed(Duration.zero);
      ticks.add(0); // countdown finished
      await Future<void>.delayed(Duration.zero);
      b.add(const ResendRequested());
    },
    skip: 2, // submitting + code step, covered above
    expect: () => [
      codeStep.copyWith(resendIn: 0),
      codeStep.copyWith(resendIn: 0, status: EmailSignInStatus.submitting),
      codeStep, // new code sent, countdown back to 60
    ],
    verify: (_) =>
        expect(repo.requested, ['rafi@diu.edu.bd', 'rafi@diu.edu.bd']),
  );

  blocTest<EmailSignInBloc, EmailSignInState>(
    '"Use a different email" goes back, keeping what was typed',
    seed: () => codeStep,
    build: build,
    act: (b) => b.add(const EmailChangeRequested()),
    expect: () => [const EmailSignInState(email: 'rafi@diu.edu.bd')],
  );
}
