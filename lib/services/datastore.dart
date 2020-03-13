import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nullpass/models/secret.dart';
import 'package:nullpass/services/logging.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

// This is the actual database filename that is saved in the docs directory.
final _databaseName = "nullpass";
// Increment this version when you need to change the schema.
final _databaseVersion = 1;

class NullPassDB {
  // Make this a singleton class.
  NullPassDB._privateConstructor();
  static final NullPassDB instance = NullPassDB._privateConstructor();

  static final _messageSecureStorage = new FlutterSecureStorage();
  // Only allow a single open connection to the database.
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
}

class _NullPassSecretDetailsDB {
  _NullPassSecretDetailsDB._privateConstructor();
  static final _NullPassSecretDetailsDB instance =
      _NullPassSecretDetailsDB._privateConstructor();

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

  static Database _database;
  Future<Database> get database async {
    if (_database != null) return _database;
    _database = await _initDatabase();
    return _database;
  }

  // open the database
  _initDatabase() async {
    // The path_provider plugin gets the right directory for Android or iOS.
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);

    // Open the database. Can also add an onUpdate callback parameter.
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  // SQL string to create the database
  Future _onCreate(Database db, int version) async {
    // TODO: move password to secure storage - remove '$columnPassword TEXT,'
    // $columnPassword TEXT,
    await db.execute('''
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
              ''');
  }

  /* Database helper methods */

  Future<int> insert(Secret s) async {
    Database db = await database;
    s.created = DateTime.now().toUtc();
    s.lastModified = DateTime.now().toUtc();
    Log.debug(s.toMap());
    int id = await db.insert(secretTableName, s.toMap());
    return id;
  }

  Future<void> insertBulk(List<dynamic> ls) async {
    Database db = await database;
    var batch = db.batch();
    ls.forEach((s) => batch.insert(secretTableName, s));
    var results = await batch.commit(continueOnError: true);
    Log.debug(results);
    return;
  }

  Future<void> insertBulkMaps(List<Map<String, dynamic>> ls) async {
    Database db = await database;
    var batch = db.batch();
    ls.forEach((s) => batch.insert(secretTableName, s));
    await batch.commit(noResult: true, continueOnError: true);
    return;
  }

  Future<void> insertBulkSecrets(List<Secret> ls) async {
    Database db = await database;
    var batch = db.batch();
    ls.forEach((s) => batch.insert(secretTableName, s.toMap()));
    await batch.commit(noResult: true, continueOnError: true);
    return;
  }

  Future<Secret> getSecretByID(String uuid) async {
    Database db = await database;
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
    Database db = await database;
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
    Database db = await database;
    s.lastModified = DateTime.now().toUtc();

    int id = await db.update(secretTableName, s.toMap(),
        where: '$columnSecretId = ?', whereArgs: [s.uuid]);
    return id;
  }

  Future<int> delete(String uuid) async {
    Database db = await database;
    int id = await db.delete(secretTableName,
        where: '$columnSecretId = ?', whereArgs: [uuid]);
    return id;
  }

  Future<int> deleteAll() async {
    Database db = await database;
    int id = await db.delete(secretTableName);
    return id;
  }

  Future<List<Secret>> find(String keyword) async {
    Database db = await database;
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
