import 'dart:async';
import 'dart:typed_data';

import 'package:hive/hive.dart';

typedef PersistenceServiceBuilder = PersistenceService Function(String name);
typedef Deserializer<T> = T Function(dynamic json);

abstract class PersistenceService {
  static PersistenceServiceBuilder _builder =
      (name) => HivePersistenceService(name);

  static void use(PersistenceServiceBuilder builder) {
    _builder = builder;
  }

  factory PersistenceService(String name) {
    return _builder(name);
  }

  Future<void> set(String key, value);

  Future get(String key);

  Future<void> clear();

  void remove(String key);
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
  Future get(String key) async {
    final box = await _box.future;
    return box.get(key);
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

    return box.put(key, value);
  }

  @override
  Future<void> clear() async {
    final box = await _box.future;
    await box.clear();
  }
}
