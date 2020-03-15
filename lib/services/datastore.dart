import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nullpass/models/device.dart';
import 'package:nullpass/models/secret.dart';
import 'package:nullpass/services/logging.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

// This is the actual database filename that is saved in the docs directory.
final _dbName = "nullpass";
// Increment this version when you need to change the schema.
final _dbVersion = 1;

// a common representation of the database for all subtables to access (so a separate DB isn't created per object)
Database _db;
Future<Database> get _database async {
  if (_db != null) return _db;
  _db = await _initDatabase();
  return _db;
}

// open the database
_initDatabase() async {
  // The path_provider plugin gets the right directory for Android or iOS.
  Directory documentsDirectory = await getApplicationDocumentsDirectory();
  String path = join(documentsDirectory.path, _dbName);

  // Open the database. Can also add an onUpdate callback parameter.
  return await openDatabase(path, version: _dbVersion, onCreate: _onCreate);
}

// SQL string to create the database
Future _onCreate(Database db, int version) async {
  // TODO: move password to secure storage - remove '$columnPassword TEXT,'
  // $columnPassword TEXT,
  await db.execute("${_NullPassSecretDetailsDB.createTable}");
  await db.execute("${_NullPassDevicesDB.createTable}");
}

class NullPassDB {
  /* DB singleton */
  NullPassDB._privateConstructor();
  static final NullPassDB instance = NullPassDB._privateConstructor();

  /* Secrets */
  static final _messageSecureStorage = new FlutterSecureStorage();
  static final _NullPassSecretDetailsDB _secretDetailsDB =
      _NullPassSecretDetailsDB.instance;

  Future<bool> insertSecret(Secret s) async {
    try {
      await _secretDetailsDB.insert(s);
    } catch (e) {
      Log.debug(
          "an error occured while trying to add the secret to the details db: $e");
      return false;
    }

    try {
      await _messageSecureStorage.write(key: s.uuid, value: s.message);
    } catch (e) {
      Log.debug(
          "an error occured while trying to add the secret to the secure storage: $e");
      return false;
    }

    return true;
  }

  Future<void> bulkInsertSecrets(List<Secret> ls) async {
    try {
      await _secretDetailsDB.insertBulkSecrets(ls);
    } catch (e) {
      Log.debug(
          "an error occured while trying to bulk insert the secrets into the details db: $e");
    }

    try {
      ls.forEach((s) async =>
          await _messageSecureStorage.write(key: s.uuid, value: s.message));
    } catch (e) {
      Log.debug(
          "an error occured while trying to bulk insert the secrets into the secure storage: $e");
    }

    // throw new Exception("TBD - not yet implemented");
  }

  Future<Secret> getSecretByID(String uuid) async {
    Secret result;
    try {
      result = await _secretDetailsDB.getSecretByID(uuid);
    } catch (e) {
      Log.debug(
          "an error occured while trying to fetch the secret from the details db: $e");
    }

    try {
      result.message = await _messageSecureStorage.read(key: uuid);
      return result;
    } catch (e) {
      Log.debug(
          "an error occured while trying to fetch the secret from the secure storage: $e");
    }

    return null;
  }

  Future<List<Secret>> getAllSecrets() async {
    List<Secret> secretList;
    try {
      secretList = await _secretDetailsDB.getAllSecrets();
    } catch (e) {
      Log.debug(
          "an error occured while trying to fetch the secrets from the details db: $e");
    }

    if (secretList != null) {
      try {
        Map<String, String> messageMap = await _messageSecureStorage.readAll();
        secretList.forEach((s) => s.message = messageMap[s.uuid]);
        // secretList.forEach((s) async =>
        //     (s.message = await _messageSecureStorage.read(key: s.uuid)));
        return secretList;
      } catch (e) {
        Log.debug(
            "an error occured while trying to fetch the secrets from the secure storage: $e");
      }
    }
    return null;
  }

  Future<bool> updateSecret(Secret s) async {
    try {
      await _messageSecureStorage.write(key: s.uuid, value: s.message);
    } catch (e) {
      Log.debug(
          "an error occured while trying to update the secret in the secure storage: $e");
      return false;
    }

    try {
      await _secretDetailsDB.update(s);
    } catch (e) {
      Log.debug(
          "an error occured while trying to update the secret in the details db: $e");
      return false;
    }

    return true;
  }

  Future<bool> deleteSecret(String uuid) async {
    try {
      await _messageSecureStorage.delete(key: uuid);
    } catch (e) {
      Log.debug(
          "an error occured while trying to delete the secret from the secure storage: $e");
      return false;
    }

    try {
      await _secretDetailsDB.delete(uuid);
    } catch (e) {
      Log.debug(
          "an error occured while trying to delete the secret from the details db: $e");
      return false;
    }
    return true;
  }

  Future<bool> deleteAllSecrets() async {
    try {
      await _messageSecureStorage.deleteAll();
    } catch (e) {
      Log.debug(
          "an error occured while trying to delete all secrets from the secure storage: $e");
      return false;
    }

    try {
      await _secretDetailsDB.deleteAll();
    } catch (e) {
      Log.debug(
          "an error occured while trying to add the secret to the details db: $e");
      return false;
    }

    return true;
  }

  Future<List<Secret>> findSecret(String keyword) async {
    List<Secret> sList;

    try {
      sList = await _secretDetailsDB.find(keyword);
    } catch (e) {
      Log.debug(
          "an error occured while trying to add the secret to the details db: $e");
      return null;
    }

    try {
      sList.forEach((s) async {
        var message = await _messageSecureStorage.read(key: s.uuid);
        s.message = message;
      });
    } catch (e) {
      Log.debug(
          "an error occured while trying to delete all secrets from the secure storage: $e");
      return null;
    }

    return sList;
  }

  /* Devices */
  static final _NullPassDevicesDB _deviceDB = _NullPassDevicesDB.instance;

  Future<bool> insertDevice(Device d) async {
    try {
      await _deviceDB.insert(d);
      return true;
    } catch (e) {
      Log.debug(
          "an error occured while trying to add the device sync record to the db: $e");
      return false;
    }
  }

  Future<void> bulkInsertDevices(List<Device> ld) async {
    try {
      await _deviceDB.bulkInsert(ld);
    } catch (e) {
      Log.debug(
          "an error occured while trying to bulk add device sync records to the db: $e");
    }
  }

  Future<Device> getDeviceByID(String id) async {
    try {
      return await _deviceDB.getDeviceByID(id);
    } catch (e) {
      Log.debug(
          "an error occured while trying to update the device sync record to the db: $e");
      return null;
    }
  }

  Future<Device> getDeviceBySyncID(String id) async {
    try {
      return await _deviceDB.getDeviceBySyncID(id);
    } catch (e) {
      Log.debug(
          "an error occured while trying to get the device by it's sync connection id: $e");
      return null;
    }
  }

  Future<List<Device>> getAllDevices() async {
    try {
      return await _deviceDB.getAllDevices();
    } catch (e) {
      Log.debug(
          "an error occured while trying to update the device sync record to the db: $e");
      return <Device>[];
    }
  }

  Future<bool> updateDevice(Device d) async {
    try {
      await _deviceDB.update(d);
      return true;
    } catch (e) {
      Log.debug(
          "an error occured while trying to update the device sync record to the db: $e");
      return false;
    }
  }

  Future<bool> deleteDevice(String id) async {
    try {
      await _deviceDB.delete(id);
      return true;
    } catch (e) {
      Log.debug(
          "an error occured while trying to add the device sync record to the db: $e");
      return false;
    }
  }

  Future<bool> deleteAllDevices() async {
    try {
      await _deviceDB.deleteAll();
      return true;
    } catch (e) {
      Log.debug(
          "an error occured while trying to add the device sync record to the db: $e");
      return false;
    }
  }
}

/* Secrets */
class _NullPassSecretDetailsDB {
  _NullPassSecretDetailsDB._privateConstructor();
  static final _NullPassSecretDetailsDB instance =
      _NullPassSecretDetailsDB._privateConstructor();

  static final createTable = '''
              CREATE TABLE $secretTableName (
                $columnSecretId TEXT PRIMARY KEY,
                $columnSecretNickname TEXT NOT NULL,
                $columnSecretUsername TEXT,
                $columnSecretType TEXT NOT NULL,
                $columnSecretWebsite TEXT,
                $columnSecretAppName TEXT,
                $columnSecretGenericEndpoint TEXT,
                $columnSecretThumbnailURI TEXT NOT NULL,
                $columnSecretNotes TEXT,
                $columnSecretTags TEXT,
                $columnSecretVaults TEXT,
                $columnSecretCreated TEXT,
                $columnSecretLastModified TEXT,
                $columnSecretSortKey TEXT NOT NULL
              )
              ''';

  static final List<String> _secretTableColumns = [
    columnSecretId,
    columnSecretNickname,
    columnSecretUsername,
    columnSecretType,
    columnSecretWebsite,
    columnSecretAppName,
    columnSecretGenericEndpoint,
    columnSecretThumbnailURI,
    columnSecretNotes,
    columnSecretTags,
    columnSecretVaults,
    columnSecretCreated,
    columnSecretLastModified,
    columnSecretSortKey,
  ];

  /* Database helper methods */

  Future<int> insert(Secret s) async {
    Database db = await _database;
    s.created = DateTime.now().toUtc();
    s.lastModified = DateTime.now().toUtc();
    Log.debug(s.toMap());
    int id = await db.insert(secretTableName, s.toMap());
    return id;
  }

  Future<void> insertBulk(List<dynamic> ls) async {
    Database db = await _database;
    var batch = db.batch();
    ls.forEach((s) => batch.insert(secretTableName, s));
    var results = await batch.commit(continueOnError: true);
    Log.debug(results);
    return;
  }

  Future<void> insertBulkMaps(List<Map<String, dynamic>> ls) async {
    Database db = await _database;
    var batch = db.batch();
    ls.forEach((s) => batch.insert(secretTableName, s));
    await batch.commit(noResult: true, continueOnError: true);
    return;
  }

  Future<void> insertBulkSecrets(List<Secret> ls) async {
    Database db = await _database;
    var batch = db.batch();
    ls.forEach((s) => batch.insert(secretTableName, s.toMap()));
    await batch.commit(noResult: true, continueOnError: true);
    return;
  }

  Future<Secret> getSecretByID(String uuid) async {
    Database db = await _database;
    List<Map> maps = await db.query(secretTableName,
        columns: _secretTableColumns,
        where: '$columnSecretId = ?',
        whereArgs: [uuid]);
    if (maps.length > 0) {
      Secret s = Secret.fromMap(maps.first);
      return s;
    }
    return null;
  }

  Future<List<Secret>> getAllSecrets() async {
    Database db = await _database;
    List<Map> maps = await db.query(secretTableName,
        columns: _secretTableColumns, orderBy: columnSecretSortKey);
    if (maps.length > 0) {
      List<Secret> secretList = <Secret>[];
      maps.forEach((m) => secretList.add(Secret.fromMap(m)));
      return secretList;
    }
    return null;
  }

  Future<int> update(Secret s) async {
    Database db = await _database;
    s.lastModified = DateTime.now().toUtc();

    int id = await db.update(secretTableName, s.toMap(),
        where: '$columnSecretId = ?', whereArgs: [s.uuid]);
    return id;
  }

  Future<int> delete(String uuid) async {
    Database db = await _database;
    int id = await db.delete(secretTableName,
        where: '$columnSecretId = ?', whereArgs: [uuid]);
    return id;
  }

  Future<int> deleteAll() async {
    Database db = await _database;
    int id = await db.delete(secretTableName);
    return id;
  }

  Future<List<Secret>> find(String keyword) async {
    Database db = await _database;
    List<Map<String, dynamic>> query = await db.query(secretTableName,
        where:
            '$columnSecretNickname LIKE ? OR $columnSecretWebsite LIKE ? OR $columnSecretUsername LIKE ?  OR $columnSecretNotes LIKE ?',
        whereArgs: ['%$keyword%', '%$keyword%', '%$keyword%', '%$keyword%']);
    List<Secret> secretList = <Secret>[];
    //     query != null ? query.map((i) => Secret.fromJson(i)).toList() : null;
    query.forEach((m) => secretList.add(Secret.fromMap(m)));
    return secretList;
  }
}

/* Devices */
class _NullPassDevicesDB {
  _NullPassDevicesDB._privateConstructor();
  static final _NullPassDevicesDB instance =
      _NullPassDevicesDB._privateConstructor();

  // This is the actual database filename that is saved in the docs directory.
  // static final _dbName = "nullpass_devices";
  // Increment this version when you need to change the schema.
  static final createTable = '''
              CREATE TABLE $deviceTableName (
                $columnDeviceId TEXT PRIMARY KEY,
                $columnDeviceSyncId TEXT NOT NULL,
                $columnDeviceNickname TEXT,
                $columnDeviceEncryptionKey TEXT NOT NULL,
                $columnDeviceType TEXT,
                $columnDeviceNotes TEXT,
                $columnDeviceCreated TEXT,
                $columnDeviceModified TEXT,
                $columnDeviceSortKey TEXT NOT NULL
              )
              ''';

  static final List<String> _devicesTableColumns = [
    columnDeviceId,
    columnDeviceSyncId,
    columnDeviceNickname,
    columnDeviceEncryptionKey,
    columnDeviceType,
    columnDeviceNotes,
    columnDeviceCreated,
    columnDeviceModified,
    columnDeviceSortKey,
  ];

  /* Database helper methods */

  Future<int> insert(Device d) async {
    Database db = await _database;
    d.created = DateTime.now().toUtc();
    d.lastModified = DateTime.now().toUtc();
    Log.debug(d.toMap());
    int id;
    try {
      id = await db.insert(deviceTableName, d.toMap());
    } catch (e) {
      Log.debug(e);
      throw e;
    }
    return id;
  }

  Future<void> bulkInsert(List<dynamic> ld) async {
    Database db = await _database;
    var batch = db.batch();
    ld.forEach((d) => batch.insert(deviceTableName, d));
    var results = await batch.commit(continueOnError: true);
    Log.debug(results);
    return;
  }

  Future<void> bulkInsertMaps(List<Map<String, dynamic>> ld) async {
    Database db = await _database;
    var batch = db.batch();
    ld.forEach((d) => batch.insert(deviceTableName, d));
    await batch.commit(noResult: true, continueOnError: true);
    return;
  }

  Future<void> bulkInsertDevices(List<Device> ld) async {
    Database db = await _database;
    var batch = db.batch();
    ld.forEach((d) => batch.insert(deviceTableName, d.toMap()));
    await batch.commit(noResult: true, continueOnError: true);
    return;
  }

  Future<Device> getDeviceByID(String uid) async {
    Database db = await _database;
    List<Map> maps = await db.query(deviceTableName,
        columns: _devicesTableColumns,
        where: '$columnDeviceId = ?',
        whereArgs: [uid]);
    if (maps.length > 0) {
      var d = Device.fromMap(maps.first);
      return d;
    }
    return null;
  }

  Future<Device> getDeviceBySyncID(String uid) async {
    Database db = await _database;
    List<Map> maps = await db.query(deviceTableName,
        columns: _devicesTableColumns,
        where: '$columnDeviceSyncId = ?',
        whereArgs: [uid]);
    if (maps.length > 0) {
      var d = Device.fromMap(maps.first);
      return d;
    }
    return null;
  }

  Future<List<Device>> getAllDevices() async {
    Database db = await _database;
    List<Map> maps = await db.query(deviceTableName,
        columns: _devicesTableColumns, orderBy: columnDeviceSortKey);
    if (maps.length > 0) {
      List<Device> deviceList = <Device>[];
      maps.forEach((m) => deviceList.add(Device.fromMap(m)));
      return deviceList;
    }
    return null;
  }

  Future<int> update(Device d) async {
    Database db = await _database;
    d.lastModified = DateTime.now().toUtc();

    int id = await db.update(deviceTableName, d.toMap(),
        where: '$columnDeviceId = ?', whereArgs: [d.id]);
    return id;
  }

  Future<int> delete(String id) async {
    Database db = await _database;
    int retId = await db
        .delete(deviceTableName, where: '$columnDeviceId = ?', whereArgs: [id]);
    return retId;
  }

  Future<int> deleteAll() async {
    Database db = await _database;
    int id = await db.delete(deviceTableName);
    return id;
  }
}
