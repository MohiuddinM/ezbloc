import 'package:ezbloc_flutter/src/logger.dart';
import 'package:flutter/widgets.dart';

import 'bloc.dart';
import 'type_and_arg.dart';

/// Takes [context] and [arg], returns a [Bloc]
///
/// Used by [BlocContainer] to instantiate blocs on demand
/// [arg] must implement equality
typedef BlocWithArgBuilder<T> = T Function(BuildContext? context, dynamic arg);


/// Builds, saves and provides [Bloc] independent of the build tree
///
/// Generally, applications would [add] all the blocs which would be required any where in the application.
/// And then [get] them whenever they are needed
final class BlocContainer {
  static const _log = EzBlocLogger('BlocContainer');
  static final Map<Type, BlocWithArgBuilder> _blocs = {};
  static final Map<TypeAndArg, Bloc> _cache = {};

  /// Adds a blocs to internal resolver
  ///
  /// Takes a [builder] to build a [Bloc] of type [T]
  static void add<T>(BlocWithArgBuilder<T> builder) {
    assert(T != dynamic, 'Type must be defined');
    assert(!_blocs.containsKey(T));
    _blocs[T] = builder;
  }

  /// Called whenever an application needs an already added [Bloc]
  ///
  /// The blocs which are once instantiated, can also be cached using the [useCache] option
  /// The bloc type [T] and the provided arg are both matched to return the cached bloc
  static R get<R extends Bloc>({
    BuildContext? context,
    arg,
    bool useCache = true,
  }) {
    if (!_blocs.containsKey(R)) {
      throw ArgumentError(
        '$R was not found in this container. Did you forgot to add() it',
      );
    }

    if (!useCache) {
      return _blocs[R]!(context, arg);
    }

    final cacheKey = TypeAndArg(R, arg);

    R cachedBloc;

    try {
      final entry = _cache.entries.firstWhere((e) => e.key == cacheKey);
      cachedBloc = entry.value as R;
    } catch (e) {
      cachedBloc = _blocs[R]!(context, arg);
      _cache[cacheKey] = cachedBloc;
    }

    final numCached = _cache.keys.where((e) => e.type == R).length;

    if (numCached > 2) {
      _log.warning('you have already cached $numCached ${R}s');
    }

    return cachedBloc;
  }

  /// Removes blocs from the cache
  ///
  /// If a [type] is provided then all blocs of that type are removed.
  /// If a [bloc] is provided then that specific bloc is removed
  static void removeFromCache({Type? type, Bloc? bloc}) {
    assert(type != null || bloc != null);

    if (type != null) {
      _cache.removeWhere((key, value) => key.type == type);
    } else if (bloc != null) {
      _cache.removeWhere((key, value) => value == bloc);
    }
  }

  /// Removes all blocs from the cache
  static void clearCache() {
    _cache.clear();
  }

  /// Clears blocs from the container
  ///
  /// If a [type] is provided then blocs registered with this type are cleared
  /// otherwise all values are cleared.
  /// This method also clears the cached blocs
  static void clear([Type? type]) {
    if (type == null) {
      _blocs.clear();
      _cache.clear();
    } else {
      _blocs.remove(type);
      _cache.removeWhere((key, value) => key.type == type);
    }
  }
}
