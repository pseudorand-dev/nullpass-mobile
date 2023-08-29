/*
 * Created by Ilan Rasekh on 2020/3/12
 * Copyright (c) 2020 Pseudorand Development. All rights reserved.
 */

import 'package:flutter/foundation.dart';
import 'package:nullpass/services/logging.dart';
import 'package:uuid/uuid.dart';
import 'package:validators/validators.dart';

final String deviceTableName = 'devices';
final String columnDeviceId = "_id";
final String columnDeviceSyncId = "device_id";
final String columnDeviceNickname = "nickname";
final String columnDeviceEncryptionKey = "encryption_key";
final String columnDeviceType = "device_type";
final String columnDeviceNotes = "notes";
final String columnDeviceCreated = "created_at";
final String columnDeviceModified = "modified_at";
final String columnDeviceSortKey = "sort_key";

enum DeviceType { MacOS, iOS, Android, Unknown }

String deviceTypeToString(DeviceType? dt) =>
    dt.toString().substring(dt.toString().lastIndexOf(".") + 1);

DeviceType parseDeviceTypeFromString(String? dType) {
  var ret = DeviceType.Unknown;
  try {
    ret = DeviceType.values.firstWhere((e) =>
        e
            .toString()
            .toLowerCase()
            .substring(e.toString().lastIndexOf(".") + 1) ==
        dType!.toLowerCase());
  } catch (e) {
    Log.debug(
        "An error occurred while trying to translate string to NotificationType: ${e.toString()}");
    // throw new Exception("Unknown DeviceType");
  }
  return ret;
}

class Device {
  String? id;
  String? deviceID;
  String? nickname;
  String? encryptionKey;
  DeviceType? type;
  String? notes;
  DateTime? created;
  DateTime? lastModified;
  String get sortKey => (nickname != null) ? nickname!.trim().toLowerCase() : "";

  Device({
    String? id,
    required String? deviceID,
    String? nickname,
    String? encryptionKey,
    DeviceType? type,
    String? notes,
    DateTime? created,
    DateTime? lastModified,
  }) {
    if (id == null || id.trim() == '' || !isUUID(id, 4)) {
      id = (new Uuid()).v4();
    }

    DateTime now = DateTime.now().toUtc();

    this.id = id;
    this.deviceID = deviceID;
    this.nickname = nickname;
    this.encryptionKey = encryptionKey ?? "";
    this.type = type ?? DeviceType.Unknown;
    this.notes = notes;
    this.created = created ?? now;
    this.lastModified = lastModified ?? now;
  }

  Map<String, dynamic> toMap() => {
        columnDeviceId: this.id,
        columnDeviceSyncId: this.deviceID,
        columnDeviceNickname: this.nickname,
        columnDeviceEncryptionKey: this.encryptionKey ?? "",
        columnDeviceType: deviceTypeToString(this.type),
        columnDeviceNotes: this.notes,
        columnDeviceCreated: (this.created != null)
            ? this.created!.toIso8601String()
            : DateTime.now().toUtc().toIso8601String(),
        columnDeviceModified: (this.lastModified != null)
            ? this.lastModified!.toIso8601String()
            : DateTime.now().toUtc().toIso8601String(),
        columnDeviceSortKey: sortKey,
      };

  static Device fromMap(Map input) {
    try {
      var newDevice = Device(
        id: input[columnDeviceId],
        deviceID: input[columnDeviceSyncId],
        nickname: input[columnDeviceNickname],
        encryptionKey: input[columnDeviceEncryptionKey] ?? "",
        type: parseDeviceTypeFromString(input[columnDeviceType]),
        notes: input[columnDeviceNotes],
        created: DateTime.tryParse(input[columnDeviceCreated]),
        lastModified: DateTime.tryParse(input[columnDeviceModified]),
      );
      return newDevice;
    } catch (e) {
      Log.debug("error creating device from map: ${e.toString()}");
      throw e;
    }
  }

  Map<String, dynamic> toJson() => {
        columnDeviceId: this.id,
        columnDeviceSyncId: this.deviceID,
        columnDeviceNickname: this.nickname,
        columnDeviceEncryptionKey: this.encryptionKey ?? "",
        columnDeviceType: deviceTypeToString(this.type),
        columnDeviceNotes: this.notes,
        columnDeviceCreated: (this.created != null)
            ? this.created!.toIso8601String()
            : DateTime.now().toUtc().toIso8601String(),
        columnDeviceModified: (this.lastModified != null)
            ? this.lastModified!.toIso8601String()
            : DateTime.now().toUtc().toIso8601String(),
        columnDeviceSortKey: sortKey,
      };

  static Device deviceFromJson(Map<String, dynamic> input) {
    try {
      var newDevice = Device(
        id: input[columnDeviceId],
        deviceID: input[columnDeviceSyncId],
        nickname: input[columnDeviceNickname],
        encryptionKey: input[columnDeviceEncryptionKey] ?? "",
        type: parseDeviceTypeFromString(input[columnDeviceType]),
        notes: input[columnDeviceNotes],
        created: DateTime.tryParse(input[columnDeviceCreated]),
        lastModified: DateTime.tryParse(input[columnDeviceModified]),
      );
      return newDevice;
    } catch (e) {
      Log.debug("error creating device from json: ${e.toString()}");
      throw e;
    }
  }
}
