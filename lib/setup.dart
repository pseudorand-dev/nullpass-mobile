/*
 * Created by Ilan Rasekh on 2020/4/19
 * Copyright (c) 2020 Pseudorand Development. All rights reserved.
 */

import 'package:nullpass/common.dart';
import 'package:nullpass/models/auditRecord.dart';
import 'package:nullpass/services/datastore.dart';
import 'package:nullpass/services/encryption.dart';
import 'package:nullpass/services/logging.dart';
import 'package:nullpass/services/notificationManager.dart' as np;

void setupSharedPreferences({Function encryptionKeyCallback}) {
  if (!sharedPrefs.containsKey(EncryptionKeyPairSetupPrefKey)) {
    Crypto.instance.then((instance) {
      if (instance.hasKeyPair) {
        sharedPrefs.setBool(EncryptionKeyPairSetupPrefKey, true).then((worked) {
          if (worked) {
            Log.debug('Added $EncryptionKeyPairSetupPrefKey');
            _logSetup("The device encryption key was setup");
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
    NullPassDB.instance.createDefaultVault().then((newV) {
      if (newV != null) {
        sharedPrefs.setString(DefaultVaultIDPrefKey, newV.uid).then((worked) {
          if (worked)
            Log.debug('Default Vault ID Added Complete - ${newV.uid}');
        });
        sharedPrefs.setBool(VaultsSetupPrefKey, true).then((worked) {
          if (worked) Log.debug('Default Vault Setup Complete');
          _logSetup("The device default vault was setup");
        });
      }
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

  if (!sharedPrefs.containsKey(SyncdDataNotificationsPrefKey))
    sharedPrefs.setBool(SyncdDataNotificationsPrefKey, true).then((worked) {
      if (worked) Log.debug('Added $SyncdDataNotificationsPrefKey');
    });

  if (!sharedPrefs.containsKey(PasswordPreviewSizePrefKey))
    sharedPrefs.setInt(PasswordPreviewSizePrefKey, 20).then((worked) {
      if (worked) Log.debug('Added $PasswordPreviewSizePrefKey');
    });

  if (!sharedPrefs.containsKey(SharedPrefSetupKey))
    sharedPrefs.setBool(SharedPrefSetupKey, true).then((worked) {
      if (worked) Log.debug('Shared Preference Setup Complete');
      _logSetup("The device setup was completed");
    });
}

Future<String> setupNotifications() async {
  notify = np.OneSignalNotificationManager(key: OneSignalKey);
  await notify.initialize();
  _logSetup("The device notification management was setup");
  return notify.deviceId;
}

Future<void> _logSetup(String msg) async {
  await NullPassDB.instance.addAuditRecord(
    AuditRecord(
      type: AuditType.AppSetup,
      message: msg,
      date: DateTime.now().toUtc(),
    ),
  );
}
