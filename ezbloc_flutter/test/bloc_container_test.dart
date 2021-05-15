import 'package:ezbloc_flutter/ezbloc_flutter.dart';
import 'package:test/test.dart';

class CounterBloc extends Bloc<int> {
  void increment() => setState(state! + 1);

  void decrement() => setState(state! - 1);
}

class CounterBloc2 extends Bloc<int> {
  void increment() => setState(state! + 1);

  void decrement() => setState(state! - 1);
}

void main() {
  setUp(() => BlocContainer.clear());

  test('container should fetch same bloc for same arg', () {
    BlocContainer.add<CounterBloc>((context, arg) => CounterBloc());

    final bloc = BlocContainer.get<CounterBloc>(arg: 1);
    final bloc2 = BlocContainer.get<CounterBloc>(arg: 1);

    expect(bloc, bloc2);
  });

  test('container should fetch different blocs for different args', () {
    BlocContainer.add<CounterBloc>((context, arg) => CounterBloc());

    final bloc = BlocContainer.get<CounterBloc>(arg: 1);
    final bloc2 = BlocContainer.get<CounterBloc>(arg: 2);

    expect(bloc, isNot(bloc2));
  });

  test('container should fetch same blocs if arg is null', () {
    BlocContainer.add<CounterBloc>((context, arg) => CounterBloc());

    final bloc = BlocContainer.get<CounterBloc>();
    final bloc2 = BlocContainer.get<CounterBloc>();

    expect(bloc, bloc2);
  });

  test('container should fetch different blocs if useCache is false', () {
    BlocContainer.add<CounterBloc>((context, arg) => CounterBloc());

    final bloc = BlocContainer.get<CounterBloc>();
    final bloc2 = BlocContainer.get<CounterBloc>();
    final bloc3 = BlocContainer.get<CounterBloc>(useCache: false);

    expect(bloc, bloc2);
    expect(bloc, isNot(bloc3));
  });

  test('container should fetch bloc of specified type even if args are same',
      () {
    BlocContainer.add((context, arg) => CounterBloc());
    BlocContainer.add((context, arg) => CounterBloc2());

    final bloc2 = BlocContainer.get<CounterBloc2>();

    expect(bloc2.runtimeType, isNot(CounterBloc));
  });

  test('container should fetch bloc same blocs if arg is an equal list', () {
    final list1 = <int>[1, 2, 3];
    final list2 = <int>[1, 2, 3];

    BlocContainer.add((context, arg) => CounterBloc());

    final bloc1 = BlocContainer.get<CounterBloc>(arg: list1);
    final bloc2 = BlocContainer.get<CounterBloc>(arg: list2);

    expect(bloc1, bloc2);
  });

  test('clear should remove all blocs from container', () {
    BlocContainer.add((context, arg) => CounterBloc());
    BlocContainer.add((context, arg) => CounterBloc2());

    BlocContainer.clear();

    expect(() => BlocContainer.get<CounterBloc>(), throwsArgumentError);
    expect(() => BlocContainer.get<CounterBloc2>(), throwsArgumentError);
  });

  test(
      'clear called with a type should only remove blocs of that type from container',
      () {
    BlocContainer.add((context, arg) => CounterBloc());
    BlocContainer.add((context, arg) => CounterBloc2());

    BlocContainer.clear(CounterBloc);

    expect(() => BlocContainer.get<CounterBloc>(), throwsArgumentError);
    expect(BlocContainer.get<CounterBloc2>(), isA<CounterBloc2>());
  });
}
