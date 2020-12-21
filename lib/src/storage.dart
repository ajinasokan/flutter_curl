// Uses file system to keep key/value pairs
// Works in all platforms. No need to use shared preferences

import 'dart:io';
import 'package:path/path.dart' as path;

class Storage {
  final String dir;

  Storage({this.dir});

  Future<String> get(String key) async {
    var file = File(path.join(dir, key));
    if (await file.exists()) return file.readAsString();
    return null;
  }

  Future<void> set(String key, String value) async {
    var file = File(path.join(dir, key));
    await file.create(recursive: true);
    await file.writeAsString(value);
  }

  String getSync(String key) {
    var file = File(path.join(dir, key));
    if (file.existsSync()) return file.readAsStringSync();
    return null;
  }

  void setSync(String key, String value) {
    var file = File(path.join(dir, key));
    file.createSync(recursive: true);
    file.writeAsStringSync(value);
  }
}

abstract class DataStorage {
  static Storage _dataStorage;

  static Future<void> init() async {
    var dataDir;
    dataDir = path.join(".", "app_storage");
    _dataStorage = Storage(dir: dataDir);
  }

  static final getSync = _dataStorage.getSync;
  static final get = _dataStorage.get;
  static final setSync = _dataStorage.setSync;
  static final set = _dataStorage.set;
}

abstract class CacheStorage {
  static Storage _dataStorage;

  static Future<void> init() async {
    var cacheDir;
    cacheDir = path.join(".", "app_cache");
    _dataStorage = Storage(dir: cacheDir);
  }

  static final getSync = _dataStorage.getSync;
  static final get = _dataStorage.get;
  static final setSync = _dataStorage.setSync;
  static final set = _dataStorage.set;
}
