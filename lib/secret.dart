/*
 * Created by Ilan Rasekh on 2019/10/2
 * Copyright (c) 2019 Pseudorand Development. All rights reserved.
 */

import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:validators/validators.dart';

// database table and column names
//final String databaseName = 'NullPass';
final String tableName = 'secrets';
final String _columnId = '_id';
final String _columnNickname = 'nickname';
final String _columnUsername = 'username';
final String _columnType = 'type';
final String _columnWebsite = 'website';
final String _columnAppName = 'appName';
final String _columnGenericEndpoint = 'genericEndpoint';
final String _columnThumbnailURI = 'thumbnailURI';
final String _columnNotes = 'notes';
final String _columnTags = 'tags';
final String _columnVaults = 'vaults';
final String _columnCreated = 'created';
final String _columnLastModified = 'lastModified';
final String _columnSortKey = 'sortKey';

enum SecretType { Website, App, Generic }

SecretType parseSecretTypeFromString(String str) {
  String strToLower = str.toLowerCase();

  if (SecretType.App.toString().toLowerCase() == strToLower ||
      SecretType.App.toString().substring(7).toLowerCase() == strToLower)
    return SecretType.App;

  if (SecretType.Generic.toString().toLowerCase() == strToLower ||
      SecretType.Generic.toString().substring(7).toLowerCase() == strToLower)
    return SecretType.Generic;

  if (SecretType.Website.toString().toLowerCase() == strToLower ||
      SecretType.Website.toString().substring(7).toLowerCase() == strToLower)
    return SecretType.Website;

  throw new Exception("Unknown SecretType");
}

SecretType tryParseSecretTypeFromString(String str) {
  try {
    return parseSecretTypeFromString(str);
  } catch (e) {
    return null;
  }
}

String secretTypeToString(SecretType st) {
  return st.toString().substring(7);
}

class Secret {
  String uuid;
  String nickname;
  String username;
  SecretType type;
  String website;
  String appName;
  String genericEndpoint;
  String message;
  String get thumbnailURI => _getThumbnail();
  String notes;
  List<String> tags;
  List<String> vaults;
  DateTime created;
  DateTime lastModified;
  String get sortKey => this.nickname.toLowerCase();
  int get strength => this._secretStrength();

  /*
  String uuid
  String nickname
  String username
  String thumbnailUri
  - enum? type
  String website
  String appName
  String genericEndpoint
  ? int/String strength
  String message
  List<String> tags
  String notes
  DateTime createdOn
  DateTime lastUpdatedOn
  */

  factory Secret.fromJson(Map<String, dynamic> json) =>
      Secret.secretFromJson(json);

  // TODO: move password to secure storage and remove @required
  Secret({
    @required String nickname,
    @required String username,
    @required String message,
    String uuid,
    SecretType type = SecretType.Website,
    String website = '',
    String appName = '',
    String genericEndpoint = '',
    String thumbnailURI = '',
    String notes = '',
    List<String> tags,
    List<String> vaults,
    DateTime created,
    DateTime lastModified,
  }) {
    if (uuid == null || uuid.trim() == '' || !isUUID(uuid, 4)) {
      uuid = (new Uuid()).v4();
    }
    DateTime now = DateTime.now().toUtc();

    this.uuid = uuid;
    this.nickname = nickname;
    this.username = username;
    this.message = message;
    this.type = type;
    this.website = website;
    this.appName = appName;
    this.genericEndpoint = genericEndpoint;
    // this.thumbnailURI = (thumbnailURI != null)
    //     ? thumbnailURI
    //     : 'https://api.faviconkit.com/soundcloud.com/144';
    //     : 'https://logo.clearbit.com/amazon.com';
    this.notes = notes;
    this.tags = tags ?? <String>[];
    this.vaults = vaults ?? <String>[];
    this.created = created ?? now;
    this.lastModified = lastModified ?? now;
  }

  String _getThumbnail() {
    Uri uri;
    if (this.website.startsWith("http"))
      uri = Uri.parse(this.website);
    else
      uri = Uri.parse('http://${this.website}');

    //"https://logo.clearbit.com/slack.com"
    return 'https://logo.clearbit.com/${uri.host}';

    // 'https://api.faviconkit.com/soundcloud.com/144';
    // return 'https://api.faviconkit.com/${uri.host}/144';
  }

  int _secretStrength() {
    Map<String, double> entropyMap = new Map<String, double>();
    this.message.split('').forEach((String character) {
      entropyMap[character] =
          entropyMap[character] != null ? entropyMap[character] + 1.0 : 1.0;
    });

    var score = 0.0;
    if (entropyMap.length == 1) {
      var val = entropyMap.values.first;
      score =
          0 - ((val / this.message.length) * log(val / this.message.length));
    } else {
      // var result = 0.0;
      score = entropyMap.values.reduce((result, val) =>
          result -
          ((val / this.message.length) * log(val / this.message.length)));
    }
    if ((score >= 3.5 && score < 4) || (score >= 4.5 && score < 5)) {
      return score.ceil();
    }
    return score.floor();
  }

  Color strengthColor() {
    switch (this.strength) {
      case 5:
        {
          return Colors.blue;
        }
      case 4:
        {
          return Colors.green;
        }
      case 3:
        {
          return Colors.orange;
        }
      case 2:
        {
          return Colors.red;
        }
      default:
        {
          return Colors.black;
        }
    }
  }

  // convenience constructor to create a Secret object
  Secret.fromMap(Map<String, dynamic> map) {
    uuid = map[_columnId];
    nickname = map[_columnNickname];
    username = map[_columnUsername];
    type = tryParseSecretTypeFromString(map[_columnType]);
    website = map[_columnWebsite];
    appName = map[_columnAppName];
    genericEndpoint = map[_columnGenericEndpoint];
    // thumbnailURI = map[_columnThumbnailURI];
    notes = map[_columnNotes];
    tags = (map[_columnTags] as String).trim().isEmpty
        ? <String>[]
        : (map[_columnTags] as String).split(',');
    vaults = (map[_columnVaults] as String).trim().isEmpty
        ? <String>[]
        : (map[_columnVaults] as String).split(',');
    created = DateTime.tryParse(_columnCreated);
    lastModified = DateTime.tryParse(_columnLastModified);
  }

  // convenience method to create a Map from this Secret object
  Map<String, dynamic> toMap() {
    if (uuid == null || uuid.trim() == '' || !isUUID(uuid, 4)) {
      uuid = (new Uuid()).v4();
    }
    var map = <String, dynamic>{
      _columnId: uuid,
      _columnNickname: nickname,
      _columnUsername: username,
      _columnType: secretTypeToString(type),
      _columnWebsite: website,
      _columnAppName: appName,
      _columnGenericEndpoint: genericEndpoint,
      _columnThumbnailURI: thumbnailURI,
      _columnNotes: notes,
      _columnTags: tags.join(','),
      _columnVaults: vaults.join(','),
      _columnCreated: created.toIso8601String(),
      _columnLastModified: lastModified.toIso8601String(),
      _columnSortKey: sortKey,
      // columnPassword: password, // TODO: move password to secure storage - remove
    };
    return map;
  }

  Map<String, dynamic> toJson() => {
        'gid': uuid,
        'nickname': nickname,
        'username': username,
        'message': message,
        'type': secretTypeToString(type),
        'website': website,
        'appName': appName,
        'genericEndpoint': genericEndpoint,
        'thumbnailURI': thumbnailURI,
        'notes': notes,
        'tags': tags,
        'vaults': vaults,
        'created': (created != null)
            ? created.toIso8601String()
            : DateTime.now().toUtc().toIso8601String(),
        'lastModified': (lastModified != null)
            ? lastModified.toIso8601String()
            : DateTime.now().toUtc().toIso8601String(),
        'sortKey': sortKey,
      };

  static Secret secretFromJson(Map<String, dynamic> jsonBlob) {
    var now = DateTime.now();
    var created = now;
    if (jsonBlob.containsKey('created'))
      created = DateTime.tryParse(jsonBlob['created']) ?? now;
    if (jsonBlob.containsKey('createdOn'))
      created = DateTime.tryParse(jsonBlob['createdOn']) ?? now;

    var lastModified = now;
    if (jsonBlob.containsKey('lastModified'))
      lastModified = DateTime.tryParse(jsonBlob['lastModified']) ?? now;
    if (jsonBlob.containsKey('lastUpdatedOn'))
      lastModified = DateTime.tryParse(jsonBlob['lastUpdatedOn']) ?? now;

    return Secret(
      uuid: jsonBlob['uuid'] ?? jsonBlob['_id'] ?? jsonBlob['gid'] ?? '',
      nickname: jsonBlob['nickname'],
      username: jsonBlob['username'],
      message: jsonBlob['message'] ?? jsonBlob['password'],
      type:
          tryParseSecretTypeFromString(jsonBlob['type']) ?? SecretType.Generic,
      website: jsonBlob['website'],
      appName: jsonBlob['appName'],
      genericEndpoint: jsonBlob['genericEndpoint'],
      thumbnailURI: jsonBlob['thumbnailURI'] ?? jsonBlob['thumbnailUri'],
      notes: jsonBlob['notes'],
      tags: new List.from(jsonBlob['tags']) ?? <String>[],
      vaults: jsonBlob.containsKey('vault')
          ? new List.from(jsonBlob['vaults']) ?? <String>[]
          : <String>[],
      created: created,
      lastModified: lastModified,
    );
  }
}

class NullPassDB {
  // Make this a singleton class.
  NullPassDB._privateConstructor();
  static final NullPassDB instance = NullPassDB._privateConstructor();

  static final _messageSecureStorage = new FlutterSecureStorage();
  // Only allow a single open connection to the database.
  static final _NullPassDetailsDB _detailsDB = _NullPassDetailsDB.instance;

  Future<bool> insert(Secret s) async {
    try {
      await _detailsDB.insert(s);
    } catch (e) {
      print(
          "an error occured while trying to add the secret to the details db: $e");
      return false;
    }

    try {
      await _messageSecureStorage.write(key: s.uuid, value: s.message);
    } catch (e) {
      print(
          "an error occured while trying to add the secret to the secure storage: $e");
      return false;
    }

    return true;
  }

  Future<void> insertBulk(List<Secret> ls) async {
    try {
      await _detailsDB.insertBulkSecrets(ls);
    } catch (e) {
      print(
          "an error occured while trying to bulk insert the secrets into the details db: $e");
    }

    try {
      ls.forEach((s) async =>
          await _messageSecureStorage.write(key: s.uuid, value: s.message));
    } catch (e) {
      print(
          "an error occured while trying to bulk insert the secrets into the secure storage: $e");
    }

    // throw new Exception("TBD - not yet implemented");
  }

  Future<Secret> getSecretByID(String uuid) async {
    Secret result;
    try {
      result = await _detailsDB.getSecretByID(uuid);
    } catch (e) {
      print(
          "an error occured while trying to fetch the secret from the details db: $e");
    }

    try {
      result.message = await _messageSecureStorage.read(key: uuid);
      return result;
    } catch (e) {
      print(
          "an error occured while trying to fetch the secret from the secure storage: $e");
    }

    return null;
  }

  Future<List<Secret>> getAllSecrets() async {
    List<Secret> secretList;
    try {
      secretList = await _detailsDB.getAllSecrets();
    } catch (e) {
      print(
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
        print(
            "an error occured while trying to fetch the secrets from the secure storage: $e");
      }
    }
    return null;
  }

  Future<bool> update(Secret s) async {
    try {
      await _messageSecureStorage.write(key: s.uuid, value: s.message);
    } catch (e) {
      print(
          "an error occured while trying to update the secret in the secure storage: $e");
      return false;
    }

    try {
      await _detailsDB.update(s);
    } catch (e) {
      print(
          "an error occured while trying to update the secret in the details db: $e");
      return false;
    }

    return true;
  }

  Future<bool> delete(String uuid) async {
    try {
      await _messageSecureStorage.delete(key: uuid);
    } catch (e) {
      print(
          "an error occured while trying to delete the secret from the secure storage: $e");
      return false;
    }

    try {
      await _detailsDB.delete(uuid);
    } catch (e) {
      print(
          "an error occured while trying to delete the secret from the details db: $e");
      return false;
    }
    return true;
  }

  Future<bool> deleteAll() async {
    try {
      await _messageSecureStorage.deleteAll();
    } catch (e) {
      print(
          "an error occured while trying to delete all secrets from the secure storage: $e");
      return false;
    }

    try {
      await _detailsDB.deleteAll();
    } catch (e) {
      print(
          "an error occured while trying to add the secret to the details db: $e");
      return false;
    }

    return true;
  }

  Future<List<Secret>> find(String keyword) async {
    List<Secret> sList;

    try {
      sList = await _detailsDB.find(keyword);
    } catch (e) {
      print(
          "an error occured while trying to add the secret to the details db: $e");
      return null;
    }

    try {
      sList.forEach((s) async {
        var message = await _messageSecureStorage.read(key: s.uuid);
        s.message = message;
      });
    } catch (e) {
      print(
          "an error occured while trying to delete all secrets from the secure storage: $e");
      return null;
    }

    return sList;
  }
}

class _NullPassDetailsDB {
  _NullPassDetailsDB._privateConstructor();
  static final _NullPassDetailsDB instance =
      _NullPassDetailsDB._privateConstructor();

  // This is the actual database filename that is saved in the docs directory.
  static final _databaseName = "nullpass";
  // Increment this version when you need to change the schema.
  static final _databaseVersion = 1;

  static final List<String> _secretTableColumns = [
    _columnId,
    _columnNickname,
    _columnUsername,
    _columnType,
    _columnWebsite,
    _columnAppName,
    _columnGenericEndpoint,
    _columnThumbnailURI,
    _columnNotes,
    _columnTags,
    _columnVaults,
    _columnCreated,
    _columnLastModified,
    _columnSortKey,
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
              CREATE TABLE $tableName (
                $_columnId TEXT PRIMARY KEY,
                $_columnNickname TEXT NOT NULL,
                $_columnUsername TEXT,
                $_columnType TEXT NOT NULL,
                $_columnWebsite TEXT,
                $_columnAppName TEXT,
                $_columnGenericEndpoint TEXT,
                $_columnThumbnailURI TEXT NOT NULL,
                $_columnNotes TEXT,
                $_columnTags TEXT,
                $_columnVaults TEXT,
                $_columnCreated TEXT,
                $_columnLastModified TEXT,
                $_columnSortKey TEXT NOT NULL
              )
              ''');
  }

  /* Database helper methods */

  Future<int> insert(Secret s) async {
    Database db = await database;
    s.created = DateTime.now().toUtc();
    s.lastModified = DateTime.now().toUtc();
    print(s.toMap());
    int id = await db.insert(tableName, s.toMap());
    return id;
  }

  Future<void> insertBulk(List<dynamic> ls) async {
    Database db = await database;
    var batch = db.batch();
    ls.forEach((s) => batch.insert(tableName, s));
    var results = await batch.commit(continueOnError: true);
    print(results);
    return;
  }

  Future<void> insertBulkMaps(List<Map<String, dynamic>> ls) async {
    Database db = await database;
    var batch = db.batch();
    ls.forEach((s) => batch.insert(tableName, s));
    await batch.commit(noResult: true, continueOnError: true);
    return;
  }

  Future<void> insertBulkSecrets(List<Secret> ls) async {
    Database db = await database;
    var batch = db.batch();
    ls.forEach((s) => batch.insert(tableName, s.toMap()));
    await batch.commit(noResult: true, continueOnError: true);
    return;
  }

  Future<Secret> getSecretByID(String uuid) async {
    Database db = await database;
    List<Map> maps = await db.query(tableName,
        columns: _secretTableColumns,
        where: '$_columnId = ?',
        whereArgs: [uuid]);
    if (maps.length > 0) {
      Secret s = Secret.fromMap(maps.first);
      return s;
    }
    return null;
  }

  Future<List<Secret>> getAllSecrets() async {
    Database db = await database;
    List<Map> maps = await db.query(tableName,
        columns: _secretTableColumns, orderBy: _columnSortKey);
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

    int id = await db.update(tableName, s.toMap(),
        where: '$_columnId = ?', whereArgs: [s.uuid]);
    return id;
  }

  Future<int> delete(String uuid) async {
    Database db = await database;
    int id =
        await db.delete(tableName, where: '$_columnId = ?', whereArgs: [uuid]);
    return id;
  }

  Future<int> deleteAll() async {
    Database db = await database;
    int id = await db.delete(tableName);
    return id;
  }

  Future<List<Secret>> find(String keyword) async {
    Database db = await database;
    List<Map<String, dynamic>> query = await db.query(tableName,
        where:
            '$_columnNickname LIKE ? OR $_columnWebsite LIKE ? OR $_columnUsername LIKE ?  OR $_columnNotes LIKE ?',
        whereArgs: ['%$keyword%', '%$keyword%', '%$keyword%', '%$keyword%']);
    List<Secret> secretList = <Secret>[];
    //     query != null ? query.map((i) => Secret.fromJson(i)).toList() : null;
    query.forEach((m) => secretList.add(Secret.fromMap(m)));
    return secretList;
  }
}
