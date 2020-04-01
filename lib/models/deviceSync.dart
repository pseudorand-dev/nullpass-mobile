/*
 * Created by Ilan Rasekh on 2020/3/12
 * Copyright (c) 2020 Pseudorand Development. All rights reserved.
 */

import 'package:flutter/foundation.dart';
import 'package:nullpass/services/logging.dart';
import 'package:uuid/uuid.dart';
import 'package:validators/validators.dart';

final String syncTableName = 'device_sync';
final String columnSyncId = "_id";
final String columnSyncDeviceId = "device_id";
final String columnSyncDeviceConnectionId = "device_sync_id";
// does this record represent a sync from our device to another device
final String columnSyncFrom = "sync_from";
final String columnSyncVaultId = "vault_id";
final String columnSyncVaultName = "vault_name";
final String columnSyncVaultAccess = "vault_access";
// device type info (macos / ios / android / chrome / etc.)
final String columnSyncNotes = "notes";
final String columnSyncCreated = "created_at";
final String columnSyncModified = "modified_at";
final String columnSyncLastPerformed = "last_synced";

enum DeviceAccess { None, Backup, ReadOnly, Manage }

String deviceAccessToString(DeviceAccess da) =>
    da.toString().substring(da.toString().lastIndexOf(".") + 1);

DeviceAccess parseDeviceAccessFromString(String dAccess) {
  var ret = DeviceAccess.None;
  try {
    ret = DeviceAccess.values.firstWhere((da) =>
        da
            .toString()
            .toLowerCase()
            .substring(da.toString().lastIndexOf(".") + 1) ==
        dAccess.toLowerCase());
  } catch (e) {
    Log.debug(
        "An error occurred while trying to translate string to NotificationType: ${e.toString()}");
    // throw new Exception("Unknown DeviceAccess");
  }
  return ret;
}

List<String> deviceAccessStringList() {
  var daList = <String>[];
  DeviceAccess.values.forEach((da) => daList.add(deviceAccessToString(da)));
  return daList;
}

class DeviceSync {
  String id;
  String deviceID;
  String deviceSyncID;
  bool syncFrom;
  String vaultID;
  String vaultName;
  DeviceAccess vaultAccess;
  String notes;
  DateTime created;
  DateTime lastModified;
  DateTime lastSync;

  factory DeviceSync.fromJson(Map<String, dynamic> json) =>
      DeviceSync.deviceFromJson(json);

  DeviceSync({
    String id,
    @required String deviceID,
    String deviceSyncID,
    @required bool syncFrom,
    @required String vaultID,
    @required String vaultName,
    @required DeviceAccess vaultAccess,
    String notes,
    DateTime created,
    DateTime lastModified,
    DateTime lastSync,
  }) {
    if (id == null || id.trim() == '' || !isUUID(id, 4)) {
      id = (new Uuid()).v4();
    }

    DateTime now = DateTime.now().toUtc();

    this.id = id;
    this.deviceID = deviceID;
    this.deviceSyncID = deviceSyncID;
    this.syncFrom = syncFrom;
    this.vaultID = vaultID;
    this.vaultName = vaultName;
    this.vaultAccess = vaultAccess ?? DeviceAccess.None;
    this.notes = notes;
    this.created = created ?? now;
    this.lastModified = lastModified ?? now;
    this.lastSync = lastSync ?? now;
  }

  Map<String, dynamic> toMap() => {
        columnSyncId: this.id,
        columnSyncDeviceId: this.deviceID,
        columnSyncDeviceConnectionId: this.deviceSyncID,
        columnSyncFrom: this.syncFrom,
        columnSyncVaultId: this.vaultID,
        columnSyncVaultName: this.vaultName,
        columnSyncVaultAccess: deviceAccessToString(this.vaultAccess),
        columnSyncNotes: this.notes,
        columnSyncCreated: (this.created != null)
            ? this.created.toIso8601String()
            : DateTime.now().toUtc().toIso8601String(),
        columnSyncModified: (this.lastModified != null)
            ? this.lastModified.toIso8601String()
            : DateTime.now().toUtc().toIso8601String(),
        columnSyncLastPerformed: (this.lastSync != null)
            ? this.lastSync.toIso8601String()
            : DateTime.now().toUtc().toIso8601String(),
      };

  static DeviceSync fromMap(Map input) {
    try {
      var newDevice = DeviceSync(
        id: input[columnSyncId],
        deviceID: input[columnSyncDeviceId],
        deviceSyncID: input[columnSyncDeviceConnectionId],
        syncFrom: input[columnSyncFrom],
        vaultID: input[columnSyncVaultId],
        vaultName: input[columnSyncVaultName],
        vaultAccess: parseDeviceAccessFromString(input[columnSyncVaultAccess]),
        notes: input[columnSyncNotes],
        created: DateTime.tryParse(input[columnSyncCreated]),
        lastModified: DateTime.tryParse(input[columnSyncModified]),
        lastSync: DateTime.tryParse(input[columnSyncLastPerformed]),
      );
      return newDevice;
    } catch (e) {
      Log.debug("error creating sync record from map: ${e.toString()}");
      throw e;
    }
  }

  Map<String, dynamic> toJson() => {
        columnSyncId: this.id,
        columnSyncDeviceId: this.deviceID,
        columnSyncDeviceConnectionId: this.deviceSyncID,
        columnSyncFrom: this.syncFrom,
        columnSyncVaultId: this.vaultID,
        columnSyncVaultName: this.vaultName,
        columnSyncVaultAccess: deviceAccessToString(this.vaultAccess),
        columnSyncNotes: this.notes,
        columnSyncCreated: (this.created != null)
            ? this.created.toIso8601String()
            : DateTime.now().toUtc().toIso8601String(),
        columnSyncModified: (this.lastModified != null)
            ? this.lastModified.toIso8601String()
            : DateTime.now().toUtc().toIso8601String(),
        columnSyncLastPerformed: (this.lastSync != null)
            ? this.lastSync.toIso8601String()
            : DateTime.now().toUtc().toIso8601String(),
      };

  static DeviceSync deviceFromJson(Map<String, dynamic> jsonBlob) {
    try {
      var newDevice = DeviceSync(
        id: jsonBlob[columnSyncId],
        deviceID: jsonBlob[columnSyncDeviceId],
        deviceSyncID: jsonBlob[columnSyncDeviceConnectionId],
        syncFrom: jsonBlob[columnSyncFrom],
        vaultID: jsonBlob[columnSyncVaultId],
        vaultName: jsonBlob[columnSyncVaultName],
        vaultAccess:
            parseDeviceAccessFromString(jsonBlob[columnSyncVaultAccess]),
        notes: jsonBlob[columnSyncNotes],
        created: DateTime.tryParse(jsonBlob[columnSyncCreated]),
        lastModified: DateTime.tryParse(jsonBlob[columnSyncModified]),
        lastSync: DateTime.tryParse(jsonBlob[columnSyncLastPerformed]),
      );
      return newDevice;
    } catch (e) {
      Log.debug("error creating sync record from json: ${e.toString()}");
      throw e;
    }
  }
}
