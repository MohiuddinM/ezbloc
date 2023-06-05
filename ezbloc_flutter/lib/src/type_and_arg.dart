import 'package:flutter/foundation.dart';

/// Acts as a key for bloc container cache
///
/// For cache to return cache value, both type and arg must match with a stored version
final class TypeAndArg {
  final Type type;
  final arg;

  TypeAndArg(this.type, this.arg);

  @override
  bool operator ==(Object other) {
    if (other is! TypeAndArg) {
      return false;
    }

    if (other.type == type && other.arg.runtimeType == arg.runtimeType) {
      if (other.arg is List) {
        return listEquals(other.arg, arg);
      }

      if (other.arg is Set) {
        return setEquals(other.arg, arg);
      }

      if (other.arg is Map) {
        return mapEquals(other.arg, arg);
      }

      return other.arg == arg;
    }

    return false;
  }

  @override
  int get hashCode => Object.hash(type, arg);
}
