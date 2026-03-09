/*
 * Created by Ilan Rasekh on 2020/3/13
 * Copyright (c) 2020 Pseudorand Development. All rights reserved.
 */

import 'package:nullpass/common.dart';
import 'package:uuid/uuid.dart';

// TODO: replace with better terminology
enum VaultManager { Internal, External }

String vaultSourceToString(VaultManager input) {
  return input.toString().substring(input.toString().indexOf(".") + 1);
}

VaultManager vaultSourceFromString(String input) {
  return VaultManager.values.firstWhere(
      (vs) => vaultSourceToString(vs).toLowerCase() == input.toLowerCase());
}

const String _VAULT_UID_KEY = "_id";
const String _VAULT_NICKNAME_KEY = "nickname";
const String _VAULT_MANAGER_KEY = "manager";
const String _VAULT_MANAGERID_KEY = "manager_id";
const String _VAULT_ISDEFAULT_KEY = "is_default";
const String _VAULT_SORTKEY_KEY = "sort_key";
const String _VAULT_CREATED_KEY = "created_at";
const String _VAULT_MODIFIED_KEY = "modified_at";

const String vaultTableName = 'vaults';
const String columnVaultId = _VAULT_UID_KEY;
const String columnVaultNickname = _VAULT_NICKNAME_KEY;
const String columnVaultManager = _VAULT_MANAGER_KEY;
const String columnVaultManagerId = _VAULT_MANAGERID_KEY;
const String columnVaultIsDefault = _VAULT_ISDEFAULT_KEY;
const String columnVaultSortKey = _VAULT_SORTKEY_KEY;
const String columnVaultCreated = _VAULT_CREATED_KEY;
const String columnVaultModified = _VAULT_MODIFIED_KEY;

class Vault {
  static const String InternalSourceID = "myDevice";

  String uid;
  String nickname;
  VaultManager manager;
  String managerId;
  bool isDefault;
  DateTime createdAt;
  DateTime modifiedAt;
  get sortKey => nickname.trim().toLowerCase() ?? "";

  Vault(
      {String? uid,
      required this.nickname,
      required this.manager,
      required this.managerId,
      this.isDefault = false,
      DateTime? createdAt,
      DateTime? modifiedAt})
      : uid = _populateUID(uid),
        createdAt = createdAt ?? DateTime.now(),
        modifiedAt = modifiedAt ?? DateTime.now();

  static String _populateUID(String? uid) {
    if (uid == null || uid.trim().isEmpty) {
      return const Uuid().v4();
    } else {
      return uid;
    }
  }

  @override
  String toString() {
    return "{\"$_VAULT_UID_KEY\":\"$uid\"," "\"$_VAULT_NICKNAME_KEY\":\"$nickname\"," "\"$_VAULT_MANAGER_KEY\":\"$manager\"," "\"$_VAULT_MANAGERID_KEY\":\"$managerId\"" "\"$_VAULT_ISDEFAULT_KEY\":\"$isDefault\"" +
        "\"$_VAULT_CREATED_KEY\":\"$createdAt\"" +
        "\"$_VAULT_MODIFIED_KEY\":\"$modifiedAt\"}";
  }

  Map<String, dynamic> toJson() => toMap();
  Map<String, dynamic> toMap() => {
        _VAULT_UID_KEY: uid,
        _VAULT_NICKNAME_KEY: nickname,
        _VAULT_MANAGER_KEY: vaultSourceToString(manager),
        _VAULT_MANAGERID_KEY: managerId,
        _VAULT_ISDEFAULT_KEY: isDefault,
        _VAULT_SORTKEY_KEY: sortKey,
        _VAULT_CREATED_KEY: createdAt.toIso8601String(),
        _VAULT_MODIFIED_KEY: modifiedAt.toIso8601String(),
      };

  Vault.fromMap(Map input) :
    uid = input[_VAULT_UID_KEY],
    nickname = input[_VAULT_NICKNAME_KEY],
    manager = vaultSourceFromString(input[_VAULT_MANAGER_KEY]),
    managerId = input[_VAULT_MANAGERID_KEY],
    isDefault = isTrue(input[_VAULT_ISDEFAULT_KEY]),
    createdAt = DateTime.tryParse(input[_VAULT_CREATED_KEY]) ?? DateTime.now(),
    modifiedAt = DateTime.tryParse(input[_VAULT_MODIFIED_KEY]) ?? DateTime.now();
}
