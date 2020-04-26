/*
 * Created by Ilan Rasekh on 2020/4/21
 * Copyright (c) 2020 Pseudorand Development. All rights reserved.
 */

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:validators/validators.dart';

final String auditTableName = "audit_log";
final String columnAuditId = "_id";
final String columnAuditType = "type";
final String columnAuditMessage = "message";
final String columnAuditDevicesReferenceId = "device_ids";
final String columnAuditSecretsReferenceId = "secret_ids";
final String columnAuditSyncsReferenceId = "sync_ids";
final String columnAuditVaultsReferenceId = "vault_ids";
final String columnAuditDate = "date";

class AuditType {
  static const AuditType Unknown = AuditType._("Unknown");

  // App Actions
  static const AuditType AppDataExported = AuditType._("AppDataExported");
  static const AuditType AppDataImported = AuditType._("AppDataImported");
  static const AuditType AppDataDeleted = AuditType._("AppDataDeleted");
  static const AuditType AppSetup = AuditType._("AppSetup");

  // Device Actions
  static const AuditType DeviceCreated = AuditType._("DeviceCreated");
  static const AuditType DeviceUpdated = AuditType._("DeviceUpdated");
  static const AuditType DeviceDeleted = AuditType._("DeviceDeleted");

  // Secrets Actions
  static const AuditType SecretCreated = AuditType._("SecretCreated");
  static const AuditType SecretUpdated = AuditType._("SecretUpdated");
  static const AuditType SecretDeleted = AuditType._("SecretDeleted");
  static const AuditType SecretViewed = AuditType._("SecretViewed");
  static const AuditType SecretUrlCopied = AuditType._("SecretUrlCopied");
  static const AuditType SecretUrlOpened = AuditType._("SecretUrlOpened");
  static const AuditType SecretUsernameCopied =
      AuditType._("SecretUsernameCopied");
  static const AuditType SecretNotesCopied = AuditType._("SecretNotesCopied");
  static const AuditType SecretPasswordViewed =
      AuditType._("SecretPasswordViewed");
  static const AuditType SecretPasswordCopied =
      AuditType._("SecretPasswordCopied");

  // Sync Actions
  static const AuditType SyncCreated = AuditType._("SyncCreated");
  static const AuditType SyncUpdated = AuditType._("SyncUpdated");
  static const AuditType SyncDeleted = AuditType._("SyncDeleted");

  // Vault Actions
  static const AuditType VaultCreated = AuditType._("VaultCreated");
  static const AuditType VaultUpdated = AuditType._("VaultUpdated");
  static const AuditType VaultDeleted = AuditType._("VaultDeleted");
  static const AuditType VaultNewDefault = AuditType._("VaultNewDefault");

  final String _name;
  const AuditType._(this._name);

  static const List<String> _values = <String>[
    "Unknown",
    "AppDataExported",
    "AppDataImported",
    "AppDataDeleted",
    "AppSetup",
    "DeviceCreated",
    "DeviceUpdated",
    "DeviceDeleted",
    "SecretCreated",
    "SecretUpdated",
    "SecretDeleted",
    "SecretViewed",
    "SecretUrlCopied",
    "SecretUrlOpened",
    "SecretUsernameCopied",
    "SecretNotesCopied",
    "SecretPasswordViewed",
    "SecretPasswordCopied",
    "SyncCreated",
    "SyncUpdated",
    "SyncDeleted",
    "VaultCreated",
    "VaultUpdated",
    "VaultDeleted",
    "VaultNewDefault",
  ];

  static dynamic fromString(String auditType) {
    if (_values.contains(auditType))
      return AuditType._(auditType);
    else
      return AuditType.Unknown;
  }

  @override
  String toString() {
    return _name;
  }
}

class AuditRecord {
  String id;
  AuditType type;
  String message;
  Set<String> devicesReferenceId;
  Set<String> secretsReferenceId;
  Set<String> syncsReferenceId;
  Set<String> vaultsReferenceId;
  DateTime date;

  AuditRecord({
    String id,
    @required AuditType type,
    @required String message,
    Set<String> devicesReferenceId,
    Set<String> secretsReferenceId,
    Set<String> syncsReferenceId,
    Set<String> vaultsReferenceId,
    DateTime date,
  }) {
    if (id == null || id.trim() == '' || !isUUID(id, 4)) {
      id = (new Uuid()).v4();
    }
    DateTime now = DateTime.now().toUtc();

    this.id = id;
    this.type = type;
    this.message = message;
    this.devicesReferenceId = devicesReferenceId ?? <String>{};
    this.secretsReferenceId = secretsReferenceId ?? <String>{};
    this.syncsReferenceId = syncsReferenceId ?? <String>{};
    this.vaultsReferenceId = vaultsReferenceId ?? <String>{};
    this.date = date ?? now;
  }

  Map<String, dynamic> toMap() => {
        columnAuditId: this.id,
        columnAuditType: this.type.toString(),
        columnAuditMessage: this.message,
        columnAuditDate: this.date.toIso8601String(),
        columnAuditDevicesReferenceId: this.devicesReferenceId.join(','),
        columnAuditSecretsReferenceId: this.secretsReferenceId.join(','),
        columnAuditSyncsReferenceId: this.syncsReferenceId.join(','),
        columnAuditVaultsReferenceId: this.vaultsReferenceId.join(','),
      };

  Map<String, dynamic> toJson() => {
        columnAuditId: this.id,
        columnAuditType: this.type.toString(),
        columnAuditMessage: this.message,
        columnAuditDate: this.date.toIso8601String(),
        columnAuditDevicesReferenceId: this.devicesReferenceId,
        columnAuditSecretsReferenceId: this.secretsReferenceId,
        columnAuditSyncsReferenceId: this.syncsReferenceId,
        columnAuditVaultsReferenceId: this.vaultsReferenceId,
      };

  AuditRecord.fromMap(Map map) {
    id = map[columnAuditId];
    type = AuditType.fromString(map[columnAuditType]);
    message = map[columnAuditMessage];
    date = DateTime.tryParse(map[columnAuditDate]) ?? DateTime.now();
    devicesReferenceId =
        (map[columnAuditDevicesReferenceId] as String).split(",").toSet() ??
            <String>{};
    secretsReferenceId =
        (map[columnAuditSecretsReferenceId] as String).split(",").toSet() ??
            <String>{};
    syncsReferenceId =
        (map[columnAuditSyncsReferenceId] as String).split(",").toSet() ??
            <String>{};
    vaultsReferenceId =
        (map[columnAuditVaultsReferenceId] as String).split(",").toSet() ??
            <String>{};
  }
}
