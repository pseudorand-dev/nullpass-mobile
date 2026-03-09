/*
 * Created by Ilan Rasekh on 2019/10/4
 * Copyright (c) 2019 Pseudorand Development. All rights reserved.
 */

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nullpass/models/secret.dart';
import 'package:nullpass/services/notificationManager.dart' as np;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

/* VARIABLES */
// TODO: Add your actual OneSignal App ID before building
// Get it from: https://dashboard.onesignal.com/ -> Your App -> Settings -> Keys & IDs
// Note: OneSignal v5.x has breaking changes - may need to update initialization in setup.dart
const String OneSignalKey = "<YOUR_ONESIGNAL_APP_ID_HERE>";

// A common variable for the internal notification system
late np.NotificationManager notify;

late SharedPreferences sharedPrefs;
const String AuthOnLoadPrefKey = 'AuthenticateOnAppLoad';
const String AuthTimeoutSecondsPrefKey = 'AutenticationTimeoutSeconds';
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
const String DeviceNotificationIdPrefKey = 'DeviceNotificationIdPrefKey';

bool canCheckBiometrics = false;

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
  List<Secret>? secretList;
  var decoded = jsonDecode(jsonBlob);

  try {
    var jsonList = decoded as List;
    secretList = jsonList.map((i) => Secret.fromJson(i)).toList();
  } catch (e) {
    secretList = null;
  }
  if (secretList == null) {
    secretList = <Secret>[];
    var jsonMap = decoded as Map;
    jsonMap.forEach((k, v) => secretList!.add(Secret.fromJson(v)));
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
  final messenger = ScaffoldMessenger.of(scaffoldKey.currentContext!);
  messenger.showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(milliseconds: 1000)));
  var hasVibrator = await Vibration.hasVibrator();
  if (vibrate && hasVibrator) {
    // if (Vibration.hasVibrator())
    Vibration.vibrate(duration: vibrateDuration);
  }
}

String base64EncodeString(String input) => base64.encode(utf8.encode(input));

String base64DecodeString(String input) => utf8.decode(base64.decode(input));

String stringListToString(List<String> stringList) {
  var str = "[";

  for (var s in stringList) {
    str = "$str\"$s\",";
  }

  if (stringList.isNotEmpty) {
    str = str.substring(0, str.length - 1);
  }

  str = "$str]";
  return str;
}

/* TYPES */
typedef AsyncBoolCallback = Future<bool> Function();
