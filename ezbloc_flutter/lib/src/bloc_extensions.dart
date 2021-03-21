import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:ezbloc/ezbloc.dart';

import 'bloc_builder.dart';

extension BlocExtensions<S> on Bloc<S> {
  Widget builder({
    Key? key,
    required DataBuilder<S> onUpdate,
    WidgetBuilder? onBusy,
    ErrorBuilder? onError,
  }) {
    onBusy ??= (_) => LayoutBuilder(
          builder: (context, crts) {
            if (crts.maxHeight < 10 || crts.maxWidth < 10) {
              // Size is too small to draw a CircularProgressIndicator
              return const SizedBox();
            }

            return Center(
              child: SizedBox(
                width: min(80, crts.maxWidth),
                height: min(80, crts.maxHeight),
                child: CircularProgressIndicator.adaptive(),
              ),
            );
          },
        );

    onError ??= (_, error) {
      return Container(
        color: Colors.red,
        child: Center(
          child: Text(error.message),
        ),
      );
    };

    return BlocBuilder<S>(
      key: key,
      onUpdate: onUpdate,
      onError: onError,
      onBusy: onBusy,
      bloc: this,
    );
  }
}
