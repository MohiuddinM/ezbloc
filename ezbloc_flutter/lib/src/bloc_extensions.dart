import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:ezbloc/ezbloc.dart';

import 'bloc_builder.dart';

extension BlocExtensions<S> on Bloc<S> {
  Widget builder({
    Key? key,
    required DataBuilder<S> onState,
    WidgetBuilder? onBusy,
    ErrorBuilder? onError,
  }) {
    return BlocBuilder<S>(
      key: key,
      onState: onState,
      onError: onError,
      onBusy: onBusy,
      bloc: this,
    );
  }
}
