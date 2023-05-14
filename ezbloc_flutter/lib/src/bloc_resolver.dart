import 'bloc.dart';
import 'logger.dart';
import 'type_and_arg.dart';

/// Takes [context] and [arg], returns a [Bloc]
///
/// Used by [BlocContainer] to instantiate blocs on demand
/// [arg] must implement equality
typedef ArgBlocBuilder<T> = T Function(dynamic arg);

/// Creates and caches bloc instances on the fly
///
/// Guarantees compile time safety (no more [Bloc] does not exist)
class BlocResolver<T extends Bloc> {
  BlocResolver(this.builder);

  static const _log = EzBlocLogger('BlocResolver');
  final ArgBlocBuilder<T> builder;

  /// Caches of all types are kept in the same static instance, so we can
  /// support [clearAllCaches]
  static final _cache = <TypeAndArg, Bloc>{};
  T? _toInject;

  /// Injects a bloc into this resolver
  ///
  /// This [BlocResolver] will always return this injected [bloc]. This can be
  /// used during testing, to inject mocks.
  void inject(T bloc) => _toInject = bloc;

  /// Removed the injected bloc, and restores normal bloc creation
  void removeInjection() => _toInject = null;

  /// Creates a new bloc, or retrieves a cached one
  ///
  /// if [useCache] is false then a new bloc is created everytime, otherwise
  /// returns a cached bloc if it exists
  T create({dynamic arg, bool useCache = true}) {
    if (_toInject != null) {
      return _toInject!;
    }

    if (!useCache) {
      return builder(arg);
    }

    final cacheKey = TypeAndArg(T, arg);

    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]! as T;
    }

    final bloc = builder(arg);

    _cache.addAll({cacheKey: bloc});

    final numCached = _cache.keys.where((e) => e.type == T).length;

    if (numCached > 2) {
      _log.warning('you have already cached $numCached ${T}s');
    }

    return bloc;
  }

  /// Redirects to [create]
  T call({dynamic arg, bool useCache = true}) =>
      create(arg: arg, useCache: useCache);

  /// Clears cached blocs only of type [T]
  void clearCache() => _cache.removeWhere(
        (key, value) => key.type == T,
      );

  /// Removes all cached blocs of all types
  static void clearAllCaches() => _cache.clear();
}
