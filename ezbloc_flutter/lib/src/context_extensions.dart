import 'package:flutter/widgets.dart';

import 'bloc.dart';
import 'bloc_builder.dart';
import 'bloc_provider.dart';
import 'bloc_extensions.dart';

extension ContextX<S> on BuildContext {
  bool get isDisposed => !mounted;

  /// Get a [Bloc] that exists in an ancestor widget
  ///
  /// returns null if none is found
  R? bloc<R extends Bloc<S>>() {
    return BlocProvider.of<R>(this);
  }


  /// Get the current [Bloc.state] from a [Bloc] that exists in an ancestor
  /// widget
  ///
  /// returns null if none is found
  S? blocState<R extends Bloc<S>>() {
    final bloc = BlocProvider.of<R>(this);
    final hasState = bloc?.hasState ?? false;
    return hasState ? bloc!.state : null;
  }

  @Deprecated('use [blocState]')
  S? blocValue<R extends Bloc<S>>() {
    final bloc = BlocProvider.of<R>(this);
    return bloc?.state;
  }

  @Deprecated('use [bloc.builder]')
  Widget blocBuilder<R extends Bloc<S>>({
    Key? key,
    required DataBuilder<S> onState,
    BusyBuilder<S>? onBusy,
    ErrorBuilder? onError,
  }) {
    final bloc = BlocProvider.of<R>(this);
    return bloc!.builder(
      key: key,
      onState: onState,
      onBusy: onBusy,
      onError: onError,
    );
  }
}
