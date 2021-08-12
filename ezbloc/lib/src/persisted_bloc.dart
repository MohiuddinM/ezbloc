import 'dart:async';
import 'dart:convert';

import 'bloc_monitor.dart';
import 'bloc.dart';
import 'persistence_service.dart';

/// If bloc is not a singleton then tags must be provided to differentiate between different instances, otherwise different instances will overwrite each other
abstract class AutoPersistedBloc<S> extends Bloc<S> {
  late PersistenceService _persistenceService;
  final Object tag;
  final Deserializer<S>? deserializer;
  final initialization = Completer<void>();

  AutoPersistedBloc({
    S? startState,
    BlocMonitor monitor = const BlocEventsPrinter(),
    this.tag = 0,
    this.deserializer,
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

          super.setState(deserializer!(jsonEncode(lastState)),
              event: 'recovered_state');
        }
      }

      initialization.complete();
    });
  }

  bool _isPrimitive(S v) =>
      v is num || v is String || v is DateTime || v is bool;

  String _serialize(value) {
    try {
      return jsonEncode(value.toJson());
    } on NoSuchMethodError {
      throw '$S should be serializable type';
    }
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
