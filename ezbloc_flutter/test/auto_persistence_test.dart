import 'package:ezbloc_flutter/ezbloc_flutter.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_test/flutter_test.dart';
import 'auto_persistence_test.mocks.dart';

class BlocPrinter extends BlocMonitor {
  @override
  void onEvent(bloc, currentState, update, {String? event}) {
    print('[$bloc] currentState: $currentState, update: $update ($event)');
  }

  @override
  void onBroadcast(bloc, state, {String? event}) {
    print('[$bloc] broadcast: $state ($event)');
  }
}

class Int {
  final int value;

  Int(this.value);

  Int operator +(int other) => Int(value + other);

  Int operator -(int other) => Int(value - other);

  @override
  bool operator ==(Object o) => o is Int && o.value == value;

  @override
  String toString() => value.toString();

  @override
  int get hashCode => value.hashCode;
}

final class IntBloc extends AutoPersistedBloc<Int> {
  IntBloc(
    super._persistenceService, {
    required super.tag,
    super.startState,
  }) : super(
          monitor: BlocPrinter(),
          deserializer: (j) => Int(j),
          serializer: (i) => i.value,
        );

  void increment() => setState(state + 1, shouldPersist: true);

  void decrement() => setState(state - 1, shouldPersist: true);

  @override
  String toString() => persistenceKey;
}

final class IntBloc2 extends AutoPersistedBloc<Int> {
  IntBloc2({super.deserializer, super.serializer})
      : super(
          InMemoryPersistenceService(),
          monitor: BlocPrinter(),
          tag: 0,
        );
}

final class IntBloc3 extends AutoPersistedBloc<int> {
  IntBloc3({super.deserializer, super.serializer})
      : super(
          InMemoryPersistenceService(),
          monitor: BlocPrinter(),
          tag: 0,
        );
}

final class PrimitiveBloc extends AutoPersistedBloc<int> {
  PrimitiveBloc(
    super._persistenceService, {
    required super.tag,
    super.startState,
  }) : super(
          monitor: BlocPrinter(),
        );

  void increment() => setState(state + 1, shouldPersist: true);

  void decrement() => setState(state - 1, shouldPersist: true);

  @override
  String toString() => persistenceKey;
}

@GenerateMocks([PersistenceService])
void main() {
  late InMemoryPersistenceService testPersistence;
  late MockPersistenceService mockPersistence1;
  late MockPersistenceService mockPersistence2;

  setUp(() {
    testPersistence = InMemoryPersistenceService();
    mockPersistence1 = MockPersistenceService();
    mockPersistence2 = MockPersistenceService();
  });

  tearDownAll(() {});

  testBloc<IntBloc, Int>(
    'bloc should work with hive persistence',
    expectBefore: (bloc) async {
      expect(bloc.isBusy, true);
    },
    expectAfter: (bloc) async {},
    bloc: () async => IntBloc(
      HivePersistenceService('default', inMemory: true),
      tag: 1,
      startState: Int(0),
    ),
    transform: (bloc, i) => i.value,
    expectedStates: emitsInOrder([0, 1, 0]),
    job: (bloc) async {
      bloc.increment();
      bloc.decrement();
    },
  );

  test('bloc should recover initial state', () async {
    when(mockPersistence1.get(any)).thenAnswer(
      (realInvocation) async => Int(1),
    );
    when(mockPersistence2.get(any)).thenAnswer(
      (realInvocation) async => Int(2),
    );

    final bloc1 = IntBloc(mockPersistence1, tag: 1);
    final bloc2 = IntBloc(mockPersistence2, tag: 2);

    expect(bloc1.isBusy, true);
    expect(bloc2.isBusy, true);

    expect(() => bloc1.state, throwsA(isArgumentError));
    expect(() => bloc2.state, throwsA(isArgumentError));

    await Future.delayed(Duration(seconds: 1));

    expect(bloc1.state, Int(1));
    expect(bloc2.state, Int(2));

    verify(mockPersistence1.get(any)).called(1);
    verify(mockPersistence2.get(any)).called(1);
  });

  test('bloc should recover saved state at initialization', () async {
    await testPersistence.set('IntBloc.1', 5);
    final bloc1 = IntBloc(testPersistence, tag: 1, startState: Int(0));

    await bloc1.initialization;

    expect(bloc1.state, Int(5));
  });

  test('bloc should use startState if no state is saved', () async {
    final bloc1 = IntBloc(testPersistence, tag: 1, startState: Int(9));

    await bloc1.initialization;

    expect(bloc1.state, Int(9));
  });

  test('setState persists state only if shouldPersist is true', () async {
    final bloc = IntBloc(testPersistence, tag: 1, startState: Int(0));
    await bloc.initialization;

    bloc.setState(Int(5));

    expect(bloc.state, Int(5));
    expect(testPersistence.values, isEmpty);
  });

  test('setState throws error for providing wrong serializer', () async {
    final bloc = IntBloc2(
      deserializer: (x) => Int(x),
      serializer: (x) => x,
    );

    expect(
      () => bloc.setState(Int(1), shouldPersist: true),
      throwsUnsupportedError,
    );
  });

  test('two blocs can use same persistence service', () async {
    final bloc1 = IntBloc(testPersistence, tag: 1, startState: Int(0));
    final bloc2 = IntBloc(testPersistence, tag: 2, startState: Int(1));

    await bloc1.initialization;
    await bloc2.initialization;

    bloc1.increment();
    bloc2.increment();

    expect(bloc1.state, Int(1));
    expect(bloc2.state, Int(2));
  });

  test('2 bloc recovers previous state on initialization', () async {
    final bloc1 = IntBloc(testPersistence, tag: 1, startState: Int(0));

    await bloc1.initialization;

    bloc1.increment();

    final bloc2 = IntBloc(testPersistence, tag: 1, startState: Int(0));

    await bloc2.initialization;

    expect(bloc1.state, bloc2.state);
  });

  test('deserializer is not required for primitive value', () async {
    expect(() => IntBloc3(), returnsNormally);
  });

  test('serializer is not required for primitive value', () async {
    expect(() => IntBloc3(), returnsNormally);
  });

  test('throws error if deserializer is not provided for non-primitive value',
      () async {
    expect(
      () => IntBloc2(serializer: (_) => ''),
      throwsA(isA<AssertionError>()),
    );
  });

  test('throws error if serializer is not provided for non-primitive value',
      () async {
    expect(
      () => IntBloc2(deserializer: (_) => Int(0)),
      throwsA(isA<AssertionError>()),
    );
  });
}
