/*
 * Created by Ilan Rasekh on 2020/3/12
 * Copyright (c) 2020 Pseudorand Development. All rights reserved.
 */

import 'package:flutter/foundation.dart';
import 'package:nullpass/common.dart';
import 'package:nullpass/services/logging.dart';
import 'package:uuid/uuid.dart';
import 'package:validators/validators.dart';

final String syncTableName = 'device_sync';
final String columnSyncId = "_id";
final String columnSyncDeviceId = "device_id";
final String columnSyncDeviceConnectionId = "device_sync_id";
// does this record represent a sync from our device to another device
final String columnSyncFromInternal = "sync_from_internal";
final String columnSyncVaultId = "vault_id";
final String columnSyncVaultName = "vault_name";
final String columnSyncVaultAccess = "vault_access";
final String columnSyncStatus = "status";
// device type info (macos / ios / android / chrome / etc.)
final String columnSyncNotes = "notes";
final String columnSyncCreated = "created_at";
final String columnSyncModified = "modified_at";
final String columnSyncLastPerformed = "last_synced";

class DeviceAccess {
  static const DeviceAccess None = DeviceAccess._("None");
  static const DeviceAccess Backup = DeviceAccess._("Backup");
  static const DeviceAccess ReadOnly = DeviceAccess._("Read-Only");
  static const DeviceAccess Manage = DeviceAccess._("Manage");

  static const List<String> values = <String>[
    "None",
    "Backup",
    "Read-Only",
    "Manage"
  ];

  final String _name;
  const DeviceAccess._(this._name);

  static dynamic fromString(String deviceAccess) {
    if (values.contains(deviceAccess) ||
        values.contains(deviceAccess.replaceAll("-", "")))
      return DeviceAccess._(deviceAccess);
    else
      return DeviceAccess.None;
  }

  @override
  String toString() {
    return _name;
  }

  @override
  bool operator ==(dynamic other) {
    if (other is DeviceAccess && this._name == other._name) {
      return true;
    }
    return false;
  }
}

enum SyncStatus { Unknown, Creating, Active, Syncing, Deleting }

String syncStatusToString(SyncStatus status) =>
    status.toString().substring(status.toString().lastIndexOf(".") + 1);

SyncStatus parseSyncStatusFromString(String status) {
  var syncStatus = SyncStatus.Unknown;
  try {
    syncStatus = SyncStatus.values.firstWhere((ss) =>
        ss
            .toString()
            .toLowerCase()
            .substring(ss.toString().lastIndexOf(".") + 1) ==
        status.toLowerCase());
  } catch (e) {
    Log.debug(
      "An error occurred while trying to translate string to a SyncStatus: ${e.toString()}",
    );
  }
  return syncStatus;
}

class DeviceSync {
  String id;
  String deviceID;
  String deviceSyncID;
  bool syncFromInternal;
  String vaultID;
  String vaultName;
  DeviceAccess vaultAccess;
  String notes;
  SyncStatus status;
  DateTime created;
  DateTime lastModified;
  DateTime lastSync;

  factory DeviceSync.fromJson(Map<String, dynamic> json) =>
      DeviceSync.deviceFromJson(json);

  DeviceSync({
    String id,
    @required String deviceID,
    String deviceSyncID,
    @required bool syncFromInternal,
    @required String vaultID,
    @required String vaultName,
    @required DeviceAccess vaultAccess,
    SyncStatus status,
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
    this.syncFromInternal = syncFromInternal != null
        ? isTrue(syncFromInternal)
        : (throw ArgumentError.notNull("syncFromInternal"));
    this.vaultID = vaultID;
    this.vaultName = vaultName;
    this.vaultAccess = vaultAccess ?? DeviceAccess.None;
    this.status = status ?? SyncStatus.Unknown;
    this.notes = notes;
    this.created = created ?? now;
    this.lastModified = lastModified ?? now;
    this.lastSync = lastSync ?? now;
  }

  Map<String, dynamic> toMap() => {
        columnSyncId: this.id,
        columnSyncDeviceId: this.deviceID,
        columnSyncDeviceConnectionId: this.deviceSyncID,
        columnSyncFromInternal: this.syncFromInternal,
        columnSyncVaultId: this.vaultID,
        columnSyncVaultName: this.vaultName,
        columnSyncVaultAccess: this.vaultAccess.toString(),
        columnSyncStatus: syncStatusToString(this.status),
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
        syncFromInternal: isTrue(input[columnSyncFromInternal]),
        vaultID: input[columnSyncVaultId],
        vaultName: input[columnSyncVaultName],
        vaultAccess: DeviceAccess.fromString(input[columnSyncVaultAccess]),
        status: parseSyncStatusFromString(input[columnSyncStatus]),
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
        columnSyncFromInternal: this.syncFromInternal,
        columnSyncVaultId: this.vaultID,
        columnSyncVaultName: this.vaultName,
        columnSyncVaultAccess: this.vaultAccess.toString(),
        columnSyncStatus: syncStatusToString(this.status),
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
        syncFromInternal: isTrue(jsonBlob[columnSyncFromInternal]),
        vaultID: jsonBlob[columnSyncVaultId],
        vaultName: jsonBlob[columnSyncVaultName],
        vaultAccess: DeviceAccess.fromString(jsonBlob[columnSyncVaultAccess]),
        status: parseSyncStatusFromString(jsonBlob[columnSyncStatus]),
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

  DeviceSync clone() {
    return DeviceSync(
      id: this.id,
      deviceID: this.deviceID,
      deviceSyncID: this.deviceSyncID,
      syncFromInternal: this.syncFromInternal,
      vaultID: this.vaultID,
      vaultName: this.vaultName,
      vaultAccess: this.vaultAccess,
      status: this.status,
      notes: this.notes,
      created: this.created,
      lastModified: this.lastModified,
      lastSync: this.lastSync,
    );
  }
}
