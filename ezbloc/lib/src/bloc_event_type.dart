enum BlocEventType {
  /// [Bloc] is initialized
  init,

  /// [Bloc] encountered an error
  error,

  /// State is changed
  stateChange,

  /// [Bloc] is busy
  busy,

  /// [Bloc] has no listeners (stream is being closed)
  streamClosed,
}
