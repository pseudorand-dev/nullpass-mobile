/*
 * Created by Ilan Rasekh on 2020/3/13
 * Copyright (c) 2020 Pseudorand Development. All rights reserved.
 */

import 'package:nullpass/common.dart';
import 'package:uuid/uuid.dart';

// TODO: replace with better terminology
enum VaultSource { Internal, External }

String vaultSourceToString(VaultSource input) {
  return input.toString().substring(input.toString().indexOf(".") + 1);
}

VaultSource vaultSourceFromString(String input) {
  return VaultSource.values.firstWhere(
      (vs) => vaultSourceToString(vs).toLowerCase() == input.toLowerCase());
}

const String _VAULT_UID_KEY = "_id";
const String _VAULT_NICKNAME_KEY = "nickname";
const String _VAULT_SOURCE_KEY = "source";
const String _VAULT_SOURCEID_KEY = "source_id";
const String _VAULT_ISDEFAULT_KEY = "is_default";
const String _VAULT_SORTKEY_KEY = "sort_key";
const String _VAULT_CREATED_KEY = "created_at";
const String _VAULT_MODIFIED_KEY = "modified_at";

final String vaultTableName = 'vaults';
final String columnVaultId = _VAULT_UID_KEY;
final String columnVaultNickname = _VAULT_NICKNAME_KEY;
final String columnVaultSource = _VAULT_SOURCE_KEY;
final String columnVaultSourceId = _VAULT_SOURCEID_KEY;
final String columnVaultIsDefault = _VAULT_ISDEFAULT_KEY;
final String columnVaultSortKey = _VAULT_SORTKEY_KEY;
final String columnVaultCreated = _VAULT_CREATED_KEY;
final String columnVaultModified = _VAULT_MODIFIED_KEY;

class Vault {
  String uid;
  String nickname;
  VaultSource source;
  String sourceId;
  bool isDefault;
  DateTime createdAt;
  DateTime modifiedAt;
  get sortKey => nickname.trim().toLowerCase() ?? "";

  Vault(
      {uid,
      this.nickname,
      this.source,
      this.sourceId,
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
        "\"$_VAULT_SOURCE_KEY\":\"${this.source}\"," +
        "\"$_VAULT_SOURCEID_KEY\":\"${this.sourceId}\"" +
        "\"$_VAULT_ISDEFAULT_KEY\":\"${this.isDefault}\"" +
        "\"$_VAULT_CREATED_KEY\":\"${this.createdAt}\"" +
        "\"$_VAULT_MODIFIED_KEY\":\"${this.modifiedAt}\"}";
  }

  Map<String, dynamic> toJson() => this.toMap();
  Map<String, dynamic> toMap() => {
        _VAULT_UID_KEY: this.uid,
        _VAULT_NICKNAME_KEY: this.nickname,
        _VAULT_SOURCE_KEY: vaultSourceToString(this.source),
        _VAULT_SOURCEID_KEY: this.sourceId,
        _VAULT_ISDEFAULT_KEY: this.isDefault,
        _VAULT_SORTKEY_KEY: this.sortKey,
        _VAULT_CREATED_KEY: this.createdAt.toIso8601String(),
        _VAULT_MODIFIED_KEY: this.modifiedAt.toIso8601String(),
      };

  Vault.fromMap(Map input) {
    this.uid = input[_VAULT_UID_KEY];
    this.nickname = input[_VAULT_NICKNAME_KEY];
    this.source = vaultSourceFromString(input[_VAULT_SOURCE_KEY]);
    this.sourceId = input[_VAULT_SOURCEID_KEY];
    this.isDefault = isTrue(input[_VAULT_ISDEFAULT_KEY]);
    this.createdAt = DateTime.tryParse(input[_VAULT_CREATED_KEY]);
    this.modifiedAt = DateTime.tryParse(input[_VAULT_MODIFIED_KEY]);
  }
}
