/*
 * Created by Ilan Rasekh on 2020/3/11
 * Copyright (c) 2020 Pseudorand Development. All rights reserved.
 */

import 'dart:convert';
import 'dart:io';

import 'package:nullpass/common.dart';
import 'package:nullpass/models/deviceSync.dart';
import 'package:nullpass/models/notification.dart';
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
  String deviceId;
  Function(dynamic) syncInitHandshakeStepOneHandler;
  Function(dynamic) syncInitHandshakeStepTwoHandler;
  Function(dynamic) syncInitHandshakeStepThreeHandler;
  Function(dynamic) syncInitHandshakeStepFourHandler;
  Function(String, dynamic) syncDataHandler;
  Function(dynamic) syncDataResponseHandler;

  Future<void> initialize({String key}) async {}

  Future<void> sendMessageToAnotherDevice(
      {List<String> deviceIDs, Notification message}) async {}

  void setDefaultNotificationHandlers() {}

  Future<void> setMessageReceivedHandler() async {}
}

class OneSignalNotificationManager implements NotificationManager {
  // OneSignal Attributes
  static String _onesignalKey;
  static OneSignal osInstance;
  static bool _initialized = false;
  String deviceId;

  List<String> receivedDataChunks;

  // Handler functions
  @override
  Function(dynamic) syncInitHandshakeStepOneHandler;
  @override
  Function(dynamic) syncInitHandshakeStepTwoHandler;
  @override
  Function(dynamic) syncInitHandshakeStepThreeHandler;
  @override
  Function(dynamic) syncInitHandshakeStepFourHandler;
  @override
  Function(String, dynamic) syncDataHandler;
  @override
  Function(dynamic) syncDataResponseHandler;

  OneSignalNotificationManager({String key}) {
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
  Future<void> initialize({String key}) async {
    if (_initialized) return;

    if (_onesignalKey.isEmpty) {
      _onesignalKey = key;
    }

    osInstance = OneSignal.shared;

    osInstance.init(_onesignalKey, iOSSettings: {
      OSiOSSettings.autoPrompt: false,
      OSiOSSettings.inAppLaunchUrl: true
    });
    osInstance.setInFocusDisplayType(OSNotificationDisplayType.notification);

    if (Platform.isIOS) {
      osInstance.promptUserForPushNotificationPermission().then((accepted) {
        Log.debug('Accepted permission: $accepted');
      });
    }

    osInstance.getPermissionSubscriptionState().then((status) {
      var playerId = status.subscriptionStatus.userId;
      deviceId = playerId;
      Log.debug('device id: $playerId\n');
    });

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
      {List<String> deviceIDs, Notification message}) async {
    var dataChunks = message.toDataChunks();
    for (var data in dataChunks) {
      var currNote = OSCreateNotification.silentNotification(
        playerIds: deviceIDs,
        additionalData: data,
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
      if (haveReceivedAllChunks(tmpNotification)) {
        var dataString = combineChunks();
        var notificationDataString = base64DecodeString(dataString);

        // convert notificationDataString to map
        // var notificationData = jsonDecode(notificationDataString);

        Log.debug(notificationDataString);
        switch (tmpNotification.notificationType) {
          case NotificationType.SyncInitStepOne:
            receivedDataChunks = null;
            syncInitHandshakeStepOneHandler(notificationDataString);
            break;
          case NotificationType.SyncInitStepTwo:
            receivedDataChunks = null;
            syncInitHandshakeStepTwoHandler(notificationDataString);
            break;
          case NotificationType.SyncInitStepThree:
            receivedDataChunks = null;
            syncInitHandshakeStepThreeHandler(notificationDataString);
            break;
          case NotificationType.SyncInitStepFour:
            receivedDataChunks = null;
            syncInitHandshakeStepFourHandler(notificationDataString);
            break;
          case NotificationType.SyncUpdate:
            receivedDataChunks = null;
            syncDataHandler(tmpNotification.deviceID, notificationDataString);
            break;
          case NotificationType.SyncUpdateReceived:
            receivedDataChunks = null;
            syncDataResponseHandler(tmpNotification.data);
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
      receivedDataChunks = List<String>(lastestChunk.parts);

    receivedDataChunks[lastestChunk.position - 1] = lastestChunk.data;
    for (var i = 0; i < receivedDataChunks.length; i++) {
      if (receivedDataChunks[i] == null ||
          receivedDataChunks[i].isEmpty ||
          receivedDataChunks[i].trim().toLowerCase() == "null") {
        return false;
      }
    }

    return true;
  }

  String combineChunks() {
    var tmpStr = "";
    for (var i = 0; i < receivedDataChunks.length; i++) {
      tmpStr = "$tmpStr${receivedDataChunks[i]}";
    }
    return tmpStr;
  }

  Future<void> defaultSyncDataHandler(String senderID, dynamic data) async {
    Log.debug("in init sync data handler");
    Log.debug("recieved: $data");
    try {
      var privateKey = await NullPassDB.instance.getEncryptionPrivateKey();
      var decryptedMsg = await OpenPGP.decrypt(data as String, privateKey, "");
      var syncDataMap = jsonDecode(decryptedMsg);
      var sd = SyncDataWrapper.fromMap(syncDataMap);

      // if (sd.generatedNonce == sd.receivedNonce) {}
      switch (sd.type) {
        case SyncType.VaultAdd:
          var svaData = sd.data as SyncVaultAdd;
          if (svaData.accessLevel != DeviceAccess.None) {
            var ds = DeviceSync(
                deviceID: senderID,
                vaultID: svaData.vaultId,
                vaultName: svaData.vaultName,
                vaultAccess: svaData.accessLevel,
                syncFromInternal: svaData.accessLevel == DeviceAccess.Manage,
                status: SyncStatus.Active);
            await NullPassDB.instance.insertSync(ds);
            await NullPassDB.instance.insertVault(Vault(
              uid: svaData.vaultId,
              nickname: svaData.vaultName,
              manager: VaultManager.External,
              managerId: senderID,
              isDefault: false,
              createdAt: DateTime.now(),
              modifiedAt: DateTime.now(),
            ));
            await NullPassDB.instance.bulkInsertSecrets(svaData.secrets);
          }
          break;
        case SyncType.VaultRemove:
          var svrData = sd.data as SyncVaultRemove;
          await NullPassDB.instance
              .deleteSyncOfVaultToDevice(senderID, svrData.vaultId);
          await NullPassDB.instance.deleteVault(svrData.vaultId);
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
}
