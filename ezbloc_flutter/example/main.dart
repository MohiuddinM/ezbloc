import 'package:ezbloc_flutter/ezbloc_flutter.dart';
import 'package:path_provider/path_provider.dart' as paths;
import 'package:flutter/material.dart';

class CounterBloc extends AutoPersistedBloc<int> {
  final int counterNumber;

  CounterBloc({this.counterNumber = 0}) : super(initialState: 0);

  void increment() => setState(state + 1, event: 'increment');

  void decrement() => setState(state - 1, event: 'decrement');
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bloc = BlocContainer.get<CounterBloc>();

    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('You have pushed the button this many times:'),
              bloc.builder(
                onState: (context, data) => Text(data.toString(),
                    style: Theme.of(context).textTheme.headline4),
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
  final documentsDir = (await paths.getApplicationDocumentsDirectory()).path;
  HivePersistenceService.databaseDirectory = documentsDir;
  BlocContainer.add<CounterBloc>(
    (context, arg) => CounterBloc(counterNumber: arg),
  );
  runApp(MyApp());
}
