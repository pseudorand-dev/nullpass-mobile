/*
 * Created by Ilan Rasekh on 2020/02/28
 * Copyright (c) 2020 Pseudorand Development. All rights reserved.
 */

import 'dart:io';
import 'package:nullpass/services/logging.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class Notification {
  Future<void> initialize({String key}) async {}

  Future<void> sendMessageToAnotherDevice(
      {String deviceID, String message}) async {}
}

class OneSignalNotification implements Notification {
  static String _onesignalKey;

  OneSignalNotification({String key}) {
    if (key.isNotEmpty) {
      _onesignalKey = key;
    }
  }

  @override
  Future<void> initialize({String key}) async {
    if (_onesignalKey.isEmpty) {
      _onesignalKey = key;
    }

    OneSignal.shared.init(_onesignalKey, iOSSettings: {
      OSiOSSettings.autoPrompt: false,
      OSiOSSettings.inAppLaunchUrl: true
    });
    OneSignal.shared
        .setInFocusDisplayType(OSNotificationDisplayType.notification);

    if (Platform.isIOS) {
      OneSignal.shared
          .promptUserForPushNotificationPermission()
          .then((accepted) {
        Log.debug('Accepted permission: $accepted');
      });
    }

    OneSignal.shared.getPermissionSubscriptionState().then((status) {
      var playerId = status.subscriptionStatus.userId;
      Log.debug('device id: $playerId\n');
    });
  }

  @override
  Future<void> sendMessageToAnotherDevice(
      {String deviceID, String message}) async {}
}
