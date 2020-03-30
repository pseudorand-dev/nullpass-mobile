/*
 * Created by Ilan Rasekh on 2019/10/2
 * Copyright (c) 2019 Pseudorand Development. All rights reserved.
 */

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:validators/validators.dart';

// database table and column names that correlate to the map keys
final String secretTableName = 'secrets';
final String columnSecretId = '_id';
final String columnSecretNickname = 'nickname';
final String columnSecretUsername = 'username';
final String columnSecretType = 'type';
final String columnSecretWebsite = 'website';
final String columnSecretAppName = 'appName';
final String columnSecretGenericEndpoint = 'genericEndpoint';
final String columnSecretThumbnailURI = 'thumbnailURI';
final String columnSecretNotes = 'notes';
final String columnSecretTags = 'tags';
final String columnSecretVaults = 'vaults';
final String columnSecretCreated = 'created';
final String columnSecretLastModified = 'lastModified';
final String columnSecretSortKey = 'sortKey';

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
    uuid = map[columnSecretId];
    nickname = map[columnSecretNickname];
    username = map[columnSecretUsername];
    type = tryParseSecretTypeFromString(map[columnSecretType]);
    website = map[columnSecretWebsite];
    appName = map[columnSecretAppName];
    genericEndpoint = map[columnSecretGenericEndpoint];
    // thumbnailURI = map[columnSecretThumbnailURI];
    notes = map[columnSecretNotes];
    tags = (map[columnSecretTags] as String).trim().isEmpty
        ? <String>[]
        : (map[columnSecretTags] as String).split(',');
    vaults = (map[columnSecretVaults] as String).trim().isEmpty
        ? <String>[]
        : (map[columnSecretVaults] as String).split(',');
    created = DateTime.tryParse(columnSecretCreated);
    lastModified = DateTime.tryParse(columnSecretLastModified);
  }

  // convenience method to create a Map from this Secret object
  Map<String, dynamic> toMap() {
    if (uuid == null || uuid.trim() == '' || !isUUID(uuid, 4)) {
      uuid = (new Uuid()).v4();
    }
    var map = <String, dynamic>{
      columnSecretId: uuid,
      columnSecretNickname: nickname,
      columnSecretUsername: username,
      columnSecretType: secretTypeToString(type),
      columnSecretWebsite: website,
      columnSecretAppName: appName,
      columnSecretGenericEndpoint: genericEndpoint,
      columnSecretThumbnailURI: thumbnailURI,
      columnSecretNotes: notes,
      columnSecretTags: tags.join(','),
      columnSecretVaults: vaults.join(','),
      columnSecretCreated: created.toIso8601String(),
      columnSecretLastModified: lastModified.toIso8601String(),
      columnSecretSortKey: sortKey,
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
      vaults: jsonBlob.containsKey('vaults')
          ? new List.from(jsonBlob['vaults']) ?? <String>[]
          : <String>[],
      created: created,
      lastModified: lastModified,
    );
  }
}
