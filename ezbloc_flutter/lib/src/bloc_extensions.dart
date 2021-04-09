import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:ezbloc/ezbloc.dart';

import 'bloc_builder.dart';
import 'logger.dart';

extension BlocExtensions<S> on Bloc<S> {
  Widget builder({
    Key? key,
    required DataBuilder<S> onState,
    WidgetBuilder? onBusy,
    ErrorBuilder? onError,
  }) {
    const log = EzBlocLogger('BlocContainer');

    onBusy ??= (_) => LayoutBuilder(
          builder: (context, crts) {
            if (crts.maxHeight < 10 || crts.maxWidth < 10) {
              // Size is too small to draw a CircularProgressIndicator
              return const SizedBox();
            }

            return Center(
              child: SizedBox(
                width: min(60, crts.maxWidth),
                height: min(60, crts.maxHeight),
                child: CircularProgressIndicator.adaptive(),
              ),
            );
          },
        );

    onError ??= (context, error) {
      log.error(error.message);
      return onState(context, this.state);
    };

    return BlocBuilder<S>(
      key: key,
      onState: onState,
      onError: onError,
      onBusy: onBusy,
      bloc: this,
    );
  }
}
