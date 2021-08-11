import 'bloc_monitor.dart';
import 'bloc.dart';
import 'persistence_service.dart';

/// If bloc is not a singleton then tags must be provided to differentiate between different instances, otherwise different instances will overwrite each other
abstract class AutoPersistedBloc<S> extends Bloc<S> {
  late PersistenceService _persistenceService;
  final Object tag;
  final Deserializer<S>? deserializer;

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

          super.setState(deserializer!(lastState), event: 'recovered_state');
        }
      }
    });
  }

  bool get _isPrimitive {
    if (S is num || S is String || S is DateTime || S is bool) {
      return true;
    }

    return false;
  }

  Map? _serialize(value) {
    try {
      return value.toJson();
    } on NoSuchMethodError {
      return null;
    }
  }

  @override
  void setState(S update, {String? event, bool shouldPersist = false}) {
    super.setState(update, event: event);

    if (shouldPersist) {
      final write = _isPrimitive ? update : _serialize(update);
      _persistenceService.set('value', write);
    }
  }
}
