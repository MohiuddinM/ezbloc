import 'package:ezbloc/ezbloc.dart';
import 'package:flutter/widgets.dart';

import 'bloc_builder.dart';
import 'bloc_provider.dart';
import 'bloc_extensions.dart';

extension ContextX<S> on BuildContext {
  S? blocValue<R extends Bloc<S>>() {
    final bloc = BlocProvider.of<R>(this);
    return bloc.state;
  }

  Widget blocBuilder<R extends Bloc<S>>({
    Key? key,
    required DataBuilder<S> onState,
    WidgetBuilder? onBusy,
    ErrorBuilder? onError,
  }) {
    final bloc = BlocProvider.of<R>(this);
    return bloc.builder(
      key: key,
      onState: onState,
      onBusy: onBusy,
      onError: onError,
    );
  }
}
