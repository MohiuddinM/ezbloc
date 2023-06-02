# ezbloc_flutter

`ezbloc_flutter` is a Flutter package that simplifies state management using the BLoC pattern. It provides a collection of widgets and utilities to make it easy to manage state and build reactive UIs.

## Pros

- Simplifies state management using the BLoC pattern
- Compile time checking to prevent type and null errors at runtime
- Easy to use with a clean and intuitive API
- Reduces boilerplate code and improves code organization
- Supports both synchronous and asynchronous operations


## Bloc Builder
Keeps your UI in sync with the State of your app. It's StatelessWidget widget that only rebuilds the relative child, instead of rebuilding entire page.

```dart
bloc.builder(
  onState: (context, data) => Text(data.toString()),
  onBusy: (_, data) => Text('Working'),
  onError: (_, e) => Text('Error Occurred: $e'),
)
```

for details [see example](https://pub.dev/packages/ezbloc_flutter#-example-tab-)

## Bloc Container
A container where you can store all your blocs on app startup, and then access them anywhere in your app independently of the widget tree.
```dart
void main() {
  BlocContainer.add((context, args) => CounterBloc(args));
  final counterBloc = BlocContainer.get(arg: 0);
}
```
[see example](https://pub.dev/packages/ezbloc_flutter#-example-tab-)


## Contribution ❤
Issues and pull requests are welcome

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/MohiuddinM/ezbloc