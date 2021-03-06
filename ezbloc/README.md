A State management library for Dart and Flutter using BLoCs (Business Logic Component)

Checkout the flutter version too: [ezbloc_flutter](https://pub.dev/packages/ezbloc_flutter)

## Why?
This library provides a simpler alternative for existing libraries which: 
- Require a lot of boilerplate code
- Expose complexity of underlying reactive streams

## Pros 👍
- Easy to use and works out of the box
- Complete abstraction over Streams and Subscriptions
- No more states or events boilerplate bloat (just work with functions)

## Example
Easy Bloc hides all *streams*/*yields*, exposing only simple functions **setState()**, **setBusy()** and **setError()**:

```dart
import 'package:ezbloc/ezbloc.dart';

class CounterBloc extends Bloc {
  void increment() => setState(value + 1);
  void decrement() => setState(value - 1);
}

void main() {
  final bloc = CounterBloc();
  
  bloc.increment();
}
```

&nbsp; 

##### A bit more complex bloc:
AutoPersistedBloc can be used to save value on app exit, and recover again on app start. Keeps State in sync, shows error messages and  loading indicator.

```dart
import 'package:ezbloc/ezbloc.dart';

class CounterBloc extends AutoPersistedBloc<CounterBloc, int> {
  void increment() async {
    if (value >= 10) {
      setError(StateError('Counter cannot go beyond 10'));
    }
    
    setBusy();
    await makeNetworkCall();
    
    setState(value + 1);
  }

  void decrement() => setState(value - 1);
}

void main() async {
  final bloc = CounterBloc();
  
  await bloc.increment();
}
```
## Bloc Monitor
You can monitor your blocs and create side effects simply by using a bloc monitor.
```dart
 class BroadcastPrinter extends BlocMonitor {
   @override
   void onBroadcast(String blocName, state, {String event}) {
     print('[$blocName] broadcast: $state ($event)');
   }
 }
```

For more details: [bloc monitor](https://pub.dev/documentation/ezbloc/latest/ezbloc/BlocMonitor-class.html)

## Test
```dart
testBloc<CounterBloc, int>(
    'counter should work',
    bloc: () async => CounterBloc(0),
    expectBefore: (bloc) async => expect(bloc.isBusy, false),
    expectAfter: (bloc) async => expect(bloc.hasError, false),
    timeout: Duration(seconds: 1),
    expectedStates: emitsInOrder([0, 1, 2, 1]),
    job: (bloc) async {
      bloc.increment();
      bloc.increment();
      bloc.decrement();
    },
  );
```

## Contribution ❤
Issues and pull requests are welcome

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/MohiuddinM/ezbloc
