import 'package:ezbloc/ezbloc.dart';
import 'package:flutter/widgets.dart';

/// This function takes a [context] and [data] of type [T] and returns a widget
///
/// Used when bloc updates its state and widget needs to rebuild with new data
typedef DataBuilder<T> = Widget Function(BuildContext context, T data);

/// This function takes a [context] and an [error] and returns a widget
///
/// Used when bloc sets an error and an error widget should be built to show that error
typedef ErrorBuilder = Widget Function(BuildContext context, StateError error);

class BlocBuilder<S> extends StatelessWidget {
  /// Bloc whose broadcasts  this builder listens to
  final Bloc<S> bloc;

  /// This is called whenever there is a valid state update in the provided bloc (setState)
  final DataBuilder<S> onState;

  /// This is called whenever the bloc sets the onBusy flag (setBusy)
  final WidgetBuilder? onBusy;

  /// This is called whenever the bloc sets an error (setError)
  final ErrorBuilder? onError;

  const BlocBuilder({
    Key? key,
    required this.bloc,
    required this.onState,
    this.onBusy,
    this.onError,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // bloc.value can not be accessed here, because we are not sure if it is set or not
    // and if it is not set, then it will throw an error
    // bloc uses BehaviorSubject, so bloc.state should immediately return bloc.value if it was set
    return StreamBuilder<S?>(
      stream: bloc.stream,
      builder: (context, s) {
        if (bloc.isBusy || s.connectionState == ConnectionState.waiting) {
          if (onBusy != null) {
            return onBusy!(context);
          } else {
            throw Exception(
              'you must define onBusy function if your bloc uses "setBusy()"',
            );
          }
        }

        if (bloc.hasError) {
          if (onError != null) {
            return onError!(context, bloc.error);
          } else {
            throw ArgumentError(
              'you must define onError if your bloc uses "setError()"',
            );
          }
        }

        if (s.connectionState == ConnectionState.active ||
            s.connectionState == ConnectionState.done) {
          if (s.data == null) {
            assert(onError != null);
            return onError!(context,
                StateError('null data was sent on an active connection'));
          }

          return onState(context, s.data!);
        }

        throw StateError('${s.connectionState}, ${s.data}, ${s.error}');
      },
    );
  }
}
