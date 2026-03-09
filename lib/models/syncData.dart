/*
 * Created by Ilan Rasekh on 2020/3/11
 * Copyright (c) 2020 Pseudorand Development. All rights reserved.
 */

import 'dart:convert';

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
  late NullPassSync data;
  late SyncType type;
  late String receivedNonce;
  late String generatedNonce;
  late bool state;

  SyncDataWrapper(
      {required this.data, required this.type, required this.receivedNonce, required this.generatedNonce});

  Map<String, dynamic> toJson() {
    return {
      _SYNC_DATA_KEY: data.toJson(),
      _DATA_TYPE_KEY: syncTypeToString(type),
      if (receivedNonce.isNotEmpty)
        _RECEIVED_NONCE_KEY: receivedNonce,
      if (generatedNonce.isNotEmpty)
        _GENERATED_NONCE_KEY: generatedNonce,
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
  String toString() => jsonEncode(toJson());
}

// Handles changes of sync access for preexisting syncs
class SyncStateChange {
  late DeviceAccess newState;
  late String vaultId;
}

abstract class NullPassSync {
  toJson();

  @override
  String toString() => jsonEncode(toJson());
}

class SyncVaultAdd extends NullPassSync {
  late String vaultId;
  late String vaultName;
  late DeviceAccess accessLevel;
  late List<Secret> secrets;

  SyncVaultAdd({
    required String vaultId,
    required String vaultName,
    DeviceAccess accessLevel = DeviceAccess.None,
    List<Secret> secrets = const <Secret>[],
  }) {
    this.vaultId = vaultId;
    this.vaultName = vaultName;
    this.accessLevel = accessLevel;
    this.secrets = secrets;
  }

  @override
  Map<String, dynamic> toJson() => {
        "vault_id": vaultId,
        "vault_name": vaultName,
        "access_level": accessLevel.toString(),
        "secrets": secrets,
      };

  SyncVaultAdd.fromMap(Map map) {
    vaultId = map["vault_id"];
    vaultName = map["vault_name"];
    accessLevel = DeviceAccess.fromString(map["access_level"]);
    secrets = <Secret>[];
    for (var s in (map["secrets"] as List)) {
      secrets.add(Secret.fromMap(s));
    }
  }
}

class SyncVaultUpdate extends NullPassSync {
  late DeviceAccess accessLevel;
  late String vaultName;
  late String vaultId;

  SyncVaultUpdate({
    required String vaultId,
    required String vaultName,
    required DeviceAccess accessLevel,
  }) {
    this.vaultId = vaultId;
    this.vaultName = vaultName;
    this.accessLevel = accessLevel ?? DeviceAccess.None;
  }

  @override
  Map<String, dynamic> toJson() => {
        "vault_id": vaultId,
        "vault_name": vaultName,
        "access_level": accessLevel.toString(),
      };

  SyncVaultUpdate.fromMap(Map map) {
    vaultId = map["vault_id"];
    vaultName = map["vault_name"];
    accessLevel = DeviceAccess.fromString(map["access_level"]);
  }
}

class SyncVaultRemove extends NullPassSync {
  late String vaultId;

  SyncVaultRemove(this.vaultId);

  @override
  Map<String, dynamic> toJson() => {"vault_id": vaultId};

  SyncVaultRemove.fromMap(Map map) {
    vaultId = map["vault_id"];
  }
}

class SyncDataAdd extends NullPassSync {
  late String vaultId;
  late List<Secret> secrets;

  SyncDataAdd({required this.vaultId, required this.secrets});

  @override
  Map<String, dynamic> toJson() => {
        "vault_id": vaultId,
        "secrets": secrets,
      };

  SyncDataAdd.fromMap(Map map) {
    vaultId = map["vault_id"];
    secrets = <Secret>[];
    for (var s in (map["secrets"] as List)) {
      secrets.add(Secret.fromMap(s));
    }
  }
}

class SyncDataUpdate extends NullPassSync {
  late String vaultId;
  late List<Secret> secrets;

  SyncDataUpdate({required this.vaultId, required this.secrets});

  @override
  Map<String, dynamic> toJson() => {
        "vault_id": vaultId,
        "secrets": secrets,
      };

  SyncDataUpdate.fromMap(Map map) {
    vaultId = map["vault_id"];
    secrets = <Secret>[];
    for (var s in (map["secrets"] as List)) {
      secrets.add(Secret.fromMap(s));
    }
  }
}

class SyncDataRemove extends NullPassSync {
  late String vaultId;
  late List<String> secretIDs;

  SyncDataRemove({required this.vaultId, required this.secretIDs});

  @override
  Map<String, dynamic> toJson() => {
        "vault_id": vaultId,
        "secret_ids": secretIDs,
      };

  SyncDataRemove.fromMap(Map map) {
    vaultId = map["vault_id"];
    secretIDs = <String>[];
    for (var s in (map["secret_ids"] as List)) {
      secretIDs.add(s as String);
    }
  }
}
