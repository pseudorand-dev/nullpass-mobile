/*
 * Created by Ilan Rasekh on 2019/10/2
 * Copyright (c) 2019 Pseudorand Development. All rights reserved.
 */

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:nullpass/common.dart';
import 'package:nullpass/services/logging.dart';
import 'package:otp/otp.dart';
import 'package:uuid/uuid.dart';
import 'package:validators/validators.dart';

// database table and column names that correlate to the map keys
final String secretTableName = 'secrets';
final String columnSecretId = '_id';
final String columnSecretNickname = 'nickname';
final String columnSecretUsername = 'username';
final String columnSecretOTPTitle = 'otpTitle';
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

enum SecretType { Website, App, Generic, OTP }

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
  String otpCode;
  String _otpTitle;
  String get thumbnailURI => _getThumbnail();
  String notes;
  List<String> tags;
  List<String> vaults;
  DateTime created;
  DateTime lastModified;
  String get sortKey => this.nickname.toLowerCase();
  int get strength => this._secretStrength();

  String get otpTitle => _getOTPTitle();
  void set otpTitle(String title) => this._otpTitle = title;

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
  String otpTitleKey
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
    String otpCode = '',
    String otpTitle = '',
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
    this._otpTitle = otpTitle;
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
    uuid = map[columnSecretId] ?? map['uuid'] ?? map['_id'] ?? map['gid'] ?? '';
    message = map['message'] ?? map['password'];
    otpCode = map['otpCode'] ?? map['otp'];
    _otpTitle = map[columnSecretOTPTitle];
    nickname = map[columnSecretNickname];
    username = map[columnSecretUsername];
    type = tryParseSecretTypeFromString(map[columnSecretType]);
    website = map[columnSecretWebsite];
    appName = map[columnSecretAppName];
    genericEndpoint = map[columnSecretGenericEndpoint];
    // thumbnailURI = map[columnSecretThumbnailURI];
    notes = map[columnSecretNotes];

    tags = <String>[];
    if (map[columnSecretTags] is String &&
        (map[columnSecretTags] as String).trim().isNotEmpty) {
      tags = (map[columnSecretTags] as String).split(',');
    } else if (map[columnSecretTags] is List &&
        (map[columnSecretTags] as List).isNotEmpty) {
      (map[columnSecretTags] as List).forEach((v) => tags.add(v as String));
    }

    vaults = <String>[];
    if (map[columnSecretVaults] is String &&
        (map[columnSecretVaults] as String).trim().isNotEmpty) {
      vaults = (map[columnSecretVaults] as String).split(',');
    } else if (map[columnSecretVaults] is List &&
        (map[columnSecretVaults] as List).isNotEmpty) {
      (map[columnSecretVaults] as List).forEach((v) => vaults.add(v as String));
    }

    created = DateTime.tryParse(map[columnSecretCreated]) ?? DateTime.now();
    lastModified =
        DateTime.tryParse(map[columnSecretLastModified]) ?? DateTime.now();
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
      columnSecretOTPTitle: _otpTitle,
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
        'otpTitle': _otpTitle,
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
      otpCode: jsonBlob['otpCode'] ?? jsonBlob['otp'],
      otpTitle: jsonBlob['otpTitle'],
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

  @override
  String toString() {
    var sec = "{";
    sec = "$sec\"gid\":\"${this.uuid}\"";

    if (this.nickname != null) {
      sec = "$sec,\"nickname\":\"${this.nickname}\"";
    }

    if (this.username != null) {
      sec = "$sec,\"username\":\"${this.username}\"";
    }

    if (this.message != null) {
      sec = "$sec,\"message\":\"${this.message}\"";
    }

    if (this.otpCode != null) {
      sec = "$sec,\"otpCode\":\"${this.otpCode}\"";
    }

    if (this._otpTitle != null) {
      sec = "$sec,\"otpTitle\":\"${this._otpTitle}\"";
    }

    if (this.type != null) {
      sec = "$sec,\"type\":\"${secretTypeToString(this.type)}\"";
    }

    if (this.website != null) {
      sec = "$sec,\"website\":\"${this.website}\"";
    }

    if (this.appName != null) {
      sec = "$sec,\"appName\":\"${this.appName}\"";
    }

    if (this.genericEndpoint != null) {
      sec = "$sec,\"genericEndpoint\":\"${this.genericEndpoint}\"";
    }

    if (this.thumbnailURI != null) {
      sec = "$sec,\"thumbnailURI\":\"${this.thumbnailURI}\"";
    }

    if (this.notes != null) {
      sec = "$sec,\"notes\":\"${this.notes}\"";
    }

    if (this.tags != null) {
      sec = "$sec,\"tags\":${stringListToString(this.tags)}";
    }

    if (this.vaults != null) {
      sec = "$sec,\"vaults\":${stringListToString(this.vaults)}";
    }

    if (this.created != null) {
      sec = "$sec,\"created\":\"${this.created.toIso8601String()}\"";
    }

    if (this.lastModified != null) {
      sec = "$sec,\"lastModified\":\"${this.lastModified.toIso8601String()}\"";
    }

    if (this.sortKey != null) {
      sec = "$sec,\"sortKey\":\"${this.sortKey}\"";
    }

    sec = "$sec}";

    return sec;
  }

  Secret clone() {
    var s = Secret(
      uuid: this.uuid,
      nickname: this.nickname,
      username: this.username,
      type: this.type,
      website: this.website,
      appName: this.appName,
      genericEndpoint: this.genericEndpoint,
      message: this.message,
      otpCode: this.otpCode,
      otpTitle: this._otpTitle,
      notes: this.notes,
      tags: <String>[],
      vaults: <String>[],
      created: this.created,
      lastModified: this.lastModified,
    );

    this.tags.forEach((t) => s.tags.add(t));
    this.vaults.forEach((v) => s.vaults.add(v));

    return s;
  }

  String _getOTPTitle() {
    if (this._otpTitle != null && this._otpTitle.trim().isNotEmpty) {
      return this._otpTitle;
    } else {
      return "${this.website.trim()} (${this.username.trim()})";
    }
  }

  bool isOTPTitleStored() {
    return this._otpTitle != null && this._otpTitle.trim().isNotEmpty;
  }

  String getOnetimePasscode() {
    return generateOnetimePasscode(this.otpCode);
  }

  static int getOtpTimeRemaining() {
    return OTP.remainingSeconds();
  }

  static String generateOnetimePasscode(String otpCode) {
    if (otpCode == null || otpCode.trim().isEmpty) {
      return '';
    }

    try {
      Log.debug("generating otpCode with padding");
      var passcode = OTP.generateTOTPCodeString(
        otpCode.toUpperCase(),
        DateTime.now().millisecondsSinceEpoch,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );
      Log.debug("Google padded passcode: $passcode");
      return passcode;
    } catch (e) {
      Log.error("Error generating OTP with padding: $e");
    }

    try {
      Log.debug("generating otpCode without padding");
      var passcode = OTP.generateTOTPCodeString(
        otpCode.toUpperCase(),
        DateTime.now().millisecondsSinceEpoch,
        algorithm: Algorithm.SHA1,
      );
      Log.debug("passcode: $passcode");
      return passcode;
    } catch (e) {
      Log.error("Error generating OTP without padding: $e");
    }

    return '';
  }
}
