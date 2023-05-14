import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

import 'bloc_event_type.dart';
import 'bloc_listener_callback.dart';
import 'bloc_monitor.dart';

/// The central class behind this library
///
/// It is responsible for processing all the events and broadcasting corresponding
/// changes made to the state.
/// [R] is the type which subclasses [Bloc]
/// [S] is the type of [value] which this bloc broadcasts. [S] must implement equality
base class Bloc<S> {
  static const bool _kReleaseMode = bool.fromEnvironment(
    'dart.vm.product',
    defaultValue: false,
  );

  /// If set to true, the calling function's name will be used as event name,
  /// if event name is not already set.
  /// Library uses StackTrace [_caller] to find name of calling function, and
  /// this is not always possible.
  static bool callerAsEventName = !_kReleaseMode;

  final BlocMonitor _monitor;

  Error? _error;
  bool _isBusy = true;
  BehaviorSubject<S?>? _stream;
  S? _state;

  /// [initialState] is the state which is set at initialization. if its null, the initial state is set to busy.
  Bloc({S? initialState, BlocMonitor monitor = const BlocEventsPrinter()})
      : _state = initialState,
        _monitor = monitor {
    notifyListeners(BlocEventType.init);
    _monitor.onInit(this, _state);
    if (_state != null) {
      _isBusy = false;
    }
  }

  /// Broadcast Stream to which all builders listen
  ///
  /// This stream is created only when there is a listener, and is automatically cleaned
  /// when there are no listeners are left. State change broadcasts are discarded when there
  /// are no listeners.
  Stream<S?> get stream {
    _monitor.onStreamListener(this);

    if (_stream == null) {
      onActivate();
    }

    return _stream!.stream;
  }

  /// Called when [Bloc] get the first listener and [stream] is created
  @mustCallSuper
  void onActivate() {
    _stream = _state == null
        ? BehaviorSubject<S?>()
        : BehaviorSubject<S?>.seeded(_state);

    _stream!.onCancel = () {
      if (_stream != null && !_stream!.hasListener) {
        onDeactivate();
      }
    };
  }

  /// Called when [Bloc] has no more listeners and [stream] is being closed
  @mustCallSuper
  void onDeactivate() {
    notifyListeners(BlocEventType.streamClosed);
    _monitor.onStreamDispose(this);
    _stream!.close();
    _stream = null;
  }

  bool get hasState => _state != null;

  S get state {
    final state = _state;

    if (state != null) {
      return state;
    }

    throw ArgumentError.notNull('state');
  }

  bool get isBusy => _isBusy;

  bool get hasError => _error != null;

  Error get error => _error!;

  /// Callback functions that will be called on bloc updated
  final _eventListeners = <BlocListener>[];

  /// Adds a callback function to the list on active callbacks
  ///
  /// These listeners can be used to cause side effects to bloc events
  void addListener(BlocListener callback) {
    _eventListeners.add(callback);
  }

  /// Removes a callback function from the list
  void removeListener(BlocListener callback) {
    _eventListeners.remove(callback);
  }

  /// Calls all callbacks currently active
  @protected
  @mustCallSuper
  void notifyListeners(BlocEventType type) {
    _eventListeners.forEach((e) => e(type));
  }

  /// Called to calculate the new state
  ///
  /// This function takes [currentState] and the planned [update] state
  /// and returns the state which would be broadcast and will become the current state
  ///
  /// Originally it just discards the current state and returns the [update] as the next state.
  /// This behavior can of course be overridden
  ///
  /// If this function returns null, nothing will be broadcast
  @protected
  S? nextState(S? currentState, S update) {
    return update;
  }

  /// Called by blocs (subclasses) when the state is updated
  ///
  /// [isBusy] and [error] are cleared whenever the state is updated
  /// Optional argument [event] is the name of event which is calling [setState]
  @protected
  void setState(S update, {String? event}) {
    if (callerAsEventName) {
      event ??= _caller;
    }

    final _stream = this._stream;
    _monitor.onEvent(this, _state, update, event: event);
    final next = nextState(_state, update);
    _isBusy = false;
    _error = null;

    if (next == null) {
      return;
    }

    _state = next;
    if (_stream != null) {
      _stream.add(_state);
      notifyListeners(BlocEventType.stateChange);
      _monitor.onBroadcast(this, _state, event: event);
    }
  }

  /// Called by blocs (subclasses) when an error occurs
  ///
  /// [isBusy] is cleared whenever an [error] is set
  /// Optional argument [event] is the name of event which is calling [setError]
  @protected
  void setError(dynamic error, {String? event}) {
    error = error is Error ? error : StateError(error.toString());

    if (callerAsEventName) {
      event ??= _caller;
    }

    _monitor.onError(this, error, event: event);
    _isBusy = false;
    _error = error;
    _stream?.add(null);
    notifyListeners(BlocEventType.error);
  }

  /// Called by blocs (subclasses) when the updated state isn't available immediately
  ///
  /// This should be used when a bloc is waiting for an async operation (e.g. a network call)
  /// [error] is cleared whenever [isBusy] is set
  /// Optional argument [event] is the name of event which is calling [setError]
  @protected
  void setBusy({String? event}) {
    if (_isBusy) return;
    if (callerAsEventName) {
      event ??= _caller;
    }

    _monitor.onBusy(this, event: event);
    _isBusy = true;
    _error = null;
    _stream?.add(null);
    notifyListeners(BlocEventType.busy);
  }

  /// Broadcasts the same [state]
  ///
  /// This method can be used to refresh the UI, without setting a new state.
  @protected
  void refresh() {
    _stream?.add(_state);
  }

  /// Send a done event and disposes the stream
  ///
  /// It is not necessary to call this function as the stream is disposed automatically.
  /// But is useful for testing, in cases where otherwise the tester keeps waiting until done.
  @visibleForTesting
  Future<void> close() async {
    if (_stream != null) {
      notifyListeners(BlocEventType.streamClosed);
      _monitor.onStreamDispose(this);
      await _stream!.close();
      _stream = null;
    }
  }

  String? get _caller {
    try {
      final closest = StackTrace.current
          .toString()
          .split('#')
          .firstWhere((e) => e.contains(runtimeType.toString()));

      final parts = closest.substring(7).split(' ').first.split('.');
      final lastPart = parts.removeLast();
      final secondLastPart = parts.removeLast();

      if (lastPart.contains('<anonymous')) {
        return secondLastPart;
      }

      return lastPart;
    } catch (e) {
      return null;
    }
  }
}
