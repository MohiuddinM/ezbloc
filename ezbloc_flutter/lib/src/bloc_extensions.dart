import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'bloc.dart';
import 'bloc_builder.dart';

extension BlocExtensions<S> on Bloc<S> {
  Widget builder({
    Key? key,
    required DataBuilder<S> onState,
    WidgetBuilder? onBusy,
    ErrorBuilder? onError,
    ShouldSkip<S?>? shouldSkip,
  }) {
    return BlocBuilder<S>(
      key: key,
      onState: onState,
      onError: onError,
      onBusy: onBusy,
      shouldSkip: shouldSkip,
      bloc: this,
    );
  }
}
