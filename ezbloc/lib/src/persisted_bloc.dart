import 'dart:async';
import 'dart:convert';

import 'bloc_monitor.dart';
import 'bloc.dart';
import 'persistence_service.dart';

/// If bloc is not a singleton then tags must be provided to differentiate between different instances, otherwise different instances will overwrite each other
abstract class AutoPersistedBloc<S> extends Bloc<S> {
  late final PersistenceService _persistenceService;
  final Object tag;
  final Deserializer<S>? deserializer;
  final Serializer<S>? serializer;
  final _initialization = Completer<void>();

  Future<void> get initialization => _initialization.future;

  AutoPersistedBloc({
    S? startState,
    BlocMonitor monitor = const BlocEventsPrinter(),
    this.tag = 0,
    this.deserializer,
    this.serializer,
  }) : super(
          initialState: null,
          monitor: monitor,
        ) {
    _persistenceService = PersistenceService('$runtimeType.$tag');

    _persistenceService.get('value').then((lastState) {
      if (lastState == null) {
        if (startState != null) {
          // if initialState is null then the bloc's is already set to busy
          super.setState(startState, event: 'initializing');
        }
      } else {
        if (lastState is S) {
          super.setState(lastState, event: 'recovered_state');
        } else {
          assert(deserializer != null);

          super.setState(deserializer!(jsonDecode(lastState)),
              event: 'recovered_state');
        }
      }

      _initialization.complete();
    });
  }

  bool _isPrimitive(S v) =>
      v is num || v is String || v is DateTime || v is bool;

  /// [serializer] must be provided if [state] is not of a primitive type
  dynamic _serialize(S value) {
    if (serializer == null) {
      throw ArgumentError.notNull('serializer');
    }

    final s = serializer!(value);
    if (s is num || s is String || s is DateTime || s is bool) {
      return s;
    }

    throw UnsupportedError('${s.runtimeType} is not writable');
  }

  @override
  void setState(S update, {String? event, bool shouldPersist = false}) {
    super.setState(update, event: event);

    if (shouldPersist) {
      final write = _isPrimitive(state) ? state : _serialize(state);
      _persistenceService.set('value', write);
    }
  }
}
