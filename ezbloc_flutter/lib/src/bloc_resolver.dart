import 'bloc.dart';
import 'logger.dart';
import 'type_and_arg.dart';

/// Takes [context] and [arg], returns a [Bloc]
///
/// Used by [BlocContainer] to instantiate blocs on demand
/// [arg] must implement equality
typedef ArgBlocBuilder<T> = T Function(dynamic arg);

class BlocResolver<T extends Bloc> {
  BlocResolver(this.builder);

  static const _log = EzBlocLogger('BlocCreator');
  final ArgBlocBuilder<T> builder;
  static final _cache = <TypeAndArg, Bloc>{};

  T create({dynamic arg, bool useCache = true}) {
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

  T call({dynamic arg, bool useCache = true}) =>
      create(arg: arg, useCache: useCache);

  void clearCache() => _cache.removeWhere(
        (key, value) => key.type == T.runtimeType,
      );

  static void clearAllCaches() => _cache.clear();
}
