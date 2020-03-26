/*
 * Created by Ilan Rasekh on 2020/3/11
 * Copyright (c) 2020 Pseudorand Development. All rights reserved.
 */

import 'dart:io';
import 'package:nullpass/services/logging.dart';
import 'package:nullpass/services/notification.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

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

void defaultSyncDataHandler(dynamic str) {
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
  Function(dynamic) syncDataHandler;
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
  Function(dynamic) syncDataHandler;
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
    var currNote = OSCreateNotification.silentNotification(
      // var currNote = OSCreateNotification(
      playerIds: deviceIDs,
      additionalData: message.toMap(),
      // contentAvailable: true,
    );

    var response = await osInstance.postNotification(currNote);
    Log.debug(response);
  }

  @override
  Future<void> setMessageReceivedHandler() async {
    osInstance
        .setNotificationReceivedHandler((OSNotification receivedNotification) {
      Log.debug("handling notification");
      Log.debug(receivedNotification.payload.additionalData);
      var tmpNotification =
          Notification.fromMap(receivedNotification.payload.additionalData);
      // Notification.fromJson(receivedNotification.payload.body);
      Log.debug(tmpNotification.data);
      switch (tmpNotification.notificationType) {
        case NotificationType.SyncInitStepOne:
          syncInitHandshakeStepOneHandler(tmpNotification.data);
          break;
        case NotificationType.SyncInitStepTwo:
          syncInitHandshakeStepTwoHandler(tmpNotification.data);
          break;
        case NotificationType.SyncInitStepThree:
          syncInitHandshakeStepThreeHandler(tmpNotification.data);
          break;
        case NotificationType.SyncUpdate:
          syncDataHandler(tmpNotification.data);
          break;
        case NotificationType.SyncUpdateReceived:
          syncDataResponseHandler(tmpNotification.data);
          break;
        default:
          break;
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
}
