import 'package:ezbloc_flutter/ezbloc_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class BlocPrinter extends BlocMonitor {
  @override
  void onEvent(String blocName, currentState, update, {String event}) {
    print('[$blocName] $currentState ($event)');
  }
}

class CounterBloc extends AutoPersistedBloc<int> {
  final int counterNumber;

  CounterBloc({@required this.counterNumber})
      : super(initialState: 0, tag: counterNumber, monitor: BlocPrinter());

  void increment() async {
    setBusy();
    await Future.delayed(Duration(milliseconds: 1000));
    setState(state + counterNumber, event: 'increment');
  }

  void decrement() => setState(state - counterNumber, event: 'decrement');
}

//class CounterBloc extends Bloc<CounterBloc, int> {
//  final int counterNumber;
//
//  CounterBloc({this.counterNumber}) : super(initialState: 0);
//
//  void increment() => setState(value + 1, op: 'increment');
//
//  void decrement() => setState(value - 1, op: 'decrement');
//}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('You have pushed the button this many times:'),
              BlocContainer.get<CounterBloc>(arg: 1).builder(
                onUpdate: (context, int data) => Text(data.toString(),
                    style: Theme.of(context).textTheme.headline4),
                onError: (_, e) => Text('Error Occurred'),
              ),
              BlocContainer.get<CounterBloc>(arg: 2).builder(
                onUpdate: (context, int data) => Text(data.toString(),
                    style: Theme.of(context).textTheme.headline4),
                onError: (_, e) => Text('Error Occurred'),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () {
            BlocContainer.get<CounterBloc>(arg: 1).increment();
            BlocContainer.get<CounterBloc>(arg: 2).increment();
          },
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    HivePersistenceService.databaseDirectory = '';
  } else {
    HivePersistenceService.databaseDirectory =
        (await getTemporaryDirectory()).path;
  }
  BlocContainer.add<CounterBloc>(
      (context, arg) => CounterBloc(counterNumber: arg));
  runApp(MyApp());
}
