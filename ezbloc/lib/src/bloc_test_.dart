import 'package:meta/meta.dart';
import 'package:pedantic/pedantic.dart';
import 'package:test/test.dart';

import 'bloc.dart';

typedef FutureVoidCallback = Future<void> Function();
typedef BlocCallback<R> = Future<void> Function(R);
typedef BlocTestBloc<R> = Future<R> Function();
typedef BlocTestTransform<S, T> = T Function(S);
typedef BlocTestVoidCallback = void Function();

/// Utility function which abstracts over a dart test to ease off bloc testing
///
/// R = Type of bloc
/// S = Type of State
@isTest
void testBloc<R extends Bloc<S>, S>(
  /// description of the test
  description, {

  /// Any setup before the test e.g. mocking repositories
  FutureVoidCallback? setup,

  /// The bloc which is to be tested in this test must be created in this function
  required BlocTestBloc<R> bloc,

  /// Any assertions that must be checked before any operations are run on the bloc
  BlocCallback<R>? expectBefore,

  /// Any assertions that must be checked just before the bloc is to be dispose (end of test)
  BlocCallback<R>? expectAfter,

  /// States which are considered valid broadcasts by bloc
  required StreamMatcher expectedStates,

  /// All the operations on the bloc must be done in this function
  BlocCallback<R>? job,

  /// Any conversions which will be performed on the state before it is matched against [expectedStates]
  BlocTestTransform<S, dynamic>? transform,
  Duration timeout = const Duration(minutes: 1),
}) async {
  test(description, () async {
    if (setup != null) {
      await setup();
    }
    final _bloc = await bloc();
    final stream = _bloc.stream.where((event) => event != null);

    unawaited(expectLater(
        transform == null ? stream : stream.map((event) => transform(event!)),
        expectedStates));

    if (expectBefore != null) {
      await expectBefore(_bloc);
    }

    job ??= (_bloc) async {};

    await job!(_bloc);
    // ignore: invalid_use_of_visible_for_testing_member
    await _bloc.close();

    if (expectAfter != null) {
      await expectAfter(_bloc);
    }
  }, timeout: Timeout(timeout));
}
