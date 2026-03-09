/*
 * Created by Ilan Rasekh on 2020/4/21
 * Copyright (c) 2020 Pseudorand Development. All rights reserved.
 */

import 'package:uuid/uuid.dart';
import 'package:validators/validators.dart';

const String auditTableName = "audit_log";
const String columnAuditId = "_id";
const String columnAuditType = "type";
const String columnAuditMessage = "message";
const String columnAuditDevicesReferenceId = "device_ids";
const String columnAuditSecretsReferenceId = "secret_ids";
const String columnAuditSyncsReferenceId = "sync_ids";
const String columnAuditVaultsReferenceId = "vault_ids";
const String columnAuditDate = "date";

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
  static const AuditType SecretOTPCodeCopied = AuditType._("SecretOTPCodeCopied");

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
    if (_values.contains(auditType)) {
      return AuditType._(auditType);
    } else {
      return AuditType.Unknown;
    }
  }

  @override
  String toString() {
    return _name;
  }
}

class AuditRecord {
  late String id;
  late AuditType type;
  late String message;
  late Set<String> devicesReferenceId;
  late Set<String> secretsReferenceId;
  late Set<String> syncsReferenceId;
  late Set<String> vaultsReferenceId;
  late DateTime date;

  AuditRecord({
    String? id,
    required AuditType type,
    required String message,
    Set<String>? devicesReferenceId,
    Set<String>? secretsReferenceId,
    Set<String>? syncsReferenceId,
    Set<String>? vaultsReferenceId,
    DateTime? date,
  }) {
    if (id == null || id.trim() == '' || !isUUID(id, 4)) {
      id = (const Uuid()).v4();
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
        columnAuditId: id,
        columnAuditType: type.toString(),
        columnAuditMessage: message,
        columnAuditDate: date.toIso8601String(),
        columnAuditDevicesReferenceId: devicesReferenceId.join(','),
        columnAuditSecretsReferenceId: secretsReferenceId.join(','),
        columnAuditSyncsReferenceId: syncsReferenceId.join(','),
        columnAuditVaultsReferenceId: vaultsReferenceId.join(','),
      };

  Map<String, dynamic> toJson() => {
        columnAuditId: id,
        columnAuditType: type.toString(),
        columnAuditMessage: message,
        columnAuditDate: date.toIso8601String(),
        columnAuditDevicesReferenceId: devicesReferenceId,
        columnAuditSecretsReferenceId: secretsReferenceId,
        columnAuditSyncsReferenceId: syncsReferenceId,
        columnAuditVaultsReferenceId: vaultsReferenceId,
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
