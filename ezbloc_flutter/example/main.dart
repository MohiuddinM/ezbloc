import 'dart:async';

import 'package:ezbloc_flutter/ezbloc_flutter.dart';
import 'package:flutter/material.dart';

final class CounterBloc extends AutoPersistedBloc<int> {
  final int counterNumber;

  CounterBloc({this.counterNumber = 0})
      : super(InMemoryPersistenceService(), startState: 0);

  Timer? _timer;

  @override
  void onActivate() {
    super.onActivate();

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      increment();
    });
  }

  @override
  void onDeactivate() {
    super.onDeactivate();

    _timer?.cancel();
  }

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
                onState: (context, data) => Text(
                  data.toString(),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                onBusy: (_, __) => Text('Working'),
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
