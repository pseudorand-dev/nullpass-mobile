/*
 * Created by Ilan Rasekh on 2020/4/5
 * Copyright (c) 2020 Pseudorand Development. All rights reserved.
 */

import 'package:nullpass/common.dart';
import 'package:nullpass/models/deviceSync.dart';
import 'package:nullpass/models/notification.dart';
import 'package:nullpass/models/secret.dart';
import 'package:nullpass/models/syncData.dart';
import 'package:nullpass/services/datastore.dart';
import 'package:openpgp/openpgp.dart';
import 'package:uuid/uuid.dart';

class Sync {
  Sync._privateConstructor();
  static final Sync instance = Sync._privateConstructor();

  NullPassDB db = NullPassDB.instance;

  Future<Notification> _setupNotification(
      String encKey, NotificationType nt, dynamic nd) async {
    if (nt != null && nd != null && encKey != null && encKey.isNotEmpty) {
      var encryptedMsg = await OpenPGP.encrypt(nd.toString(), encKey);
      return Notification(
        nt,
        data: encryptedMsg,
        deviceID: notify.deviceId,
        notificationID: Uuid().v4(),
      );
    }
    return null;
  }

  Future<void> sendSecretAdded(Secret s) async {
    for (var vid in s.vaults) {
      // List<DeviceSync> dsL = db.getAllSyncsForAVault();
      var dsL = await db.getAllSyncsForAVault(vid) ?? <DeviceSync>[];
      // for each dsl send an added secret notification
      for (var ds in dsL) {
        var d = await db.getDeviceBySyncID(ds.deviceID);
        var note = await _setupNotification(
          d.encryptionKey,
          NotificationType.SyncUpdate,
          SyncDataWrapper(
              type: SyncType.DataAdd,
              data: SyncDataAdd(vaultId: vid, secrets: <Secret>[s])),
        );

        await notify.sendMessageToAnotherDevice(
            deviceIDs: <String>[ds.deviceID], message: note);
      }
    }
    return true;
  }

  Future<void> sendSecretUpdated(Secret s) async {
    for (var vid in s.vaults) {
      // List<DeviceSync> dsL = db.getAllSyncsForAVault();
      var dsL = await db.getAllSyncsForAVault(vid) ?? <DeviceSync>[];
      // for each dsl send an added secret notification
      for (var ds in dsL) {
        var d = await db.getDeviceBySyncID(ds.deviceID);
        var note = await _setupNotification(
          d.encryptionKey,
          NotificationType.SyncUpdate,
          SyncDataWrapper(
              type: SyncType.DataUpdate,
              data: SyncDataUpdate(vaultId: vid, secrets: <Secret>[s])),
        );

        await notify.sendMessageToAnotherDevice(
            deviceIDs: <String>[ds.deviceID], message: note);
      }
    }
    return true;
  }

  Future<void> sendSecretDeleted(Secret s) async {
    for (var vid in s.vaults) {
      // List<DeviceSync> dsL = db.getAllSyncsForAVault();
      var dsL = await db.getAllSyncsForAVault(vid) ?? <DeviceSync>[];
      // for each dsl send an added secret notification
      for (var ds in dsL) {
        var d = await db.getDeviceBySyncID(ds.deviceID);
        var note = await _setupNotification(
          d.encryptionKey,
          NotificationType.SyncUpdate,
          SyncDataWrapper(
              type: SyncType.DataRemove,
              data: SyncDataRemove(vaultId: vid, secretIDs: <String>[s.uuid])),
        );

        await notify.sendMessageToAnotherDevice(
            deviceIDs: <String>[ds.deviceID], message: note);
      }
    }
    return true;
  }
}
