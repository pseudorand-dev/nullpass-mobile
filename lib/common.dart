/*
 * Created by Ilan Rasekh on 2019/10/4
 * Copyright (c) 2019 Pseudorand Development. All rights reserved.
 */

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nullpass/services/notification.dart' as Np;
import 'package:nullpass/secret.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:vibration/vibration.dart';

// TODO: Determine a better way to handle the OneSignal Key
const String OneSignalKey = "<THIS_NEEDS_TO_BE_ADDED_BEFORE_COMPILATION>";

// A common variable for the internal notification system
Np.Notification notify;

SharedPreferences sharedPrefs;
const String SecretLengthPrefKey = 'SecretLength';
const String AlphaCharactersPrefKey = 'AlphaCharacters';
const String NumericCharactersPrefKey = 'NumericCharacters';
const String SymbolCharactersPrefKey = 'SymbolCharacters';
const String SharedPrefSetupKey = 'SpSetup';
const String InAppWebpagesPrefKey = 'InAppWebpages';

void setupSharedPreferences() {
  if (!sharedPrefs.containsKey(SecretLengthPrefKey))
    sharedPrefs.setInt(SecretLengthPrefKey, 512).then((worked) {
      if (worked) print('Added $SecretLengthPrefKey');
    });

  if (!sharedPrefs.containsKey(AlphaCharactersPrefKey))
    sharedPrefs.setBool(AlphaCharactersPrefKey, true).then((worked) {
      if (worked) print('Added $AlphaCharactersPrefKey');
    });

  if (!sharedPrefs.containsKey(NumericCharactersPrefKey))
    sharedPrefs.setBool(NumericCharactersPrefKey, true).then((worked) {
      if (worked) print('Added $NumericCharactersPrefKey');
    });

  if (!sharedPrefs.containsKey(SymbolCharactersPrefKey))
    sharedPrefs.setBool(SymbolCharactersPrefKey, true).then((worked) {
      if (worked) print('Added $SymbolCharactersPrefKey');
    });

  if (!sharedPrefs.containsKey(InAppWebpagesPrefKey))
    sharedPrefs.setBool(InAppWebpagesPrefKey, true).then((worked) {
      if (worked) print('Added $InAppWebpagesPrefKey');
    });

  if (!sharedPrefs.containsKey(SharedPrefSetupKey))
    sharedPrefs.setBool(SharedPrefSetupKey, true).then((worked) {
      if (worked) print('Shared Preference Setup Complete');
    });
}

bool isTrue(dynamic value) {
  bool b = false;

  if (value != null) {
    b = value.toString().toLowerCase() == 'true';
  }

  return b;
}

List<Secret> SecretsListFromJsonString(String jsonBlob) {
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

enum NullPassRoute {
  ViewSecretsList,
  FindSecret,
  NewSecret,
  GenerateSecret,
  QrCode,
  RegisterDevice,
  ManageDevices,
  Settings,
  HelpAndFeedback
}

Future<void> setupNotifications() async {
  notify = Np.OneSignalNotification(key: OneSignalKey);
  await notify.initialize();
}
