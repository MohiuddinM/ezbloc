import 'package:quick_log/quick_log.dart';

import 'bloc.dart';

/// Callbacks which are sent by the blocs, can be used for debugging or side effects
///
/// [T] is the type of state value
/// [blocName] is the name of bloc, which sent the event
abstract class BlocMonitor<R extends Bloc<S>, S> {
  /// Called when the bloc is being initialized
  ///
  /// Will be called even if initial state is null (isBusy = true)
  void onInit(R bloc, S? initState) {}

  /// Called when a builder starts listening to this bloc's broadcasts
  void onStreamListener(R bloc) {}

  /// Called when the internal stream of the bloc is being disposed (because it has no more listeners)
  void onStreamDispose(R bloc) {}

  /// Called when bloc calls the [setState] method
  void onEvent(R bloc, S? currentState, S? update, {String? event}) {}

  /// Called when the bloc broadcasts a new state to the connected builders
  void onBroadcast(R bloc, S? state, {String? event}) {}

  /// Called whenever the bloc is set to busy
  void onBusy(R bloc, {String? event}) {}

  /// Called whenever the bloc encounters an error
  void onError(R bloc, StateError error, {String? event}) {}
}

class BlocEventsPrinter<R extends Bloc<S>, S> implements BlocMonitor<R, S> {
  static const _log = Logger('BlocMonitor', 'bloc_monitor');

  const BlocEventsPrinter();

  @override
  void onBroadcast(R bloc, state, {String? event}) {
    _log.info('Broadcast by ${bloc.runtimeType}:\n'
        '    state: $state\n'
        '    at event: $event');
  }

  @override
  void onBusy(R bloc, {String? event}) {
    _log.info('Busy by ${bloc.runtimeType}:\n'
        '    at event: $event');
  }

  @override
  void onError(R bloc, StateError error, {String? event}) {
    _log.info('Error by ${bloc.runtimeType}:\n'
        '    error: $error\n'
        '    at event: $event');
  }

  @override
  void onEvent(R bloc, currentState, update, {String? event}) {
    _log.fine('Event by ${bloc.runtimeType}:\n'
        '    current state: $currentState\n'
        '    updated state: $update\n'
        '    at event: $event');
  }

  @override
  void onInit(R bloc, initState) {
    _log.info('Init by ${bloc.runtimeType}:\n'
        '    initialState: $initState');
  }

  @override
  void onStreamDispose(R bloc) {
    _log.fine('Stream Dispose by ${bloc.runtimeType}');
  }

  @override
  void onStreamListener(R bloc) {
    _log.fine('New Listener on ${bloc.runtimeType}');
  }
}
