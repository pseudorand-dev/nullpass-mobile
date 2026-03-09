/*
 * Created by Ilan Rasekh on 2019/10/2
 * Copyright (c) 2019 Pseudorand Development. All rights reserved.
 */

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:nullpass/common.dart';
import 'package:nullpass/services/logging.dart';
import 'package:otp/otp.dart';
import 'package:uuid/uuid.dart';
import 'package:validators/validators.dart';

// database table and column names that correlate to the map keys
const String secretTableName = 'secrets';
const String columnSecretId = '_id';
const String columnSecretNickname = 'nickname';
const String columnSecretUsername = 'username';
const String columnSecretType = 'type';
const String columnSecretWebsite = 'website';
const String columnSecretAppName = 'appName';
const String columnSecretGenericEndpoint = 'genericEndpoint';
const String columnSecretThumbnailURI = 'thumbnailURI';
const String columnSecretNotes = 'notes';
const String columnSecretTags = 'tags';
const String columnSecretVaults = 'vaults';
const String columnSecretCreated = 'created';
const String columnSecretLastModified = 'lastModified';
const String columnSecretSortKey = 'sortKey';

enum SecretType { Website, App, Generic }

SecretType parseSecretTypeFromString(String str) {
  String strToLower = str.toLowerCase();

  if (SecretType.App.toString().toLowerCase() == strToLower ||
      SecretType.App.toString().substring(7).toLowerCase() == strToLower) {
    return SecretType.App;
  }

  if (SecretType.Generic.toString().toLowerCase() == strToLower ||
      SecretType.Generic.toString().substring(7).toLowerCase() == strToLower) {
    return SecretType.Generic;
  }

  if (SecretType.Website.toString().toLowerCase() == strToLower ||
      SecretType.Website.toString().substring(7).toLowerCase() == strToLower) {
    return SecretType.Website;
  }

  throw Exception("Unknown SecretType");
}

SecretType? tryParseSecretTypeFromString(String str) {
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
  late String uuid;
  late String nickname;
  late String username;
  late SecretType type;
  late String website;
  late String appName;
  late String genericEndpoint;
  String? message;
  String? otpCode;
  String get thumbnailURI => _getThumbnail();
  late String notes;
  late List<String> tags;
  late List<String> vaults;
  late DateTime created;
  late DateTime lastModified;
  String get sortKey => nickname.toLowerCase();
  int get strength => _secretStrength();

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
  String otp
  */

  factory Secret.fromJson(Map<String, dynamic> json) =>
      Secret.secretFromJson(json);

  // TODO: move password to secure storage and remove required
  Secret({
    required String nickname,
    required String username,
    String? message,
    String? uuid,
    SecretType type = SecretType.Website,
    String website = '',
    String appName = '',
    String genericEndpoint = '',
    String? otpCode,
    String thumbnailURI = '',
    String notes = '',
    List<String>? tags,
    List<String>? vaults,
    DateTime? created,
    DateTime? lastModified,
  }) {
    if (uuid == null || uuid.trim() == '' || !isUUID(uuid, 4)) {
      uuid = (const Uuid()).v4();
    }
    DateTime now = DateTime.now().toUtc();

    this.uuid = uuid;
    this.nickname = nickname;
    this.username = username;
    this.message = message;
    this.otpCode = otpCode;
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
    // Return empty string if website is empty or null
    if (website == null || website.isEmpty || website.trim().isEmpty) {
      return '';
    }

    try {
      Uri uri;
      if (website.startsWith("http")) {
        uri = Uri.parse(website);
      } else {
        uri = Uri.parse('http://$website');
      }

      // Return empty if host is empty or invalid
      if (uri.host.isEmpty) {
        return '';
      }

      // Using Google's favicon service (more reliable than Clearbit)
      // sz parameter: 16, 32, 64, 128, 256
      return 'https://www.google.com/s2/favicons?domain=${uri.host}&sz=128';
      
      // Alternative services:
      // Clearbit: 'https://logo.clearbit.com/${uri.host}';
      // FaviconKit: 'https://api.faviconkit.com/${uri.host}/144';
    } catch (e) {
      // If parsing fails, return empty string
      return '';
    }
  }

  int _secretStrength() {
    final msg = message ?? '';
    Map<String, double> entropyMap = <String, double>{};
    msg.split('').forEach((String character) {
      entropyMap[character] =
          (entropyMap[character] ?? 0.0) + 1.0;
    });

    var score = 0.0;
    final msgLength = msg.length;
    if (msgLength == 0) return 0;
    
    if (entropyMap.length == 1) {
      var val = entropyMap.values.first;
      score =
          0 - ((val / msgLength) * log(val / msgLength));
    } else {
      // var result = 0.0;
      score = entropyMap.values.reduce((result, val) =>
          result -
          ((val / msgLength) * log(val / msgLength)));
    }
    if ((score >= 3.5 && score < 4) || (score >= 4.5 && score < 5)) {
      return score.ceil();
    }
    return score.floor();
  }

  Color strengthColor() {
    switch (strength) {
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
    uuid = map[columnSecretId] ?? map['uuid'] ?? map['_id'] ?? map['gid'] ?? '';
    message = map['message'] ?? map['password'];
    otpCode = map['otpCode'] ?? map['otp'];
    nickname = map[columnSecretNickname] ?? '';
    username = map[columnSecretUsername] ?? '';
    type = tryParseSecretTypeFromString(map[columnSecretType]) ?? SecretType.Website;
    website = map[columnSecretWebsite] ?? '';
    appName = map[columnSecretAppName] ?? '';
    genericEndpoint = map[columnSecretGenericEndpoint] ?? '';
    // thumbnailURI = map[columnSecretThumbnailURI];
    notes = map[columnSecretNotes] ?? '';

    tags = <String>[];
    if (map[columnSecretTags] is String &&
        (map[columnSecretTags] as String).trim().isNotEmpty) {
      tags = (map[columnSecretTags] as String).split(',');
    } else if (map[columnSecretTags] is List &&
        (map[columnSecretTags] as List).isNotEmpty) {
      for (var v in (map[columnSecretTags] as List)) {
        tags.add(v as String);
      }
    }

    vaults = <String>[];
    if (map[columnSecretVaults] is String &&
        (map[columnSecretVaults] as String).trim().isNotEmpty) {
      vaults = (map[columnSecretVaults] as String).split(',');
    } else if (map[columnSecretVaults] is List &&
        (map[columnSecretVaults] as List).isNotEmpty) {
      for (var v in (map[columnSecretVaults] as List)) {
        vaults.add(v as String);
      }
    }

    created = DateTime.tryParse(map[columnSecretCreated]) ?? DateTime.now();
    lastModified =
        DateTime.tryParse(map[columnSecretLastModified]) ?? DateTime.now();
  }

  // convenience method to create a Map from this Secret object
  Map<String, dynamic> toMap() {
    if (uuid.trim() == '' || !isUUID(uuid, 4)) {
      uuid = (const Uuid()).v4();
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
      // columnOTPCode: otpCode,
    };
    return map;
  }

  Map<String, dynamic> toJson() => {
        'gid': uuid,
        'nickname': nickname,
        'username': username,
        'message': message,
        'otpCode': otpCode,
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
    if (jsonBlob.containsKey('created')) {
      created = DateTime.tryParse(jsonBlob['created']) ?? now;
    }
    if (jsonBlob.containsKey('createdOn')) {
      created = DateTime.tryParse(jsonBlob['createdOn']) ?? now;
    }

    var lastModified = now;
    if (jsonBlob.containsKey('lastModified')) {
      lastModified = DateTime.tryParse(jsonBlob['lastModified']) ?? now;
    }
    if (jsonBlob.containsKey('lastUpdatedOn')) {
      lastModified = DateTime.tryParse(jsonBlob['lastUpdatedOn']) ?? now;
    }

    return Secret(
      uuid: jsonBlob['uuid'] ?? jsonBlob['_id'] ?? jsonBlob['gid'] ?? '',
      nickname: jsonBlob['nickname'],
      username: jsonBlob['username'],
      message: jsonBlob['message'] ?? jsonBlob['password'],
      otpCode: jsonBlob['otpCode'] ?? jsonBlob['otp'],
      type:
          tryParseSecretTypeFromString(jsonBlob['type']) ?? SecretType.Generic,
      website: jsonBlob['website'],
      appName: jsonBlob['appName'],
      genericEndpoint: jsonBlob['genericEndpoint'],
      thumbnailURI: jsonBlob['thumbnailURI'] ?? jsonBlob['thumbnailUri'],
      notes: jsonBlob['notes'],
      tags: List.from(jsonBlob['tags']) ?? <String>[],
      vaults: jsonBlob.containsKey('vaults')
          ? List.from(jsonBlob['vaults']) ?? <String>[]
          : <String>[],
      created: created,
      lastModified: lastModified,
    );
  }

  @override
  String toString() {
    var sec = "{";
    sec = "$sec\"gid\":\"$uuid\"";

    sec = "$sec,\"nickname\":\"$nickname\"";
  
    sec = "$sec,\"username\":\"$username\"";
  
    if (message != null) {
      sec = "$sec,\"message\":\"$message\"";
    }

    if (otpCode != null) {
      sec = "$sec,\"otpCode\":\"$otpCode\"";
    }

    sec = "$sec,\"type\":\"${secretTypeToString(type)}\"";
  
    sec = "$sec,\"website\":\"$website\"";
  
    sec = "$sec,\"appName\":\"$appName\"";
  
    sec = "$sec,\"genericEndpoint\":\"$genericEndpoint\"";
  
    sec = "$sec,\"thumbnailURI\":\"$thumbnailURI\"";
  
    sec = "$sec,\"notes\":\"$notes\"";
  
    sec = "$sec,\"tags\":${stringListToString(tags)}";
  
    sec = "$sec,\"vaults\":${stringListToString(vaults)}";
  
    sec = "$sec,\"created\":\"${created.toIso8601String()}\"";
  
    sec = "$sec,\"lastModified\":\"${lastModified.toIso8601String()}\"";
  
    sec = "$sec,\"sortKey\":\"$sortKey\"";
  
    sec = "$sec}";

    return sec;
  }

  Secret clone() {
    var s = Secret(
      uuid: uuid,
      nickname: nickname,
      username: username,
      type: type,
      website: website,
      appName: appName,
      genericEndpoint: genericEndpoint,
      message: message,
      otpCode: otpCode,
      notes: notes,
      tags: <String>[],
      vaults: <String>[],
      created: created,
      lastModified: lastModified,
    );

    for (var t in tags) {
      s.tags.add(t);
    }
    for (var v in vaults) {
      s.vaults.add(v);
    }

    return s;
  }

  String getOnetimePasscode() {
    return generateOnetimePasscode(otpCode ?? '');
  }

  static String generateOnetimePasscode(String otpCode) {
    if (otpCode.trim().isEmpty) {
      return '';
    }

    try {
      Log.debug("generating otpCode without padding");
      var passcode = OTP.generateTOTPCodeString(
        otpCode.toUpperCase(),
        DateTime.now().millisecondsSinceEpoch,
      );
      Log.debug("passcode: $passcode");
      return passcode;
    } catch (e) {
      Log.error("Error generating OTP without padding: $e");
    }

    try {
      Log.debug("generating otpCode with padding");
      var passcode = OTP.generateTOTPCodeString(
        otpCode.toUpperCase(),
        DateTime.now().millisecondsSinceEpoch,
        isGoogle: true,
      );
      Log.debug("passcode: $passcode");
      return passcode;
    } catch (e) {
      Log.error("Error generating OTP with padding: $e");
    }

    return '';
  }
}
