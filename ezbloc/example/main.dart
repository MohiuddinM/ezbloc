import 'package:ezbloc/ezbloc.dart';

class CounterBloc extends Bloc<int> {
  CounterBloc() : super(initialState: 0);

  // event names are optional and only used for debugging purpose
  void increment() => setState(state + 1, event: 'increment');

  void decrement() => setState(state - 1, event: 'decrement');
}

void main() {
  final bloc = CounterBloc();

  bloc.monitor.onBroadcast = (bloc, state, String? event) {
    print('[$bloc] broadcast: $state ($event)');
  };

  bloc.stream.listen((s) => print(s));

  bloc.increment();
  bloc.decrement();
}
