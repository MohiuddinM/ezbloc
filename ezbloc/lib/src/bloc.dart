import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

import 'bloc_monitor.dart';
import 'logger.dart';

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
  static bool checkIfValueType = true;

  /// If set to true, the calling function's name will be used as event name,
  /// if event name is not already set.
  /// Library uses StackTrace [_caller] to find name of calling function, and
  /// this is not always possible.
  static bool callerAsEventName = false;

  final BlocMonitor _monitor;

  StateError? _error;
  bool _isBusy = true;
  BehaviorSubject<S?>? _stream;
  S? _state;

  /// [initialState] is the state which is set at initialization. if its null, the initial state is set to busy.
  Bloc({S? initialState, BlocMonitor monitor = const BlocEventsPrinter()})
      : _state = initialState,
        _monitor = monitor {
    _monitor.onInit(runtimeType.toString(), _state);
    if (initialState != null) assert(isValueType(initialState));
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
    _monitor.onStreamListener(runtimeType.toString());
    if (_stream == null) {
      _stream =
          _state == null ? BehaviorSubject<S>() : BehaviorSubject.seeded(state);

      _stream!.onCancel = () {
        if (_stream != null && !_stream!.hasListener) {
          _monitor.onStreamDispose(runtimeType.toString());
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
    assert(isValueType(update));
    if (!_kReleaseMode && callerAsEventName) {
      event ??= _caller;
    }

    final _stream = this._stream;
    _monitor.onEvent(runtimeType.toString(), _state, update, event: event);
    final next = nextState(_state, update);
    _isBusy = false;
    _error = null;

    if (next == null) {
      return;
    }

    _state = next;
    if (_stream != null) {
      _stream.add(_state);
      _monitor.onBroadcast(runtimeType.toString(), _state, event: event);
    }
  }

  /// Called by blocs (subclasses) when an error occurs
  ///
  /// [isBusy] is cleared whenever an [error] is set
  /// Optional argument [event] is the name of event which is calling [setError]
  @protected
  void setError(StateError error, {String? event}) {
    if (_error == error) return;
    if (!_kReleaseMode && callerAsEventName) {
      event ??= _caller;
    }

    _monitor.onError(runtimeType.toString(), error, event: event);
    _isBusy = false;
    _error = error;
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
    if (!_kReleaseMode && callerAsEventName) {
      event ??= _caller;
    }
    _monitor.onBusy(runtimeType.toString(), event: event);
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
  Future<void> dispose() async {
    if (_stream != null) {
      _monitor.onStreamDispose(runtimeType.toString());
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

/// Just a utility function to make sure if the state type implements equality (by default dart classes only support referential equality).
///
/// This library will not work if equality is not implemented. If you are manually overriding == and hashCode for your classes
/// instead of using [Equatable] or [Built], then you have to set [Bloc.checkIfValueType] to false, to avoid getting false errors.
bool isValueType(value) {
  return (!Bloc.checkIfValueType ||
      value is num ||
      value is String ||
      value is DateTime ||
      value is bool);
}
