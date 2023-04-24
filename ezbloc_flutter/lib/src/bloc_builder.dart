import 'dart:math';

import 'package:flutter/material.dart';

import 'bloc.dart';

/// This function takes a [context] and [data] of type [T] and returns a widget
///
/// Used when bloc updates its state and widget needs to rebuild with new data
typedef DataBuilder<T> = Widget Function(BuildContext context, T data);

/// This function takes a [context] and an [error] and returns a widget
///
/// Used when bloc sets an error and an error widget should be built to show that error
typedef ErrorBuilder = Widget Function(BuildContext context, Error error);

/// This function takes [pastState] and [currentState]
///
/// Return true if the build should be skipped, otherwise false
typedef ShouldSkip<T> = bool Function(T pastState, T currentState);

/// This function takes a [BuildContext], [Bloc], and a [Widget] and returns a widget
///
/// Used when bloc an [ErrorBuilder] is not provided to a [BlocBuilder]
typedef GlobalErrorBuilder = Widget Function(
  BuildContext context,
  Bloc bloc,
  Widget? lastStateBuild,
);

/// This function takes a [BuildContext], [Bloc], and a [Widget] and returns a widget
///
/// Used when bloc an onBusy is not provided to a [BlocBuilder]
typedef GlobalBusyBuilder = Widget Function(
  BuildContext context,
  Bloc bloc,
  Widget? lastStateBuild,
);

class BlocBuilder<S> extends StatelessWidget {
  /// Bloc whose broadcasts  this builder listens to
  final Bloc<S> bloc;

  /// This is called whenever there is a valid state update in the provided bloc (setState)
  final DataBuilder<S> onState;

  /// This is called whenever the bloc sets the onBusy flag (setBusy)
  final WidgetBuilder? onBusy;

  /// This is called whenever the bloc sets an error (setError)
  final ErrorBuilder? onError;

  /// This is called on every event can be used to skip rebuild on an event
  ///
  /// Widget is rebuild if this returns false
  /// Rebuild is skipped if this returns true
  final ShouldSkip<S?>? shouldSkip;

  /// This is called when there is an error but no [onError] is defined
  static GlobalErrorBuilder globalOnError = (context, bloc, lastStateBuild) {
    final error = bloc.error;

    if (lastStateBuild != null) {
      return lastStateBuild;
    }

    return Container(
      color: Colors.red,
      child: Center(
        child: Text(error.toString()),
      ),
    );
  };

  /// This is called when there is an busy state but no [onBusy] is defined
  static GlobalBusyBuilder globalOnBusy = (_, __, ___) {
    return LayoutBuilder(
      builder: (context, crts) {
        if (crts.maxHeight < 10 || crts.maxWidth < 10) {
          // Size is too small to draw a CircularProgressIndicator
          return const SizedBox();
        }

        return Center(
          child: SizedBox(
            width: min(60, crts.maxWidth),
            height: min(60, crts.maxHeight),
            child: CircularProgressIndicator.adaptive(),
          ),
        );
      },
    );
  };

  static final _defaultShouldSkip = (_, __) => false;

  const BlocBuilder({
    Key? key,
    required this.bloc,
    required this.onState,
    this.onBusy,
    this.onError,
    this.shouldSkip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final onBusy = this.onBusy;
    final onState = this.onState;
    final onError = this.onError;

    return StreamBuilder<S?>(
      stream: bloc.stream
          .distinct(shouldSkip ?? _defaultShouldSkip)
          .asBroadcastStream(),
      builder: (context, s) {
        if (bloc.isBusy) {
          if (onBusy != null) {
            return onBusy(context);
          } else {
            return globalOnBusy(
              context,
              bloc,
              bloc.hasState ? onState(context, bloc.state) : null,
            );
          }
        }

        if (bloc.hasError) {
          if (onError != null) {
            return onError(context, bloc.error);
          } else {
            return globalOnError(
              context,
              bloc,
              bloc.hasState ? onState(context, bloc.state) : null,
            );
          }
        }

        if (bloc.hasState && s.data != null) {
          return onState(context, s.data!);
        }

        throw StateError('${s.connectionState}, ${s.data}, ${s.error}');
      },
    );
  }
}
