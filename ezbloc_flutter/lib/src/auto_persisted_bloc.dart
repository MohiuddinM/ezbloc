import 'package:ezbloc/ezbloc.dart' as s;

base class AutoPersistedBloc extends s.AutoPersistedBloc {
  AutoPersistedBloc(
    super.persistenceService, {
    super.startState,
    super.monitor = const s.BlocEventsPrinter(),
    super.tag = 0,
    super.deserializer,
    super.serializer,
  });
}
