import 'dart:async';

import 'package:meta/meta.dart';
import 'package:pedantic/pedantic.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:test/test.dart';

import 'bloc.dart';

typedef FutureVoidCallback = Future<void> Function();
typedef BlocCallback<R> = Future<void> Function(R);
typedef BlocTestBloc<R> = Future<R> Function();
typedef BlocTestTransform<R, S, T> = T Function(R, S);
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
  BlocTestTransform<R, S, dynamic>? transform,
  Duration timeout = const Duration(minutes: 1),
  bool testDistinctStatesOnly = false,
}) async {
  final frames = Chain.current().toTrace().terse.frames;
  final index = frames.indexWhere((element) {
    return element.member?.startsWith('main') ?? false;
  });
  final trace = frames[index].toString();

  test(description, () async {
    if (setup != null) {
      await setup();
    }

    final _bloc = await bloc();
    Stream stream = _bloc.stream.where((event) => event != null);

    if (transform != null) {
      stream = stream.map((event) => transform(_bloc, event!));
    }

    if (testDistinctStatesOnly) {
      stream = stream.distinct();
    }

    unawaited(expectLater(stream, expectedStates).onError(
      (error, stackTrace) {
        throw '$trace \n\n $error';
      },
    ));

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
