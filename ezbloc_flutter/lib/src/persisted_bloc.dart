import 'dart:async';
import 'package:ezbloc/ezbloc.dart' hide Bloc;
import 'bloc.dart';

/// If bloc is not a singleton then tags must be provided to differentiate between different instances, otherwise different instances will overwrite each other
base class AutoPersistedBloc<S> extends Bloc<S> {
  final PersistenceService _persistenceService;
  final Object tag;
  final Deserializer<S>? deserializer;
  final Serializer<S>? serializer;
  final _initialization = Completer<void>();
  late final String persistenceKey = '$runtimeType.$tag';

  Future<void> get initialization => _initialization.future;

  AutoPersistedBloc(
    this._persistenceService, {
    S? startState,
    BlocMonitor monitor = const BlocEventsPrinter(),
    this.tag = 0,
    this.deserializer,
    this.serializer,
  }) : super(
          initialState: null,
          monitor: monitor,
        ) {
    assert(_stateIsPrimitive || deserializer != null);
    assert(_stateIsPrimitive || serializer != null);

    _persistenceService.get(persistenceKey).then((lastState) {
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

          super.setState(deserializer!(lastState), event: 'recovered_state');
        }
      }

      _initialization.complete();
    });
  }

  bool get _stateIsPrimitive {
    return S == int || S == double || S == String || S == DateTime || S == bool;
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

  /// Removes the [state] persisted in this bloc
  void removePersistedState() {
    _persistenceService.remove(persistenceKey);
  }

  @override
  void setState(S update, {String? event, bool shouldPersist = true}) {
    super.setState(update, event: event);

    if (shouldPersist) {
      final write = _isPrimitive(state) ? state : _serialize(state);
      _persistenceService.set(persistenceKey, write);
    }
  }
}
