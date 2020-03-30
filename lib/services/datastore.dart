import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nullpass/models/device.dart';
import 'package:nullpass/models/deviceSync.dart';
import 'package:nullpass/models/secret.dart';
import 'package:nullpass/models/vault.dart';
import 'package:nullpass/services/logging.dart';
import 'package:openpgp/key_pair.dart';
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
  await db.execute("${_NullPassVaultsDB.createTable}");
}

class NullPassDB {
  /* DB singleton */
  NullPassDB._privateConstructor();
  static final NullPassDB instance = NullPassDB._privateConstructor();

  /* Secure Storage for PGP and Secret / Password Storage */
  static final _nullpassSecureStorage = new FlutterSecureStorage();

  /* PGP */
  Future<bool> insertEncryptionKeyPair(KeyPair kp) async {
    try {
      if (kp != null &&
          kp.publicKey != null &&
          kp.privateKey != null &&
          kp.publicKey.isNotEmpty &&
          kp.privateKey.isNotEmpty)
        await _nullpassSecureStorage.write(
            key: "encPubKey", value: kp.publicKey);
      await _nullpassSecureStorage.write(
          key: "encSecKey", value: kp.privateKey);
      return true;
    } catch (e) {
      Log.debug(
          "there was an error trying to store the encryption key pair: ${e.toString()}");
    }
    return false;
  }

  Future<KeyPair> getEncryptionKeyPair() async {
    try {
      String pubKey = await _nullpassSecureStorage.read(key: "encPubKey");
      String privKey = await _nullpassSecureStorage.read(key: "encSecKey");
      if (pubKey != null &&
          privKey != null &&
          pubKey.isNotEmpty &&
          privKey.isNotEmpty)
        return KeyPair(publicKey: pubKey, privateKey: privKey);
    } catch (e) {
      Log.debug(
          "there was an error trying to fetch the encryption key pair: ${e.toString()}");
    }
    return null;
  }

  Future<String> getEncryptionPublicKey() async {
    try {
      return await _nullpassSecureStorage.read(key: "encPubKey");
    } catch (e) {
      Log.debug(
          "there was an error trying to fetch the encryption key pair: ${e.toString()}");
      return null;
    }
  }

  Future<String> getEncryptionPrivateKey() async {
    try {
      return await _nullpassSecureStorage.read(key: "encSecKey");
    } catch (e) {
      Log.debug(
          "there was an error trying to fetch the encryption key pair: ${e.toString()}");
      return null;
    }
  }

  /* Secrets */
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
      await _nullpassSecureStorage.write(key: s.uuid, value: s.message);
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
          await _nullpassSecureStorage.write(key: s.uuid, value: s.message));
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
      result.message = await _nullpassSecureStorage.read(key: uuid);
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
        Map<String, String> messageMap = await _nullpassSecureStorage.readAll();
        secretList.forEach((s) => s.message = messageMap[s.uuid]);
        // secretList.forEach((s) async =>
        //     (s.message = await _nullpassSecureStorage.read(key: s.uuid)));
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
      await _nullpassSecureStorage.write(key: s.uuid, value: s.message);
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
      await _nullpassSecureStorage.delete(key: uuid);
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
      await _nullpassSecureStorage.deleteAll();
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
        var message = await _nullpassSecureStorage.read(key: s.uuid);
        s.message = message;
      });
    } catch (e) {
      Log.debug(
          "an error occured while trying to delete all secrets from the secure storage: $e");
      return null;
    }

    return sList;
  }

  /* Vaults */
  static final _NullPassVaultsDB _vaultDB = _NullPassVaultsDB.instance;

  Future<Vault> createDefaultVault() async {
    try {
      var v = await _vaultDB.getDefaultVault();
      if (v != null) return v;

      var newV = Vault(
          nickname: "Personal",
          source: VaultSource.Internal,
          sourceId: Vault.InternalSourceID,
          isDefault: true);
      if (await insertVault(newV)) {
        return newV;
      }
    } catch (e) {
      Log.debug(
          "an error occured while trying to create the default vault record to the db: $e");
    }
    return null;
  }

  Future<bool> insertVault(Vault v) async {
    try {
      await _vaultDB.insert(v);
      return true;
    } catch (e) {
      Log.debug(
          "an error occured while trying to add the vault record to the db: $e");
      return false;
    }
  }

  Future<void> bulkInsertVaults(List<Vault> lv) async {
    try {
      await _vaultDB.bulkInsert(lv);
    } catch (e) {
      Log.debug(
          "an error occured while trying to add the list of vault records to the db: $e");
    }
  }

  Future<Vault> getVaultByID(String uid) async {
    try {
      var v = await _vaultDB.getVaultByID(uid);
      return v;
    } catch (e) {
      Log.debug(
          "an error occured while trying to get the vault record from the db: $e");
      return null;
    }
  }

  Future<Vault> getDefaultVault() async {
    try {
      var v = await _vaultDB.getDefaultVault();
      return v;
    } catch (e) {
      Log.debug(
          "an error occured while trying to get the default vault from the db: $e");
      return null;
    }
  }

  Future<List<Vault>> getAllVaults() async {
    try {
      var lv = await _vaultDB.getAllVaults();
      return lv;
    } catch (e) {
      Log.debug(
          "an error occured while trying to get all of the vault records from the db: $e");
      return <Vault>[];
    }
  }

  Future<List<Vault>> getAllInternallyManagedVaults() async {
    try {
      var lv = await _vaultDB.getAllInternalVaults();
      return lv;
    } catch (e) {
      Log.debug(
          "an error occured while trying to get all of the vault records from the db: $e");
      return <Vault>[];
    }
  }

  Future<List<Vault>> getAllExternallyManagedVaults() async {
    try {
      var lv = await _vaultDB.getAllExternalVaults();
      return lv;
    } catch (e) {
      Log.debug(
          "an error occured while trying to get all of the vault records from the db: $e");
      return <Vault>[];
    }
  }

  Future<bool> updateVault(Vault v) async {
    try {
      await _vaultDB.update(v);
      return true;
    } catch (e) {
      Log.debug(
          "an error occured while trying to update the vault record in the db: $e");
      return false;
    }
  }

  Future<bool> deleteVault(String uid) async {
    try {
      await _vaultDB.delete(uid);
      return true;
    } catch (e) {
      Log.debug(
          "an error occured while trying to delete the vault record from the db: $e");
      return false;
    }
  }

  Future<bool> deleteAllVaults() async {
    try {
      await _vaultDB.deleteAll();
      return true;
    } catch (e) {
      Log.debug(
          "an error occured while trying to delete all of the vault records from the db: $e");
      return false;
    }
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

  /* Device Sync */
  static final _NullPassSyncDevicesDB _syncDeviceDB =
      _NullPassSyncDevicesDB.instance;

  Future<bool> insertSync(DeviceSync d) async {
    try {
      await _syncDeviceDB.insert(d);
      return true;
    } catch (e) {
      Log.debug(
          "an error occured while trying to add the device sync record to the db: $e");
      return false;
    }
  }

  Future<void> bulkInsertSync(List<DeviceSync> ld) async {
    try {
      await _syncDeviceDB.bulkInsert(ld);
    } catch (e) {
      Log.debug(
          "an error occured while trying to bulk add device sync records to the db: $e");
    }
  }

  Future<DeviceSync> getSyncByID(String id) async {
    try {
      return await _syncDeviceDB.getSyncByID(id);
    } catch (e) {
      Log.debug(
          "an error occured while trying to update the device sync record to the db: $e");
      return null;
    }
  }

  Future<List<DeviceSync>> getAllSyncs() async {
    try {
      return await _syncDeviceDB.getAllSyncs();
    } catch (e) {
      Log.debug(
          "an error occured while trying to update the device sync record to the db: $e");
      return <DeviceSync>[];
    }
  }

  Future<List<DeviceSync>> getAllVaultSyncsFromDevice(String vaultId) async {
    try {
      return await _syncDeviceDB.getAllVaultSyncsFromDevice(vaultId);
    } catch (e) {
      Log.debug(
          "an error occured while trying to update the device sync record to the db: $e");
      return <DeviceSync>[];
    }
  }

  Future<bool> updateSync(DeviceSync d) async {
    try {
      await _syncDeviceDB.update(d);
      return true;
    } catch (e) {
      Log.debug(
          "an error occured while trying to update the device sync record to the db: $e");
      return false;
    }
  }

  Future<bool> deleteSync(String id) async {
    try {
      await _syncDeviceDB.delete(id);
      return true;
    } catch (e) {
      Log.debug(
          "an error occured while trying to add the device sync record to the db: $e");
      return false;
    }
  }

  Future<bool> deleteAllSyncs() async {
    try {
      await _syncDeviceDB.deleteAll();
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

/* Vaults */
class _NullPassVaultsDB {
  _NullPassVaultsDB._privateConstructor();
  static final _NullPassVaultsDB instance =
      _NullPassVaultsDB._privateConstructor();

  static final createTable = '''
              CREATE TABLE $vaultTableName (
                $columnVaultId TEXT PRIMARY KEY,
                $columnVaultNickname TEXT NOT NULL,
                $columnVaultSource TEXT NOT NULL,
                $columnVaultSourceId TEXT NOT NULL,
                $columnVaultIsDefault BOOL NOT NULL,
                $columnVaultSortKey TEXT NOT NULL,
                $columnVaultCreated TEXT,
                $columnVaultModified TEXT
              )
              ''';

  static final List<String> _vaultsTableColumns = [
    columnVaultId,
    columnVaultNickname,
    columnVaultSource,
    columnVaultSourceId,
    columnVaultIsDefault,
    columnVaultSortKey,
    columnVaultCreated,
    columnVaultModified,
  ];

  Future<int> insert(Vault v) async {
    Database db = await _database;
    int id;
    try {
      v.createdAt = DateTime.now();
      v.modifiedAt = DateTime.now();
      Log.debug(v.toMap());
      id = await db.insert(vaultTableName, v.toMap());
    } catch (e) {
      Log.debug(e);
      throw e;
    }
    return id;
  }

  Future<void> bulkInsert(List<Vault> lv) async {
    Database db = await _database;
    var batch = db.batch();
    lv.forEach((v) {
      v.createdAt = DateTime.now();
      v.modifiedAt = DateTime.now();
      batch.insert(vaultTableName, v.toMap());
    });
    var results = await batch.commit(continueOnError: true);
    Log.debug(results);
    return;
  }

  Future<void> bulkInsertMap(List<Map<String, dynamic>> lv) async {
    Database db = await _database;
    var batch = db.batch();
    lv.forEach((v) {
      v[columnVaultCreated] = DateTime.now().toIso8601String();
      v[columnVaultCreated] = DateTime.now().toIso8601String();
      batch.insert(vaultTableName, v);
    });
    var results = await batch.commit(continueOnError: true);
    Log.debug(results);
    return;
  }

  Future<Vault> getVaultByID(String uid) async {
    Database db = await _database;
    List<Map> maps = await db.query(vaultTableName,
        columns: _vaultsTableColumns,
        where: '$columnVaultId = ?',
        whereArgs: [uid]);
    if (maps.length > 0) {
      var v = Vault.fromMap(maps.first);
      return v;
    }
    return null;
  }

  Future<Vault> getDefaultVault() async {
    Database db = await _database;
    List<Map> maps = await db.query(vaultTableName,
        columns: _vaultsTableColumns, where: '$columnVaultIsDefault = ?',
        // Have to use `1` instead of `true` because:
        //      "Invalid argument true with type bool.
        //       Only num, String and Uint8List are supported"
        // whereArgs: [true]);
        whereArgs: [1]);
    if (maps.length > 0) {
      var v = Vault.fromMap(maps.first);
      return v;
    }
    return null;
  }

  Future<List<Vault>> getAllVaults() async {
    Database db = await _database;
    List<Map> maps = await db.query(vaultTableName,
        columns: _vaultsTableColumns, orderBy: columnVaultNickname);
    if (maps.length > 0) {
      List<Vault> vaultList = <Vault>[];
      maps.forEach((m) => vaultList.add(Vault.fromMap(m)));
      return vaultList;
    }
    return null;
  }

  Future<List<Vault>> getAllInternalVaults() async {
    Database db = await _database;
    List<Map> maps = await db.query(vaultTableName,
        columns: _vaultsTableColumns,
        where: '$columnVaultSource = ?',
        whereArgs: [vaultSourceToString(VaultSource.Internal)],
        orderBy: columnVaultNickname);
    if (maps.length > 0) {
      List<Vault> vaultList = <Vault>[];
      maps.forEach((m) => vaultList.add(Vault.fromMap(m)));
      return vaultList;
    }
    return null;
  }

  Future<List<Vault>> getAllExternalVaults() async {
    Database db = await _database;
    List<Map> maps = await db.query(vaultTableName,
        columns: _vaultsTableColumns,
        where: '$columnVaultSource = ?',
        whereArgs: [vaultSourceToString(VaultSource.External)],
        orderBy: columnVaultNickname);
    if (maps.length > 0) {
      List<Vault> vaultList = <Vault>[];
      maps.forEach((m) => vaultList.add(Vault.fromMap(m)));
      return vaultList;
    }
    return null;
  }

  Future<int> update(Vault v) async {
    Database db = await _database;

    v.modifiedAt = DateTime.now();
    int id = await db.update(vaultTableName, v.toMap(),
        where: '$columnVaultId = ?', whereArgs: [v.uid]);
    return id;
  }

  Future<int> delete(String uid) async {
    Database db = await _database;

    int id = await db
        .delete(vaultTableName, where: '$columnVaultId = ?', whereArgs: [uid]);
    return id;
  }

  Future<int> deleteAll() async {
    Database db = await _database;

    int id = await db.delete(vaultTableName);
    return id;
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

/* Device Syncs */
class _NullPassSyncDevicesDB {
  _NullPassSyncDevicesDB._privateConstructor();
  static final _NullPassSyncDevicesDB instance =
      _NullPassSyncDevicesDB._privateConstructor();

  // This is the actual database filename that is saved in the docs directory.
  // static final _dbName = "nullpass_syncs";
  // Increment this version when you need to change the schema.
  static final createTable = '''
              CREATE TABLE $syncTableName (
                $columnSyncId TEXT PRIMARY KEY,
                $columnSyncDeviceId TEXT NOT NULL,
                $columnSyncDeviceConnectionId TEXT,
                $columnSyncFrom BOOL NOT NULL,
                $columnSyncVaultId TEXT,
                $columnSyncVaultName TEXT NOT NULL,
                $columnSyncVaultAccess TEXT NOT NULL,
                $columnSyncNotes TEXT,
                $columnSyncCreated TEXT,
                $columnSyncModified TEXT,
                $columnSyncLastPerformed TEXT
              )
              ''';

  static final List<String> _syncDevicesTableColumns = [
    columnSyncId,
    columnSyncDeviceId,
    columnSyncDeviceConnectionId,
    columnSyncFrom,
    columnSyncVaultId,
    columnSyncVaultName,
    columnSyncVaultAccess,
    columnSyncNotes,
    columnSyncCreated,
    columnSyncModified,
    columnSyncLastPerformed,
  ];

  /* Database helper methods */

  Future<int> insert(DeviceSync d) async {
    Database db = await _database;
    d.created = DateTime.now().toUtc();
    d.lastModified = DateTime.now().toUtc();
    Log.debug(d.toMap());
    int id = await db.insert(syncTableName, d.toMap());
    return id;
  }

  Future<void> bulkInsert(List<dynamic> ld) async {
    Database db = await _database;
    var batch = db.batch();
    ld.forEach((d) => batch.insert(syncTableName, d));
    var results = await batch.commit(continueOnError: true);
    Log.debug(results);
    return;
  }

  Future<void> bulkInsertMaps(List<Map<String, dynamic>> ld) async {
    Database db = await _database;
    var batch = db.batch();
    ld.forEach((d) => batch.insert(syncTableName, d));
    await batch.commit(noResult: true, continueOnError: true);
    return;
  }

  Future<void> bulkInsertSync(List<DeviceSync> ld) async {
    Database db = await _database;
    var batch = db.batch();
    ld.forEach((d) => batch.insert(syncTableName, d.toMap()));
    await batch.commit(noResult: true, continueOnError: true);
    return;
  }

  Future<DeviceSync> getSyncByID(String uid) async {
    Database db = await _database;
    List<Map> maps = await db.query(syncTableName,
        columns: _syncDevicesTableColumns,
        where: '$columnSyncId = ?',
        whereArgs: [uid]);
    if (maps.length > 0) {
      var d = DeviceSync.fromMap(maps.first);
      return d;
    }
    return null;
  }

  Future<DeviceSync> getSyncByDeviceID(String uid) async {
    Database db = await _database;
    List<Map> maps = await db.query(syncTableName,
        columns: _syncDevicesTableColumns,
        where: '$columnSyncDeviceId = ?',
        whereArgs: [uid]);
    if (maps.length > 0) {
      var d = DeviceSync.fromMap(maps.first);
      return d;
    }
    return null;
  }

  Future<List<DeviceSync>> getAllSyncs() async {
    Database db = await _database;
    List<Map> maps = await db.query(syncTableName,
        columns: _syncDevicesTableColumns, orderBy: columnSyncLastPerformed);
    if (maps.length > 0) {
      List<DeviceSync> deviceList = <DeviceSync>[];
      maps.forEach((m) => deviceList.add(DeviceSync.fromMap(m)));
      return deviceList;
    }
    return null;
  }

  Future<List<DeviceSync>> getAllVaultSyncsFromDevice(String vault) async {
    Database db = await _database;
    List<Map> maps = await db.query(syncTableName,
        columns: _syncDevicesTableColumns,
        where: '$columnSyncFrom = true AND $columnSyncVaultId = ?',
        whereArgs: [vault]);
    if (maps.length > 0) {
      List<DeviceSync> deviceList = <DeviceSync>[];
      maps.forEach((m) => deviceList.add(DeviceSync.fromMap(m)));
      return deviceList;
    }
    return null;
  }

  Future<int> update(DeviceSync d) async {
    Database db = await _database;
    d.lastModified = DateTime.now().toUtc();

    int id = await db.update(syncTableName, d.toMap(),
        where: '$columnSyncId = ?', whereArgs: [d.id]);
    return id;
  }

  Future<int> delete(String id) async {
    Database db = await _database;
    int retId = await db
        .delete(syncTableName, where: '$columnSyncId = ?', whereArgs: [id]);
    return retId;
  }

  Future<int> deleteAll() async {
    Database db = await _database;
    int id = await db.delete(syncTableName);
    return id;
  }
}
