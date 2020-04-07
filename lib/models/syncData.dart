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
      case SyncType.VaultRemove:
        data = SyncVaultRemove.fromMap(map[_SYNC_DATA_KEY]);
        break;
      default:
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
        "access_level": deviceAccessToString(this.accessLevel),
        "secrets": this.secrets,
      };

  SyncVaultAdd.fromMap(Map map) {
    vaultId = map["vault_id"];
    vaultName = map["vault_name"];
    accessLevel = parseDeviceAccessFromString(map["access_level"]);
    secrets = <Secret>[];
    (map["secrets"] as List).forEach((s) => secrets.add(Secret.fromMap(s)));
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