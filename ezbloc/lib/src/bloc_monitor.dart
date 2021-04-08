// ignore_for_file: top_level_function_literal_block
import 'package:quick_log/quick_log.dart';

import 'bloc.dart';

/// Callbacks which are sent by the blocs, can be used for debugging or side effects
///
/// [T] is the type of state value
/// [blocName] is the name of bloc, which sent the event
abstract class BlocMonitor<T> {
  /// Called when the bloc is being initialized
  ///
  /// Will be called even if initial state is null (isBusy = true)
  void Function(Bloc<T> bloc, T? initState)? onInit;

  /// Called when a builder starts listening to this bloc's broadcasts
  void Function(Bloc<T> bloc)? onStreamListener;

  /// Called when the internal stream of the bloc is being disposed (because it has no more listeners)
  void Function(Bloc<T> bloc)? onStreamDispose;

  /// Called when bloc calls the [setState] method
  void Function(Bloc<T> bloc, T? currentState, T? update, String? event)?
      onEvent;

  /// Called when the bloc broadcasts a new state to the connected builders
  void Function(Bloc<T> bloc, T? state, String? event)? onBroadcast;

  /// Called whenever the bloc is set to busy
  void Function(Bloc<T> bloc, String? event)? onBusy;

  /// Called whenever the bloc encounters an error
  void Function(Bloc<T> bloc, StateError error, String? event)? onError;
}

class BlocEventPrinter implements BlocMonitor {
  static const _log = Logger('BlocMonitor', 'bloc_monitor');

  @override
  var onBroadcast = (Bloc bloc, state, String? event) {
    //
    _log.info('Broadcast by ${bloc.runtimeType.toString()}:\n'
        '    state: $state\n'
        '    at event: $event');
  };

  @override
  var onBusy = (Bloc bloc, String? event) {
    _log.info('Busy by ${bloc.runtimeType.toString()}:\n'
        '    at event: $event');
  };

  @override
  var onError = (Bloc bloc, StateError error, String? event) {
    _log.info('Error by ${bloc.runtimeType.toString()}:\n'
        '    error: $error\n'
        '    at event: $event');
  };

  @override
  var onEvent = (Bloc bloc, currentState, update, String? event) {
    _log.fine('Event by ${bloc.runtimeType.toString()}:\n'
        '    current state: $currentState\n'
        '    updated state: $update\n'
        '    at event: $event');
  };

  @override
  var onInit = (Bloc bloc, initState) {
    _log.info('Init by ${bloc.runtimeType.toString()}:\n'
        '    initialState: $initState');
  };

  @override
  var onStreamDispose = (Bloc bloc) {
    _log.fine('Stream Dispose by ${bloc.runtimeType.toString()}');
  };

  @override
  var onStreamListener = (Bloc bloc) {
    _log.fine('New Listener on ${bloc.runtimeType.toString()}');
  };
}
