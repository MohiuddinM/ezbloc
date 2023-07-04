import 'package:flutter/widgets.dart';

import 'bloc.dart';

/// [StatefulWidget] that is used to provide a [Bloc] to its [child] tree.
///
/// Internally uses an [InheritedWidget] to give O(1) access to the entire
/// subtree. This gets disposed automatically when there are no more dependents
class BlocProvider<T extends Bloc> extends StatefulWidget {
  final T bloc;
  final Widget child;

  const BlocProvider({Key? key, required this.bloc, required this.child})
      : super(key: key);

  static T? of<T extends Bloc>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_Provider<T>>()?.bloc;
  }

  @override
  State<BlocProvider> createState() => BlocProviderState<T>();
}

class BlocProviderState<T extends Bloc> extends State<BlocProvider> {
  @override
  Widget build(BuildContext context) {
    return _Provider<T>(
      bloc: widget.bloc as T,
      child: widget.child,
    );
  }
}

class _Provider<T extends Bloc> extends InheritedWidget {
  final T bloc;

  _Provider({
    Key? key,
    required this.bloc,
    required Widget child,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(_Provider old) => old.bloc != bloc;
}
