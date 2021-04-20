import 'package:counter_example/counter_text.dart';
import 'package:ezbloc_flutter/ezbloc_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class BlocPrinter extends BlocMonitor {
  @override
  void onEvent(Bloc bloc, currentState, update, {String event}) {
  }
}

class PersistedCounterBloc extends AutoPersistedBloc<int> {
  final int counterNumber;

  PersistedCounterBloc({@required this.counterNumber})
      : super(initialState: 0, tag: counterNumber, monitor: BlocPrinter());

  void increment() async {
    setBusy();
    await Future.delayed(Duration(milliseconds: 1000));
    setState(state + counterNumber, event: 'increment');
  }

  void decrement() => setState(state - counterNumber, event: 'decrement');
}

class CounterBloc extends Bloc<int> {
  final int counterNumber;

  CounterBloc({this.counterNumber}) : super(initialState: 0);

  void increment() => setState(state + 1);

  void decrement() => setState(state - 1);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final counterBloc = CounterBloc();
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('You have pushed the button this many times:'),
              BlocContainer.get<PersistedCounterBloc>(arg: 1).builder(
                onState: (context, int data) => Text(data.toString(),
                    style: Theme.of(context).textTheme.headline4),
                onError: (_, e) => Text('Error Occurred'),
              ),
              Text('Provider:'),
              BlocProvider(bloc: counterBloc, child: CounterText()),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () {
            counterBloc.increment();
            BlocContainer.get<PersistedCounterBloc>(arg: 1).increment();
            BlocContainer.get<PersistedCounterBloc>(arg: 2).increment();
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
  BlocContainer.add<PersistedCounterBloc>(
      (context, arg) => PersistedCounterBloc(counterNumber: arg));
  runApp(MyApp());
}
