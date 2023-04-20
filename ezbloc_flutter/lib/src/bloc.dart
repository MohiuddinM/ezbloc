import 'package:ezbloc/ezbloc.dart' as s;
import 'package:flutter/widgets.dart';

/// Helper class to contain [s.BlocListener] and a [BuildContext]
class _WidgetListener {
  final BuildContext context;
  final s.BlocListener callback;

  const _WidgetListener(this.context, this.callback);

  bool get isDisposed => !context.mounted;
}

/// Extending [s.Bloc] here, because this one has a dependency on
/// the flutter sdk
abstract class Bloc<T> extends s.Bloc<T> {
  final _listeners = <_WidgetListener>[];

  /// Notifies listeners of any events taking place inside this bloc. A widget
  /// can only call this once.
  ///
  /// Similar to [addListener], but this one does not need [removeListener]
  /// to be called when the widget is disposed. Instead, this one takes a
  /// [BuildContext] to track listening widget, and removes callback
  /// automatically.
  void listen(BuildContext context, s.BlocListener callback) {
    final i = _listeners.indexWhere((e) => e.context == context);
    if (i == -1) {
      _listeners.add(_WidgetListener(context, callback));
    }
  }

  @protected
  @mustCallSuper
  void notifyListeners(s.BlocEventType type) {
    _listeners.removeWhere((e) => e.isDisposed);

    for (final listener in _listeners) {
      listener.callback(type);
    }

    super.notifyListeners(type);
  }
}
