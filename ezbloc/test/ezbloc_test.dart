import 'package:ezbloc/ezbloc.dart';
import 'package:test/test.dart';

class BroadcastPrinter extends BlocMonitor {
  @override
  void onBroadcast(String blocName, state, {String? event}) {
    print('[$blocName] broadcast: $state ($event)');
  }
}

class CounterBloc extends Bloc<int> {
  CounterBloc([int? initialState]) : super(initialState: initialState);

  void increment() => setState(state + 1);

  void decrement() => setState(state - 1);
}

class IncrementOnlyCounterBloc extends Bloc<int> {
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
  Bloc.checkIfValueType = false;
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
      'only unique states should be broadcast',
      bloc: () async => CounterBloc(0),
      expectedStates: emitsInOrder([0, 1, 2]),
      job: (bloc) async {
        // ignore: invalid_use_of_protected_member
        bloc.setState(0);
        // ignore: invalid_use_of_protected_member
        bloc.setState(1);
        // ignore: invalid_use_of_protected_member
        bloc.setState(1);
        // ignore: invalid_use_of_protected_member
        bloc.setState(2);
        // ignore: invalid_use_of_protected_member
        bloc.setState(2);
      },
    );

    testBloc<CounterBloc, int>(
      'same state can be broadcast if busy or error has been set',
      bloc: () async => CounterBloc(0),
      expectedStates: emitsInOrder([0, 0, 0]),
      job: (bloc) async {
        // ignore: invalid_use_of_protected_member
        bloc.setState(0);

        // ignore: invalid_use_of_protected_member
        bloc.setBusy();

        // ignore: invalid_use_of_protected_member
        bloc.setState(0);

        // ignore: invalid_use_of_protected_member
        bloc.setError(StateError(''));

        // ignore: invalid_use_of_protected_member
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
        // ignore: invalid_use_of_protected_member
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
        // ignore: invalid_use_of_protected_member
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
  });
}
