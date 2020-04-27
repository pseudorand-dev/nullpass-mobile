/*
 * Created by Ilan Rasekh on 2020/3/11
 * Copyright (c) 2020 Pseudorand Development. All rights reserved.
 */

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nullpass/models/deviceSync.dart';
import 'package:nullpass/models/secret.dart';
import 'package:nullpass/services/logging.dart';

const String _SYNC_DATA_KEY = "data";
const String _DATA_TYPE_KEY = "type";
const String _RECEIVED_NONCE_KEY = "received_nonce";
const String _GENERATED_NONCE_KEY = "generated_nonce";

enum SyncType {
  Unknown,
  VaultAdd,
  VaultRemove,
  VaultUpdate,
  DataAdd,
  DataRemove,
  DataUpdate,
  StateChange,
}
String syncTypeToString(SyncType st) =>
    st.toString().substring(st.toString().lastIndexOf(".") + 1);

SyncType parseSyncTypeFromString(String syncType) {
  var ret = SyncType.Unknown;
  try {
    ret = SyncType.values.firstWhere((st) =>
        st
            .toString()
            .toLowerCase()
            .substring(st.toString().lastIndexOf(".") + 1) ==
        syncType.toLowerCase());
  } catch (e) {
    Log.debug(
        "An error occurred while trying to translate string to SyncType: ${e.toString()}");
  }
  return ret;
}

class SyncDataWrapper {
  NullPassSync data;
  SyncType type;
  String receivedNonce;
  String generatedNonce;
  bool state;

  SyncDataWrapper(
      {this.data, this.type, this.receivedNonce, this.generatedNonce});

  Map<String, dynamic> toJson() {
    return {
      _SYNC_DATA_KEY: this.data.toJson(),
      _DATA_TYPE_KEY: syncTypeToString(this.type),
      if (this.receivedNonce != null && receivedNonce.isNotEmpty)
        _RECEIVED_NONCE_KEY: this.receivedNonce,
      if (this.generatedNonce != null && generatedNonce.isNotEmpty)
        _GENERATED_NONCE_KEY: this.generatedNonce,
    };
  }

  SyncDataWrapper.fromMap(Map map) {
    type = parseSyncTypeFromString(map[_DATA_TYPE_KEY]);
    receivedNonce = map[_RECEIVED_NONCE_KEY];
    generatedNonce = map[_GENERATED_NONCE_KEY];
    switch (type) {
      case SyncType.VaultAdd:
        data = SyncVaultAdd.fromMap(map[_SYNC_DATA_KEY]);
        break;
      case SyncType.VaultUpdate:
        data = SyncVaultUpdate.fromMap(map[_SYNC_DATA_KEY]);
        break;
      case SyncType.VaultRemove:
        data = SyncVaultRemove.fromMap(map[_SYNC_DATA_KEY]);
        break;
      case SyncType.DataAdd:
        data = SyncDataAdd.fromMap(map[_SYNC_DATA_KEY]);
        break;
      case SyncType.DataUpdate:
        data = SyncDataUpdate.fromMap(map[_SYNC_DATA_KEY]);
        break;
      case SyncType.DataRemove:
        data = SyncDataRemove.fromMap(map[_SYNC_DATA_KEY]);
        break;
      default:
        Log.debug(syncTypeToString(type));
        break;
    }
  }

  @override
  String toString() => jsonEncode(this.toJson());
}

// Handles changes of sync access for preexisting syncs
class SyncStateChange {
  DeviceAccess newState;
  String vaultId;
}

abstract class NullPassSync {
  toJson();

  @override
  String toString() => jsonEncode(this.toJson());
}

class SyncVaultAdd extends NullPassSync {
  String vaultId;
  String vaultName;
  DeviceAccess accessLevel;
  List<Secret> secrets;

  SyncVaultAdd({
    @required String vaultId,
    String vaultName,
    DeviceAccess accessLevel,
    List<Secret> secrets,
  }) {
    this.vaultId = vaultId;
    this.vaultName = vaultName;
    this.accessLevel = accessLevel ?? DeviceAccess.None;
    this.secrets = secrets ?? <Secret>[];
  }

  Map<String, dynamic> toJson() => {
        "vault_id": this.vaultId,
        "vault_name": this.vaultName,
        "access_level": this.accessLevel.toString(),
        "secrets": this.secrets,
      };

  SyncVaultAdd.fromMap(Map map) {
    vaultId = map["vault_id"];
    vaultName = map["vault_name"];
    accessLevel = DeviceAccess.fromString(map["access_level"]);
    secrets = <Secret>[];
    (map["secrets"] as List).forEach((s) => secrets.add(Secret.fromMap(s)));
  }
}

class SyncVaultUpdate extends NullPassSync {
  DeviceAccess accessLevel;
  String vaultName;
  String vaultId;

  SyncVaultUpdate({
    @required String vaultId,
    @required String vaultName,
    @required DeviceAccess accessLevel,
  }) {
    this.vaultId = vaultId;
    this.vaultName = vaultName;
    this.accessLevel = accessLevel ?? DeviceAccess.None;
  }

  Map<String, dynamic> toJson() => {
        "vault_id": this.vaultId,
        "vault_name": this.vaultName,
        "access_level": this.accessLevel.toString(),
      };

  SyncVaultUpdate.fromMap(Map map) {
    vaultId = map["vault_id"];
    vaultName = map["vault_name"];
    accessLevel = DeviceAccess.fromString(map["access_level"]);
  }
}

class SyncVaultRemove extends NullPassSync {
  String vaultId;

  SyncVaultRemove(this.vaultId);

  Map<String, dynamic> toJson() => {"vault_id": this.vaultId};

  SyncVaultRemove.fromMap(Map map) {
    vaultId = map["vault_id"];
  }
}

class SyncDataAdd extends NullPassSync {
  String vaultId;
  List<Secret> secrets;

  SyncDataAdd({@required this.vaultId, @required this.secrets});

  Map<String, dynamic> toJson() => {
        "vault_id": vaultId,
        "secrets": this.secrets,
      };

  SyncDataAdd.fromMap(Map map) {
    vaultId = map["vault_id"];
    secrets = <Secret>[];
    (map["secrets"] as List).forEach((s) => secrets.add(Secret.fromMap(s)));
  }
}

class SyncDataUpdate extends NullPassSync {
  String vaultId;
  List<Secret> secrets;

  SyncDataUpdate({@required this.vaultId, @required this.secrets});

  Map<String, dynamic> toJson() => {
        "vault_id": vaultId,
        "secrets": this.secrets,
      };

  SyncDataUpdate.fromMap(Map map) {
    vaultId = map["vault_id"];
    secrets = <Secret>[];
    (map["secrets"] as List).forEach((s) => secrets.add(Secret.fromMap(s)));
  }
}

class SyncDataRemove extends NullPassSync {
  String vaultId;
  List<String> secretIDs;

  SyncDataRemove({@required this.vaultId, @required this.secretIDs});

  Map<String, dynamic> toJson() => {
        "vault_id": vaultId,
        "secret_ids": secretIDs,
      };

  SyncDataRemove.fromMap(Map map) {
    vaultId = map["vault_id"];
    secretIDs = <String>[];
    (map["secret_ids"] as List).forEach((s) => secretIDs.add(s as String));
  }
}
