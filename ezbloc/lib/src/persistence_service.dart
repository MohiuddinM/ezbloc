import 'dart:async';
import 'dart:typed_data';

import 'package:hive/hive.dart';

typedef PersistenceServiceBuilder = PersistenceService Function(String name);
typedef Deserializer<T> = T Function(dynamic json);

abstract class PersistenceService {
  static PersistenceServiceBuilder _builder =
      (name) => HivePersistenceService(name);
  static Map<Type, Deserializer> deserializers = <Type, Deserializer>{};

  static void use(PersistenceServiceBuilder builder) {
    _builder = builder;
  }

  factory PersistenceService(String name) {
    return _builder(name);
  }

  Future<void> set(String key, value);

  Future<T?> get<T>(String key);

  Future<void> clear();

  void remove(String key);

  static void addDeserializer<T>(Deserializer<T> deserializer) {
    deserializers.putIfAbsent(T, () => deserializer);
  }
}

class HivePersistenceService implements PersistenceService {
  static late String databaseDirectory;
  static bool runningInTest = false;
  final _box = Completer<Box>();

  HivePersistenceService(name) {
    _initialize(name, databaseDirectory);
  }

  void _initialize(name, String directory) async {
    if (_box.isCompleted) return;
    try {
      Hive.init(directory);
    } on HiveError catch (e) {
      if (!e.message.contains('already')) {
        rethrow;
      }
    }
    final box = await Hive.openBox(
      name,
      bytes: runningInTest ? Uint8List(0) : null,
    );
    _box.complete(box);
  }

  @override
  Future<S?> get<S>(String key) async {
    final box = await _box.future;
    dynamic value = box.get(key);

    if (value != null && value is! S && (value is String || value is Map)) {
      if (PersistenceService.deserializers.containsKey(S)) {
        final deserializer = PersistenceService.deserializers[S];
        value = deserializer!(value);
      }
    }

    assert(
      value is S || value == null,
      'the type you are trying to get is not the same as what you saved',
    );
    return value as S?;
  }

  bool _isPrimitive(value) {
    if (value is num || value is String || value is DateTime || value is bool) {
      return true;
    }

    return false;
  }

  bool _isSerializable(value) {
    try {
      value.toJson();
    } on NoSuchMethodError {
      return false;
    }

    return PersistenceService.deserializers.containsKey(value.runtimeType);
  }

  @override
  void remove(String key) async {
    final box = await _box.future;
    await box.delete(key);
  }

  @override
  Future<void> set(String key, value) async {
    assert(value != null);

    final box = await _box.future;

    if (_isPrimitive(value)) {
      return box.put(key, value);
    } else if (_isSerializable(value)) {
      return box.put(key, value.toJson());
    } else {
      throw 'value should either be of primitive type or have a toJson() function';
    }
  }

  @override
  Future<void> clear() async {
    final box = await _box.future;
    await box.clear();
  }
}
