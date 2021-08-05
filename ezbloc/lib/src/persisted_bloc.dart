import 'bloc_monitor.dart';
import 'bloc.dart';
import 'persistence_service.dart';

/// If bloc is not a singleton then tags must be provided to differentiate between different instances, otherwise different instances will overwrite each other
abstract class AutoPersistedBloc<S> extends PersistedBloc<S> {
  AutoPersistedBloc({
    S? initialState,
    Object tag = 0,
    BlocMonitor monitor = const BlocEventsPrinter(),
  }) : super(
          initialState: initialState,
          monitor: monitor,
          tag: tag,
          autoPersistence: true,
          recoverStateOnStart: true,
        );
}

abstract class PersistedBloc<S> extends Bloc<S> {
  final bool _autoPersistence;
  final bool _recoverStateOnStart;
  final Object tag;

  PersistedBloc({
    S? initialState,
    BlocMonitor monitor = const BlocEventsPrinter(),
    this.tag = 0,
    bool autoPersistence = false,
    bool recoverStateOnStart = false,
  })  : _autoPersistence = autoPersistence,
        _recoverStateOnStart = recoverStateOnStart,
        super(
          initialState:
              (autoPersistence && recoverStateOnStart) ? null : initialState,
          monitor: monitor,
        ) {
    if (_autoPersistence && _recoverStateOnStart) {
      _persistenceService.get<S>('value').then((got) {
        if (got == null) {
          if (initialState != null) {
            // if initialState is null then the bloc's is already set to busy
            super.setState(initialState, event: 'initializing');
          }
        } else {
          super.setState(got, event: 'recovered_state');
        }
      });
    }
  }

  PersistenceService get _persistenceService =>
      PersistenceService('$runtimeType.$tag');

  @override
  void setState(S update, {String? event}) {
    super.setState(update, event: event);

    if (state == update && _autoPersistence) {
      _persistenceService.set('value', state);
    }
  }
}
