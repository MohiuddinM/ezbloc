import 'dart:async';
import 'dart:typed_data';

import 'package:hive/hive.dart';

typedef Deserializer<T> = T Function(dynamic o);
typedef Serializer<T> = dynamic Function(T o);

abstract class PersistenceService {
  Future<void> set(String key, value);

  Future get(String key);

  Future<void> clear();

  void remove(String key);
}

final class HivePersistenceService implements PersistenceService {
  final String databaseDirectory;
  final bool inMemory;
  final _box = Completer<Box>();

  HivePersistenceService(
    name, {
    this.databaseDirectory = '.',
    this.inMemory = false,
  }) {
    _initialize(name);
  }

  void _initialize(name) async {
    if (_box.isCompleted) return;

    Hive.init(databaseDirectory);

    final box = await Hive.openBox(
      name,
      bytes: inMemory ? Uint8List(0) : null,
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

final class InMemoryPersistenceService implements PersistenceService {
  const InMemoryPersistenceService({this.values = const {}});

  final Map<String, dynamic> values;

  @override
  Future<void> clear() async {
    values.clear();
  }

  @override
  Future get(String key) async {
    return values.containsKey(key) ? values[key] : null;
  }

  @override
  void remove(String key) {
    values.remove(key);
  }

  @override
  Future<void> set(String key, value) async {
    values.addAll({key: value});
  }
}
