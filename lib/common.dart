/*
 * Created by Ilan Rasekh on 2019/10/4
 * Copyright (c) 2019 Pseudorand Development. All rights reserved.
 */

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nullpass/models/secret.dart';
import 'package:nullpass/models/vault.dart';
import 'package:nullpass/services/datastore.dart';
import 'package:nullpass/services/encryption.dart';
import 'package:nullpass/services/notificationManager.dart' as np;
import 'package:nullpass/services/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:vibration/vibration.dart';

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

void setupSharedPreferences({Function encryptionKeyCallback}) {
  if (!sharedPrefs.containsKey(EncryptionKeyPairSetupPrefKey)) {
    Crypto.instance.then((instance) {
      if (instance.hasKeyPair) {
        sharedPrefs.setBool(EncryptionKeyPairSetupPrefKey, true).then((worked) {
          if (worked) {
            Log.debug('Added $EncryptionKeyPairSetupPrefKey');
            encryptionKeyCallback();
          }
        });
      }
    });
  } else {
    encryptionKeyCallback();
  }

  if (!sharedPrefs.containsKey(VaultsSetupPrefKey) ||
      !sharedPrefs.getBool(VaultsSetupPrefKey)) {
    var newV = Vault(
        nickname: "Personal",
        source: VaultSource.Internal,
        sourceId: "myDevice",
        isDefault: true);
    NullPassDB.instance.insertVault(newV).then((response) {
      sharedPrefs.setString(DefaultVaultIDPrefKey, newV.uid).then((worked) {
        if (worked) Log.debug('Default Vault ID Added Complete - ${newV.uid}');
      });
      sharedPrefs.setBool(VaultsSetupPrefKey, true).then((worked) {
        if (worked) Log.debug('Default Vault Setup Complete');
      });
    }).catchError((e) {
      sharedPrefs.setBool(VaultsSetupPrefKey, false).then((worked) {
        if (worked)
          Log.debug('There was a problem setting up the default Vault');
      });
    });
  }
  if (!sharedPrefs.containsKey(SecretLengthPrefKey))
    sharedPrefs.setInt(SecretLengthPrefKey, 512).then((worked) {
      if (worked) Log.debug('Added $SecretLengthPrefKey');
    });

  if (!sharedPrefs.containsKey(AlphaCharactersPrefKey))
    sharedPrefs.setBool(AlphaCharactersPrefKey, true).then((worked) {
      if (worked) Log.debug('Added $AlphaCharactersPrefKey');
    });

  if (!sharedPrefs.containsKey(NumericCharactersPrefKey))
    sharedPrefs.setBool(NumericCharactersPrefKey, true).then((worked) {
      if (worked) Log.debug('Added $NumericCharactersPrefKey');
    });

  if (!sharedPrefs.containsKey(SymbolCharactersPrefKey))
    sharedPrefs.setBool(SymbolCharactersPrefKey, true).then((worked) {
      if (worked) Log.debug('Added $SymbolCharactersPrefKey');
    });

  if (!sharedPrefs.containsKey(InAppWebpagesPrefKey))
    sharedPrefs.setBool(InAppWebpagesPrefKey, true).then((worked) {
      if (worked) Log.debug('Added $InAppWebpagesPrefKey');
    });

  if (!sharedPrefs.containsKey(SharedPrefSetupKey))
    sharedPrefs.setBool(SharedPrefSetupKey, true).then((worked) {
      if (worked) Log.debug('Shared Preference Setup Complete');
    });
}

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

enum NullPassRoute {
  ViewSecretsList,
  FindSecret,
  NewSecret,
  GenerateSecret,
  ManageVault,
  QrCode,
  QrScanner,
  ManageDevices,
  Settings,
  HelpAndFeedback
}

Future<void> setupNotifications() async {
  notify = np.OneSignalNotificationManager(key: OneSignalKey);
  await notify.initialize();
}

String base64EncodeString(String input) => base64.encode(utf8.encode(input));

String base64DecodeString(String input) => utf8.decode(base64.decode(input));
