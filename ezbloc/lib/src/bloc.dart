import 'package:ezbloc/src/bloc_event.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

import 'bloc_monitor.dart';
import 'logger.dart';

enum BlocEventType {
  init,
  event,
  error,
  stateChange,
  busy,
  newDependent,
  streamClosed,
}

typedef BlocListener = void Function(BlocEventType type);

/// The central class behind this library
///
/// It is responsible for processing all the events and broadcasting corresponding
/// changes made to the state.
/// [R] is the type which subclasses [Bloc]
/// [S] is the type of [value] which this bloc broadcasts. [S] must implement equality
abstract class Bloc<S> {
  static const bool _kReleaseMode =
      bool.fromEnvironment('dart.vm.product', defaultValue: false);
  static const _log = EzBlocLogger('Bloc');

  /// This library requires the state type to either be a primitive or override == operator.
  /// Set this to false if you manually override ==.
  @Deprecated('has no use, will be removed in future')
  static bool checkIfValueType = false;

  /// If set to true, the calling function's name will be used as event name,
  /// if event name is not already set.
  /// Library uses StackTrace [_caller] to find name of calling function, and
  /// this is not always possible.
  static bool callerAsEventName = !_kReleaseMode;

  final BlocMonitor _monitor;

  StateError? _error;
  bool _isBusy = true;
  BehaviorSubject<S?>? _stream;
  S? _state;

  /// [initialState] is the state which is set at initialization. if its null, the initial state is set to busy.
  Bloc({S? initialState, BlocMonitor monitor = const BlocEventsPrinter()})
      : _state = initialState,
        _monitor = monitor {
    _notifyListeners(BlocEventType.init);
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
    _notifyListeners(BlocEventType.newDependent);
    _monitor.onStreamListener(this);
    if (_stream == null) {
      _stream =
          _state == null ? BehaviorSubject<S>() : BehaviorSubject.seeded(state);

      _stream!.onCancel = () {
        if (_stream != null && !_stream!.hasListener) {
          _notifyListeners(BlocEventType.streamClosed);
          _monitor.onStreamDispose(this);
          _stream!.close();
          _stream = null;
        }
      };
    }

    return _stream!.stream;
  }

  S get state {
    final _state = this._state;
    if (_state != null) {
      return _state;
    } else {
      throw StateError('state is accessed before it is set');
    }
  }

  bool get isBusy => _isBusy;

  bool get hasError => _error != null;

  StateError get error => _error!;

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
  void _notifyListeners(BlocEventType type) {
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
    if (currentState == update && !(_isBusy || hasError)) {
      _log.error('broadcast has been rejected because the update is equal '
          'to the already set state. If you only want to rebuild'
          ' UI, use refresh() instead');
      return null;
    }

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
    _notifyListeners(BlocEventType.event);
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
      _notifyListeners(BlocEventType.stateChange);
      _monitor.onBroadcast(this, _state, event: event);
    }
  }

  /// Called by blocs (subclasses) when an error occurs
  ///
  /// [isBusy] is cleared whenever an [error] is set
  /// Optional argument [event] is the name of event which is calling [setError]
  @protected
  void setError(error, {String? event}) {
    final e = error is StateError ? error : StateError(error.toString());

    if (_error == e) return;

    if (callerAsEventName) {
      event ??= _caller;
    }

    _notifyListeners(BlocEventType.error);
    _monitor.onError(this, e, event: event);
    _isBusy = false;
    _error = e;
    _stream?.add(null);
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

    _notifyListeners(BlocEventType.busy);
    _monitor.onBusy(this, event: event);
    _isBusy = true;
    _error = null;
    _stream?.add(null);
  }

  /// Broadcasts the same [state]
  ///
  /// This method can be used to refresh the UI, without setting a new state.
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
      _notifyListeners(BlocEventType.streamClosed);
      _monitor.onStreamDispose(this);
      await _stream!.close();
      _stream = null;
    }
  }

  String? get _caller {
    try {
      final first = StackTrace.current
          .toString()
          .split('#')
          .firstWhere((e) => e.contains(runtimeType.toString()));

      return first.substring(7).split(' ').first.split('.').last;
    } catch (e) {
      return null;
    }
  }
}
