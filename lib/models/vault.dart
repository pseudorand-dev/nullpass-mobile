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

final String vaultTableName = 'vaults';
final String columnVaultId = _VAULT_UID_KEY;
final String columnVaultNickname = _VAULT_NICKNAME_KEY;
final String columnVaultManager = _VAULT_MANAGER_KEY;
final String columnVaultManagerId = _VAULT_MANAGERID_KEY;
final String columnVaultIsDefault = _VAULT_ISDEFAULT_KEY;
final String columnVaultSortKey = _VAULT_SORTKEY_KEY;
final String columnVaultCreated = _VAULT_CREATED_KEY;
final String columnVaultModified = _VAULT_MODIFIED_KEY;

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
      {uid,
      this.nickname,
      this.manager,
      this.managerId,
      this.isDefault = false,
      this.createdAt,
      this.modifiedAt})
      : this.uid = _populateUID(uid);

  static String _populateUID(String uid) {
    if (uid == null || uid.trim().isEmpty) {
      return Uuid().v4();
    } else {
      return uid;
    }
  }

  @override
  String toString() {
    return "{\"$_VAULT_UID_KEY\":\"${this.uid}\"," +
        "\"$_VAULT_NICKNAME_KEY\":\"${this.nickname}\"," +
        "\"$_VAULT_MANAGER_KEY\":\"${this.manager}\"," +
        "\"$_VAULT_MANAGERID_KEY\":\"${this.managerId}\"" +
        "\"$_VAULT_ISDEFAULT_KEY\":\"${this.isDefault}\"" +
        "\"$_VAULT_CREATED_KEY\":\"${this.createdAt}\"" +
        "\"$_VAULT_MODIFIED_KEY\":\"${this.modifiedAt}\"}";
  }

  Map<String, dynamic> toJson() => this.toMap();
  Map<String, dynamic> toMap() => {
        _VAULT_UID_KEY: this.uid,
        _VAULT_NICKNAME_KEY: this.nickname,
        _VAULT_MANAGER_KEY: vaultSourceToString(this.manager),
        _VAULT_MANAGERID_KEY: this.managerId,
        _VAULT_ISDEFAULT_KEY: this.isDefault,
        _VAULT_SORTKEY_KEY: this.sortKey,
        _VAULT_CREATED_KEY: this.createdAt.toIso8601String(),
        _VAULT_MODIFIED_KEY: this.modifiedAt.toIso8601String(),
      };

  Vault.fromMap(Map input) {
    this.uid = input[_VAULT_UID_KEY];
    this.nickname = input[_VAULT_NICKNAME_KEY];
    this.manager = vaultSourceFromString(input[_VAULT_MANAGER_KEY]);
    this.managerId = input[_VAULT_MANAGERID_KEY];
    this.isDefault = isTrue(input[_VAULT_ISDEFAULT_KEY]);
    this.createdAt = DateTime.tryParse(input[_VAULT_CREATED_KEY]);
    this.modifiedAt = DateTime.tryParse(input[_VAULT_MODIFIED_KEY]);
  }
}
