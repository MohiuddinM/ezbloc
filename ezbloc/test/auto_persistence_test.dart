import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ezbloc/ezbloc.dart';
import 'package:test/test.dart';
import 'auto_persistence_test.mocks.dart';

class BlocPrinter extends BlocMonitor {
  @override
  void onEvent(String blocName, currentState, update, {String? event}) {
    print('[$blocName] currentState: $currentState, update: $update ($event)');
  }

  @override
  void onBroadcast(String blocName, state, {String? event}) {
    print('[$blocName] broadcast: $state ($event)');
  }
}

class Int {
  final int value;

  Int(this.value);

  Int.fromJson(Map<String, dynamic> json) : value = json['value'];

  Map<String, Object> toJson() => {'value': value};

  Int operator +(int other) => Int(value + other);

  Int operator -(int other) => Int(value - other);

  @override
  bool operator ==(Object o) => o is Int && o.value == value;
}

class CounterBloc extends AutoPersistedBloc<Int> {
  final int counterNumber;

  CounterBloc({required this.counterNumber, Int? initialState})
      : super(
            initialState: initialState,
            tag: counterNumber,
            monitor: BlocPrinter());

  void increment() => setState(state + 1, event: 'increment');

  void decrement() => setState(state - 1, event: 'decrement');
}

@GenerateMocks([PersistenceService])
void main() {
  PersistenceService.addDeserializer((json) => Int.fromJson(json));
  HivePersistenceService.runningInTest = true;
  HivePersistenceService.databaseDirectory = '.';

  final counter1 = MockPersistenceService();
  final counter2 = MockPersistenceService();

  setUp(() => Bloc.checkIfValueType = false);
  tearDownAll(() {});

  testBloc<CounterBloc, Int>(
    'bloc should work with hive persistence',
    expectBefore: (bloc) async {
      expect(bloc.isBusy, true);
    },
    expectAfter: (bloc) async {},
    bloc: () async => CounterBloc(counterNumber: 1, initialState: Int(0)),
    transform: (i) => i.value,
    expectedStates: emitsInOrder([0, 1, 0]),
    job: (bloc) async {
      bloc.increment();
      bloc.decrement();
    },
  );

  test('bloc should recover initial state', () async {
    PersistenceService.use(
        (name) => name == 'CounterBloc.1' ? counter1 : counter2);
    when(counter1.get<Int>(any)).thenAnswer((realInvocation) async => Int(1));
    when(counter2.get<Int>(any)).thenAnswer((realInvocation) async => Int(2));

    final bloc1 = CounterBloc(counterNumber: 1);
    final bloc2 = CounterBloc(counterNumber: 2);

    expect(bloc1.isBusy, true);
    expect(bloc2.isBusy, true);
    expect(() => bloc1.state, throwsA(TypeMatcher<StateError>()));
    expect(() => bloc2.state, throwsA(TypeMatcher<StateError>()));

    await Future.delayed(Duration(seconds: 1));

    expect(bloc1.state, Int(1));
    expect(bloc2.state, Int(2));

    verify(counter1.get(any)).called(1);
    verify(counter2.get(any)).called(1);
  });
}
