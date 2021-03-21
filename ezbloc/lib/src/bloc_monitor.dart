import 'package:quick_log/quick_log.dart';

/// Callbacks which are sent by the blocs, can be used for debugging or side effects
///
/// [T] is the type of state value
/// [blocName] is the name of bloc, which sent the event
abstract class BlocMonitor<T> {
  /// Called when the bloc is being initialized
  ///
  /// Will be called even if initial state is null (isBusy = true)
  void onInit(String blocName, T? initState) {}

  /// Called when a builder starts listening to this bloc's broadcasts
  void onStreamListener(String blocName) {}

  /// Called when the internal stream of the bloc is being disposed (because it has no more listeners)
  void onStreamDispose(String blocName) {}

  /// Called when bloc calls the [setState] method
  void onEvent(String blocName, T? currentState, T? update, {String? event}) {}

  /// Called when the bloc broadcasts a new state to the connected builders
  void onBroadcast(String blocName, T? state, {String? event}) {}

  /// Called whenever the bloc is set to busy
  void onBusy(String blocName, {String? event}) {}

  /// Called whenever the bloc encounters an error
  void onError(String blocName, StateError error, {String? event}) {}
}

class BlocEventsPrinter implements BlocMonitor {
  static const _log = Logger('BlocMonitor', 'bloc_monitor');

  const BlocEventsPrinter();

  @override
  void onBroadcast(String blocName, state, {String? event}) {
    _log.info('Broadcast by $blocName:\n'
        '    state: $state\n'
        '    at event: $event');
  }

  @override
  void onBusy(String blocName, {String? event}) {
    _log.info('Busy by $blocName:\n'
        '    at event: $event');
  }

  @override
  void onError(String blocName, StateError error, {String? event}) {
    _log.info('Error by $blocName:\n'
        '    error: $error\n'
        '    at event: $event');
  }

  @override
  void onEvent(String blocName, currentState, update, {String? event}) {
    _log.fine('Event by $blocName:\n'
        '    current state: $currentState\n'
        '    updated state: $update\n'
        '    at event: $event');
  }

  @override
  void onInit(String blocName, initState) {
    _log.info('Init by $blocName:\n'
        '    initialState: $initState');
  }

  @override
  void onStreamDispose(String blocName) {
    _log.fine('Stream Dispose by $blocName');
  }

  @override
  void onStreamListener(String blocName) {
    _log.fine('New Listener on $blocName');
  }
}
