/*
 * Created by Ilan Rasekh on 2020/3/11
 * Copyright (c) 2020 Pseudorand Development. All rights reserved.
 */

import 'dart:convert';
import 'dart:io';

import 'package:nullpass/common.dart';
import 'package:nullpass/models/deviceSync.dart';
import 'package:nullpass/models/notification.dart';
import 'package:nullpass/models/secret.dart';
import 'package:nullpass/models/syncData.dart';
import 'package:nullpass/models/vault.dart';
import 'package:nullpass/services/datastore.dart';
import 'package:nullpass/services/logging.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:openpgp/openpgp.dart';

void defaultSyncInitHandshakeStepOneHandler(dynamic str) {
  Log.debug("in init handler placeholder");
  // as qr code handle sync init message from scanner
}

void defaultSyncInitHandshakeStepTwoHandler(dynamic str) {
  Log.debug("in init response handler placeholder");
  // as qr code respond to sync init response message from scanner
}

void defaultSyncInitHandshakeStepThreeHandler(dynamic str) {
  Log.debug("in init response handler placeholder");
  // as scanner respond to sync init message from qr code
}

void defaultSyncInitHandshakeStepFourHandler(dynamic str) {
  Log.debug("in init response handler placeholder");
  // as qr code respond to sync init response message from scanner
}

void defaultSyncDataHandler(String did, dynamic str) {
  Log.debug("in update handler placeholder");
  // received sync data to store
}

void defaultSyncDataResponseHandler(dynamic str) {
  Log.debug("in update response handler placeholder");
  // sync device successfully received the sync data and stored it
}

class NotificationManager {
  Future<String?> get deviceId async {
    return null;
  }

  Function(dynamic)? syncInitHandshakeStepOneHandler;
  Function(dynamic)? syncInitHandshakeStepTwoHandler;
  Function(dynamic)? syncInitHandshakeStepThreeHandler;
  Function(dynamic)? syncInitHandshakeStepFourHandler;
  Function(String?, dynamic)? syncDataHandler;
  Function(dynamic)? syncDataResponseHandler;

  Future<void> initialize({String? key}) async {}

  Future<void> sendMessageToAnotherDevice(
      {List<String?>? deviceIDs, Notification? message}) async {}

  void setDefaultNotificationHandlers() {}

  Future<void> setMessageReceivedHandler() async {}
}

class OneSignalNotificationManager implements NotificationManager {
  // OneSignal Attributes
  static String? _onesignalKey;
  static late OneSignal osInstance;
  static bool _initialized = false;
  String? _deviceId;
  Future<String?> get deviceId async {
    if (this._deviceId == null) {
      setDeviceId((await osInstance.getPermissionSubscriptionState())
          .subscriptionStatus
          .userId);
      Log.debug('device id: ${this._deviceId}\n');
    }
    return this._deviceId;
  }

  setDeviceId(String newDeviceId) {
    if (this._deviceId != null && newDeviceId == null) return;

    this._deviceId = newDeviceId;
    sharedPrefs!.setString(DeviceNotificationIdPrefKey, newDeviceId);
  }

  List<String?>? receivedDataChunks;

  // Handler functions
  @override
  Function(dynamic)? syncInitHandshakeStepOneHandler;
  @override
  Function(dynamic)? syncInitHandshakeStepTwoHandler;
  @override
  Function(dynamic)? syncInitHandshakeStepThreeHandler;
  @override
  Function(dynamic)? syncInitHandshakeStepFourHandler;
  @override
  Function(String?, dynamic)? syncDataHandler;
  @override
  Function(dynamic)? syncDataResponseHandler;

  OneSignalNotificationManager({required String key}) {
    if (key.isNotEmpty) {
      _onesignalKey = key;
    }
    setDefaultNotificationHandlers();
  }

  @override
  void setDefaultNotificationHandlers() {
    syncInitHandshakeStepOneHandler = defaultSyncInitHandshakeStepOneHandler;
    syncInitHandshakeStepTwoHandler = defaultSyncInitHandshakeStepTwoHandler;
    syncInitHandshakeStepThreeHandler =
        defaultSyncInitHandshakeStepThreeHandler;
    syncInitHandshakeStepFourHandler = defaultSyncInitHandshakeStepFourHandler;
    syncDataHandler = defaultSyncDataHandler;
  }

  @override
  Future<void> initialize({String? key}) async {
    if (_initialized) return;

    if (_onesignalKey!.isEmpty) {
      _onesignalKey = key;
    }

    osInstance = OneSignal.shared;

    // TODO: Remove this method to stop OneSignal Debugging
    if (isDebug) osInstance.setLogLevel(OSLogLevel.verbose, OSLogLevel.none);

    osInstance.init(_onesignalKey!, iOSSettings: {
      OSiOSSettings.autoPrompt: false,
      OSiOSSettings.inAppLaunchUrl: true
    });
    osInstance.setInFocusDisplayType(OSNotificationDisplayType.notification);

    if (Platform.isIOS) {
      var iosPermission =
          await osInstance.promptUserForPushNotificationPermission();
      Log.debug('Accepted permission: $iosPermission');
    }

    osInstance.setSubscriptionObserver((osSubscriptionState) {
      if (osSubscriptionState.to.userId != null) {
        setDeviceId(osSubscriptionState.to.userId);
        Log.debug('subscription state changed - id: ${this._deviceId}\n');
      }
    });

    var subscription = await osInstance.getPermissionSubscriptionState();
    if (subscription.subscriptionStatus.userId != null) {
      this._deviceId = subscription.subscriptionStatus.userId;
      Log.debug('device id: ${this._deviceId}\n');
    }

    if (syncInitHandshakeStepOneHandler == null ||
        syncInitHandshakeStepTwoHandler == null ||
        syncInitHandshakeStepThreeHandler == null ||
        syncDataHandler == null ||
        syncDataResponseHandler == null) setDefaultNotificationHandlers();

    setMessageReceivedHandler();

    _initialized = true;
  }

  @override
  Future<void> sendMessageToAnotherDevice(
      {List<String?>? deviceIDs, Notification? message}) async {
    var dataChunks = message!.toDataChunks();
    for (var data in dataChunks) {
      var currNote = OSCreateNotification.silentNotification(
        playerIds: deviceIDs as List<String>,
        additionalData: data as Map<String, dynamic>,
      );

      var response = await osInstance.postNotification(currNote);
      Log.debug(response);
    }
  }

  @override
  Future<void> setMessageReceivedHandler() async {
    osInstance
        .setNotificationReceivedHandler((OSNotification receivedNotification) {
      Log.debug("handling notification");
      Log.debug(receivedNotification.payload.additionalData);
      var tmpNotification =
          Notification.fromMap(receivedNotification.payload.additionalData);
      if (tmpNotification != null && haveReceivedAllChunks(tmpNotification)) {
        var dataString = combineChunks();
        var notificationDataString = base64DecodeString(dataString);

        // convert notificationDataString to map
        // var notificationData = jsonDecode(notificationDataString);

        Log.debug(notificationDataString);
        switch (tmpNotification.notificationType) {
          case NotificationType.SyncInitStepOne:
            receivedDataChunks = null;
            syncInitHandshakeStepOneHandler!(notificationDataString);
            break;
          case NotificationType.SyncInitStepTwo:
            receivedDataChunks = null;
            syncInitHandshakeStepTwoHandler!(notificationDataString);
            break;
          case NotificationType.SyncInitStepThree:
            receivedDataChunks = null;
            syncInitHandshakeStepThreeHandler!(notificationDataString);
            break;
          case NotificationType.SyncInitStepFour:
            receivedDataChunks = null;
            syncInitHandshakeStepFourHandler!(notificationDataString);
            break;
          case NotificationType.SyncUpdate:
            receivedDataChunks = null;
            syncDataHandler!(tmpNotification.deviceID, notificationDataString);
            break;
          case NotificationType.SyncUpdateResponse:
            receivedDataChunks = null;
            syncDataResponseHandler!(notificationDataString);
            break;
          default:
            break;
        }
      }

      return;
    });
  }

  bool haveReceivedAllChunks(Notification lastestChunk) {
    if (receivedDataChunks == null)
      receivedDataChunks = List<String>.filled(lastestChunk.parts ?? 0, "");

    receivedDataChunks![lastestChunk.position! - 1] = lastestChunk.data;
    for (var i = 0; i < receivedDataChunks!.length; i++) {
      if (receivedDataChunks![i] == null ||
          receivedDataChunks![i]!.isEmpty ||
          receivedDataChunks![i]!.trim().toLowerCase() == "null") {
        return false;
      }
    }

    return true;
  }

  String combineChunks() {
    var tmpStr = "";
    for (var i = 0; i < receivedDataChunks!.length; i++) {
      tmpStr = "$tmpStr${receivedDataChunks![i]}";
    }
    return tmpStr;
  }

  Future<void> defaultSyncDataHandler(String? senderID, dynamic data) async {
    Log.debug("in init sync data handler");
    Log.debug("recieved: $data");
    try {
      var db = NullPassDB.instance;
      var decryptedMsg = await OpenPGP.decrypt(
          data as String, (await db.getEncryptionPrivateKey())!, "");
      var syncDataMap = jsonDecode(decryptedMsg);
      var sd = SyncDataWrapper.fromMap(syncDataMap);

      // if (sd.generatedNonce == sd.receivedNonce) {}
      switch (sd.type) {
        case SyncType.VaultAdd:
          await _defaultVaultSyncAddHandler(senderID, sd.data as SyncVaultAdd);
          break;
        case SyncType.VaultUpdate:
          // TODO: add update if it's just the nickname that's being updated
          await _defaultVaultSyncUpdateHandler(
              senderID, sd.data as SyncVaultUpdate);
          break;
        case SyncType.VaultRemove:
          await _defaultVaultSyncRemoveHandler(
              senderID, sd.data as SyncVaultRemove);
          break;
        case SyncType.DataAdd:
          await _defaultDataSyncAddHandler(senderID, sd.data as SyncDataAdd);
          break;
        case SyncType.DataUpdate:
          await _defaultDataSyncUpdateHandler(
              senderID, sd.data as SyncDataUpdate);
          break;
        case SyncType.DataRemove:
          await _defaultDataSyncRemoveHandler(
              senderID, sd.data as SyncDataRemove);
          break;
        default:
          Log.debug(decryptedMsg);
          Log.debug(sd.toString());
          break;
      }
    } catch (e) {
      Log.debug(
        "an error occurred while trying to handle the sync data request ${e.toString()}",
      );
    }
  }

  Future<void> _defaultVaultSyncAddHandler(
      String? senderID, SyncVaultAdd svaData) async {
    var db = NullPassDB.instance;
    if (svaData.accessLevel != DeviceAccess.None) {
      var ds = DeviceSync(
          deviceID: senderID,
          vaultID: svaData.vaultId,
          vaultName: svaData.vaultName,
          vaultAccess: svaData.accessLevel,
          syncFromInternal: svaData.accessLevel == DeviceAccess.Manage,
          status: SyncStatus.Active);
      await db.insertSync(ds);

      if (svaData.accessLevel == DeviceAccess.ReadOnly ||
          svaData.accessLevel == DeviceAccess.Manage) {
        await db.insertVault(Vault(
          uid: svaData.vaultId,
          nickname: svaData.vaultName,
          manager: (svaData.accessLevel == DeviceAccess.Manage)
              ? VaultManager.Internal
              : VaultManager.External,
          managerId: senderID,
          isDefault: false,
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        ));
        await db.bulkInsertSecrets(svaData.secrets!);
      } else if (svaData.accessLevel == DeviceAccess.Backup) {
        var jsonSecretsStr = jsonEncode(svaData.secrets);
        var encryptedSecretData = await OpenPGP.encrypt(
            jsonSecretsStr, (await db.getEncryptionPublicKey())!);
        await db.storeSyncDataBackup(
            ds.id!, base64EncodeString(encryptedSecretData));
      }
    }
  }

  Future<void> _defaultVaultSyncUpdateHandler(
      String? senderID, SyncVaultUpdate svuData) async {
    var db = NullPassDB.instance;
    var ds = (await db.getSyncByDeviceAndVault(senderID, svuData.vaultId))!;
    if (ds.vaultAccess == svuData.accessLevel &&
        ds.vaultName == svuData.vaultName) return;
    // TODO: handle name change only as well
    if (svuData.accessLevel == DeviceAccess.None) {
      // delete the sync - TODO: add delete of backup data if applicable
      await db.deleteSyncOfVaultToDevice(senderID, svuData.vaultId);
      await db.deleteVault(svuData.vaultId);
    }

    if (ds.vaultAccess == DeviceAccess.Manage ||
        ds.vaultAccess == DeviceAccess.ReadOnly) {
      // update the sync access
      ds.syncFromInternal =
          (svuData.accessLevel == DeviceAccess.Manage) ?? false;
      ds.vaultAccess = svuData.accessLevel;
      ds.vaultName = svuData.vaultName;
      await db.updateSync(ds);

      // update the vault access if the new access is Manage or ReadOnly
      if (svuData.accessLevel == DeviceAccess.Manage ||
          svuData.accessLevel == DeviceAccess.ReadOnly) {
        var v = (await db.getVaultByID(ds.vaultID))!;
        v.manager = (svuData.accessLevel == DeviceAccess.Manage)
            ? VaultManager.Internal
            : VaultManager.External;
        v.managerId = (svuData.accessLevel == DeviceAccess.Manage)
            ? Vault.InternalSourceID
            : senderID;
        v.nickname = svuData.vaultName;
        await db.updateVault(v);
      } else if (svuData.accessLevel == DeviceAccess.Backup) {
        // update the vault access if the new access is Backup
        var secrets = await db.getAllSecretsInVault(ds.vaultID);
        var jsonSecretsStr = jsonEncode(secrets);
        var encryptedSecretData = await OpenPGP.encrypt(
            jsonSecretsStr, (await db.getEncryptionPublicKey())!);
        await db.storeSyncDataBackup(
            ds.id!, base64EncodeString(encryptedSecretData));
        await db.deleteVault(ds.vaultID);
      }
    } else if (ds.vaultAccess == DeviceAccess.Backup) {
      var encodedSyncDataBackup = (await db.fetchSyncDataBackup(ds.id!))!;
      var decryptedSecretData = await OpenPGP.decrypt(
        base64DecodeString(encodedSyncDataBackup),
        (await db.getEncryptionPrivateKey())!,
        "",
      );

      ds.vaultName = svuData.vaultName;
      ds.vaultAccess = svuData.accessLevel;

      var tmpList = jsonDecode(decryptedSecretData) ?? <Secret>[];
      var secretList = <Secret>[];
      (tmpList as List).forEach((i) => secretList.add(Secret.fromMap(i)));

      await db.insertVault(
        Vault(
          uid: svuData.vaultId,
          nickname: svuData.vaultName,
          manager: (svuData.accessLevel == DeviceAccess.Manage)
              ? VaultManager.Internal
              : VaultManager.External,
          managerId: senderID,
          isDefault: false,
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        ),
      );
      await db.bulkInsertSecrets(secretList);
      await db.updateSync(ds);
      await db.deleteSyncDataBackup(ds.id!);
    }
  }

  Future<void> _defaultVaultSyncRemoveHandler(
      String? senderID, SyncVaultRemove svrData) async {
    var db = NullPassDB.instance;
    await db.deleteSyncDataBackup(
        (await db.getSyncByDeviceAndVault(senderID, svrData.vaultId))!.id!);
    await db.deleteVault(svrData.vaultId);
    await db.deleteSyncOfVaultToDevice(senderID, svrData.vaultId);
  }

  Future<void> _defaultDataSyncAddHandler(
      String? senderID, SyncDataAdd svaData) async {
    var db = NullPassDB.instance;
    // make sure that the sync exists
    var ds = await db.getSyncByDeviceAndVault(senderID, svaData.vaultId);
    if (ds == null) {
      Log.debug(
        "The device sync did not exist implying that add data sync attempt should not proceed further",
      );
      return;
    }

    if (ds.vaultAccess != DeviceAccess.Backup) {
      await db.bulkInsertSecrets(svaData.secrets!);
    } else {
      // Otherwise get the backup data and update the data accordingly

      // Get Backup data
      var kp = (await db.getEncryptionKeyPair())!;
      var encodedSyncDataBackup = (await db.fetchSyncDataBackup(ds.id!))!;
      var decryptedSecretData = await OpenPGP.decrypt(
        base64DecodeString(encodedSyncDataBackup),
        kp.privateKey,
        "",
      );

      // Parse Data
      var tmpList = jsonDecode(decryptedSecretData) ?? <Secret>[];
      var secretList = <Secret>[];

      // Update Secret
      (tmpList as List).forEach((i) => secretList.add(Secret.fromMap(i)));

      // add all secrets who are in the data body
      for (var s in svaData.secrets!) {
        secretList.add(s);
      }

      // rewrite data
      var jsonSecretsStr = jsonEncode(secretList);
      var encryptedSecretData =
          await OpenPGP.encrypt(jsonSecretsStr, kp.publicKey);
      await db.storeSyncDataBackup(
          ds.id!, base64EncodeString(encryptedSecretData));
    }
  }

  Future<void> _defaultDataSyncUpdateHandler(
      String? senderID, SyncDataUpdate svuData) async {
    var db = NullPassDB.instance;
    // make sure that the sync exists
    var ds = await db.getSyncByDeviceAndVault(senderID, svuData.vaultId);
    if (ds == null) {
      Log.debug(
        "The device sync did not exist implying that update data sync attempt should not proceed further",
      );
      return;
    }

    // if the access is not backup then just add the secret
    if (ds.vaultAccess != DeviceAccess.Backup) {
      for (var s in svuData.secrets!) {
        await db.updateSecret(s);
      }
    } else {
      // Otherwise get the backup data and update the data accordingly

      // Setup map for easier updating of secret
      var secretMap = <String?, Secret>{};
      for (var s in svuData.secrets!) {
        secretMap[s.uuid] = s;
      }

      // Get Backup data
      var kp = (await db.getEncryptionKeyPair())!;
      var encodedSyncDataBackup = (await db.fetchSyncDataBackup(ds.id!))!;
      var decryptedSecretData = await OpenPGP.decrypt(
        base64DecodeString(encodedSyncDataBackup),
        kp.privateKey,
        "",
      );

      // Parse Data
      var tmpList = jsonDecode(decryptedSecretData) ?? <Secret>[];
      var secretList = <Secret?>[];

      // Update Secret
      (tmpList as List).forEach((i) {
        var s = Secret.fromMap(i);
        // if a secret is in the secretMap use that secret instead of the stored secret (i.e. update)
        if (secretMap.containsKey(s.uuid)) {
          secretList.add(secretMap[s.uuid]);
        } else {
          secretList.add(s);
        }
      });

      // rewrite data
      var jsonSecretsStr = jsonEncode(secretList);
      var encryptedSecretData =
          await OpenPGP.encrypt(jsonSecretsStr, kp.publicKey);
      await db.storeSyncDataBackup(
          ds.id!, base64EncodeString(encryptedSecretData));
    }
  }

  Future<void> _defaultDataSyncRemoveHandler(
      String? senderID, SyncDataRemove svrData) async {
    var db = NullPassDB.instance;
    // make sure that the sync exists
    var ds = await db.getSyncByDeviceAndVault(senderID, svrData.vaultId);
    if (ds == null) {
      Log.debug(
        "The device sync did not exist implying that delete data sync attempt should not proceed further",
      );
      return;
    }

    if (ds.vaultAccess != DeviceAccess.Backup) {
      for (var sID in svrData.secretIDs!) {
        await db.deleteSecret(sID!);
      }
    } else {
      // Otherwise get the backup data and update the data accordingly

      // Setup map for easier updating of secret
      var secretMap = <String?, bool>{};
      for (var s in svrData.secretIDs!) {
        secretMap[s] = true;
      }

      // Get Backup data
      var kp = (await db.getEncryptionKeyPair())!;
      var encodedSyncDataBackup = (await db.fetchSyncDataBackup(ds.id!))!;
      var decryptedSecretData = await OpenPGP.decrypt(
        base64DecodeString(encodedSyncDataBackup),
        kp.privateKey,
        "",
      );

      // Parse Data
      var tmpList = jsonDecode(decryptedSecretData) ?? <Secret>[];
      var secretList = <Secret>[];

      // Update Secret
      (tmpList as List).forEach((i) {
        var s = Secret.fromMap(i);

        // ignore any secrets who are in the secretMap (i.e. to be deleted)
        if (!secretMap.containsKey(s.uuid)) {
          secretList.add(s);
        }
      });

      // rewrite data
      var jsonSecretsStr = jsonEncode(secretList);
      var encryptedSecretData =
          await OpenPGP.encrypt(jsonSecretsStr, kp.publicKey);
      await db.storeSyncDataBackup(
          ds.id!, base64EncodeString(encryptedSecretData));
    }
  }
}
