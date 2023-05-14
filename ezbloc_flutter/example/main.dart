import 'package:ezbloc_flutter/ezbloc_flutter.dart';
import 'package:flutter/material.dart';

final class CounterBloc extends AutoPersistedBloc<int> {
  final int counterNumber;

  CounterBloc({this.counterNumber = 0})
      : super(InMemoryPersistenceService(), startState: 0);

  void increment() => setState(state + 1, event: 'increment');

  void decrement() => setState(state - 1, event: 'decrement');
}

final counterBlocResolver = BlocResolver<CounterBloc, int>(
  (arg) => CounterBloc(counterNumber: arg ?? 0),
);

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bloc = counterBlocResolver();

    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('You have pushed the button this many times:'),
              bloc.builder(
                onState: (context, data) => Text(data.toString(),
                    style: Theme.of(context).textTheme.headlineMedium),
                onBusy: (_) => Text('Working'),
                onError: (_, e) => Text('Error Occurred'),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: bloc.increment,
        ),
      ),
    );
  }
}

void main() async {
  runApp(MyApp());
}
