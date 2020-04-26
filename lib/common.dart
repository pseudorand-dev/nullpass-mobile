/*
 * Created by Ilan Rasekh on 2019/10/4
 * Copyright (c) 2019 Pseudorand Development. All rights reserved.
 */

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nullpass/models/secret.dart';
import 'package:nullpass/services/notificationManager.dart' as np;
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:vibration/vibration.dart';

/* VARIABLES */
// TODO: Determine a better way to handle the OneSignal Key
const String OneSignalKey = "<THIS_NEEDS_TO_BE_ADDED_BEFORE_COMPILATION>";

// A common variable for the internal notification system
np.NotificationManager notify;

SharedPreferences sharedPrefs;
const String SecretLengthPrefKey = 'SecretLength';
const String AlphaCharactersPrefKey = 'AlphaCharacters';
const String NumericCharactersPrefKey = 'NumericCharacters';
const String SymbolCharactersPrefKey = 'SymbolCharacters';
const String EncryptionKeyPairSetupPrefKey = 'EncryptionKeyPairSetup';
const String DefaultVaultIDPrefKey = 'DefaultVaultID';
const String VaultsSetupPrefKey = 'VaultsSetup';
const String SharedPrefSetupKey = 'SpSetup';
const String InAppWebpagesPrefKey = 'InAppWebpages';
const String SyncdDataNotificationsPrefKey = 'SyncedDataAccessedNotification';
const String PasswordPreviewSizePrefKey = 'PasswordPreviewSize';

/* FUNCTIONS */
bool isTrue(dynamic value) {
  bool b = false;

  if (value != null) {
    if (value is bool) {
      b = value;
    } else if (value is String) {
      b = value.toString().toLowerCase() == 'true';
    } else if (value is int) {
      b = (value == 1);
    }
  }

  return b;
}

List<Secret> secretsListFromJsonString(String jsonBlob) {
  List<Secret> secretList;
  var decoded = jsonDecode(jsonBlob);

  try {
    var jsonList = decoded as List;
    secretList = jsonList != null
        ? jsonList.map((i) => Secret.fromJson(i)).toList()
        : null;
    // secretList = jsonList.map((i) => Secret.fromJson(i)).toList();
  } catch (e) {}
  if (secretList == null) {
    secretList = <Secret>[];
    var jsonMap = decoded as Map;
    jsonMap.forEach((k, v) => secretList.add(Secret.fromJson(v)));
  }

  return secretList;
}

//Future<void> showSnackBar(BuildContext context, String text) async {
//  await showSnackBar(context, text);
//  Scaffold.of(context)
//    ..removeCurrentSnackBar()
//    ..showSnackBar(SnackBar(content: Text(text)));
//}

void showSnackBar(GlobalKey<ScaffoldState> scaffoldKey, String text,
    {bool vibrate = true, int vibrateDuration = 5}) async {
  scaffoldKey.currentState.showSnackBar(
      SnackBar(content: Text(text), duration: Duration(milliseconds: 1000)));
  /*
  var hasVibrator = await Vibration.hasVibrator();
  if (vibrate && hasVibrator) {
    // if (Vibration.hasVibrator())
    Vibration.vibrate(duration: vibrateDuration);
  }
  */
}

String base64EncodeString(String input) => base64.encode(utf8.encode(input));

String base64DecodeString(String input) => utf8.decode(base64.decode(input));

String stringListToString(List<String> stringList) {
  var str = "[";

  stringList.forEach((s) {
    str = "$str\"$s\",";
  });

  if (stringList.length > 0) {
    str = str.substring(0, str.length - 1);
  }

  str = "$str]";
  return str;
}

/* TYPES */
typedef AsyncBoolCallback = Future<bool> Function();
