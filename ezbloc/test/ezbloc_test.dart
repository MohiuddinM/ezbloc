// ignore_for_file: invalid_use_of_protected_member

import 'package:ezbloc/ezbloc.dart';
import 'package:test/test.dart';

class BroadcastPrinter extends BlocMonitor {
  @override
  void onBroadcast(bloc, state, {String? event}) {
    print('[$bloc] broadcast: $state ($event)');
  }
}

final class CounterBloc extends Bloc<int> {
  CounterBloc([int? initialState]) : super(initialState: initialState);

  void increment() => setState(state + 1);

  void decrement() => setState(state - 1);
}

final class IncrementOnlyCounterBloc extends Bloc<int> {
  IncrementOnlyCounterBloc([int? initialState])
      : super(initialState: initialState);

  @override
  int? nextState(int? currentState, int update) {
    return update > (currentState ?? 0) ? update : null;
  }

  void increment() => setState(state + 1, event: 'increment');

  void decrement() => setState(state - 1, event: 'decrement');
}

void main() {
  Bloc.callerAsEventName = true;
  group('bloc tests', () {
    test('bloc stream is broadcast', () {
      final bloc = CounterBloc(0);
      expect(bloc.stream.isBroadcast, isTrue);
    });

    testBloc<CounterBloc, int>(
      'counter should work',
      bloc: () async => CounterBloc(0),
      expectBefore: (bloc) async => expect(bloc.isBusy, false),
      expectAfter: (bloc) async => expect(bloc.hasError, false),
      expectedStates: emitsInOrder([0, 1, 2, 1]),
      job: (bloc) async {
        bloc.increment();
        bloc.increment();
        bloc.decrement();
      },
    );

    testBloc<CounterBloc, int>(
      'same state can be broadcast if busy or error has been set',
      bloc: () async => CounterBloc(0),
      expectedStates: emitsInOrder([0, 0, 0]),
      job: (bloc) async {
        bloc.setState(0);
        bloc.setBusy();
        bloc.setState(0);
        bloc.setError(StateError(''));
        bloc.setState(0);
      },
    );

    testBloc<CounterBloc, int>(
      'setting busy should not change value',
      bloc: () async => CounterBloc(0),
      expectBefore: (bloc) async => expect(bloc.isBusy, false),
      expectAfter: (bloc) async {
        //expect(bloc.value, 1);
        expect(bloc.isBusy, true);
      },
      expectedStates: emitsInOrder([0, 1]),
      job: (bloc) async {
        bloc.increment();
        bloc.setBusy();
      },
    );

    testBloc<CounterBloc, int>(
      'setting error should not change value',
      bloc: () async => CounterBloc(0),
      expectBefore: (bloc) async => expect(bloc.isBusy, false),
      expectAfter: (bloc) async {
        expect(bloc.state, 1);
        expect(bloc.hasError, true);
      },
      expectedStates: emitsInOrder([0, 1]),
      job: (bloc) async {
        bloc.increment();
        bloc.setError(StateError('error'));
      },
    );

    testBloc<CounterBloc, int>(
      'bloc should setBusy when initialState is not provided',
      bloc: () async => CounterBloc(),
      expectBefore: (bloc) async => expect(bloc.isBusy, isTrue),
      expectedStates: emitsDone,
      job: (bloc) async {},
    );

    testBloc<CounterBloc, int>(
      'isBusy and hasError should be false when valid initialState is provided',
      bloc: () async => CounterBloc(0),
      expectBefore: (bloc) async {
        expect(bloc.isBusy, isFalse);
        expect(bloc.hasError, isFalse);
      },
      expectedStates: emits(0),
      job: (bloc) async {},
    );

    testBloc<CounterBloc, int>(
      'bloc should only emit initialState when no actions are done',
      bloc: () async => CounterBloc(0),
      expectedStates: emitsInOrder([0]),
    );

    testBloc<IncrementOnlyCounterBloc, int>(
      'bloc can override which states are broadcast by overriding nextState',
      bloc: () async => IncrementOnlyCounterBloc(0),
      expectedStates: emitsInOrder([0, 1, 2]),
      job: (b) async {
        b.increment();
        b.decrement();
        b.increment();
        b.decrement();
        b.increment();
      },
    );

    testBloc<IncrementOnlyCounterBloc, int>(
      'value should remain cached even when stream is disposed',
      bloc: () async => IncrementOnlyCounterBloc(10),
      expectedStates: emitsInOrder([10, 11]),
      job: (b) async {
        b.increment();
        await b.close();
        expect(b.stream, emits(11));
      },
    );

    testBloc<CounterBloc, int>(
      'test non distinct states when testDistinctStatesOnly option is false',
      testDistinctStatesOnly: false,
      bloc: () async => CounterBloc(0),
      expectedStates: emitsInOrder([0, 1, 1, 1]),
      job: (b) async {
        b.increment();
        b.refresh();
        b.refresh();
      },
    );

    testBloc<CounterBloc, int>(
      'only test distinct states when testDistinctStatesOnly option is set',
      testDistinctStatesOnly: true,
      bloc: () async => CounterBloc(0),
      expectedStates: emitsInOrder([0, 1]),
      job: (b) async {
        b.increment();
        b.refresh();
        b.refresh();
      },
    );

    testBloc<CounterBloc, int>(
      'only test distinct transformed states when testDistinctStatesOnly option is set',
      testDistinctStatesOnly: true,
      bloc: () async => CounterBloc(0),
      transform: (bloc, state) => state + 1,
      expectedStates: emitsInOrder([1, 2]),
      job: (b) async {
        b.increment();
        b.refresh();
        b.refresh();
      },
    );

    testBloc<CounterBloc, int>(
      'transform works with different types',
      testDistinctStatesOnly: true,
      bloc: () async => CounterBloc(0),
      transform: (bloc, state) => state > 0,
      expectedStates: emitsInOrder([false, true]),
      job: (b) async {
        b.increment();
        b.refresh();
        b.refresh();
      },
    );

    testBloc<CounterBloc, int>(
      'setting busy has no effect on out states',
      testDistinctStatesOnly: true,
      bloc: () async => CounterBloc(0),
      expectedStates: emitsInOrder([0, 1]),
      job: (b) async {
        b.increment();
        b.setBusy();
        b.refresh();
        b.setBusy();
        b.refresh();
      },
    );
  });
}
