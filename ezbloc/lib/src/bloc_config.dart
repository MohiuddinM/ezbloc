class BlocConfig {
  /// Duration to wait before deactivating this [Bloc]
  ///
  /// If a new dependent comes in within this time, then the bloc will not be
  /// deactivated. This is really helpful during widget rebuilds when a widget
  /// disconnects and reconnects immediately. With this delay these rebuilds
  /// will not affect the performance of the bloc.
  static Duration deactivationDelay = const Duration(seconds: 2);
}