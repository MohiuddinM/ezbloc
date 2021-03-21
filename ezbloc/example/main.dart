import 'package:ezbloc/ezbloc.dart';

class BroadcastPrinter extends BlocMonitor {
  @override
  void onBroadcast(String blocName, state, {String? event}) {
    print('[$blocName] broadcast: $state ($event)');
  }
}

class CounterBloc extends Bloc<int> {
  CounterBloc() : super(initialState: 0, monitor: BroadcastPrinter());

  // event names are optional and only used for debugging purpose
  void increment() => setState(state + 1, event: 'increment');
  void decrement() => setState(state - 1, event: 'decrement');
}

void main() {
  final bloc = CounterBloc();

  bloc.stream.listen((s) => print(s));

  bloc.increment();
  bloc.decrement();
}
