/*
 * Created by Ilan Rasekh on 2020/3/13
 * Copyright (c) 2020 Pseudorand Development. All rights reserved.
 */

// TODO: replace with better terminology
import 'package:uuid/uuid.dart';

enum VaultSource { Internal, External }

String vaultSourceToString(VaultSource input) {
  return input.toString().substring(input.toString().indexOf(".") + 1);
}

VaultSource vaultSourceFromString(String input) {
  return VaultSource.values.firstWhere(
      (vs) => vaultSourceToString(vs).toLowerCase() == input.toLowerCase());
}

const String _UID_KEY = "uid";
const String _NICKNAME_KEY = "nickname";
const String _VAULTSOURCE_KEY = "source";
const String _VAULTSOURCEID_KEY = "source_id";

class Vault {
  String uid;
  String nickname;
  VaultSource source;
  String sourceId;

  Vault({uid, this.nickname, this.source, this.sourceId})
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
    return "{\"$_UID_KEY\":\"${this.uid}\"," +
        "\"$_NICKNAME_KEY\":\"${this.nickname}\"," +
        "\"$_VAULTSOURCE_KEY\":\"${this.source}\"," +
        "\"$_VAULTSOURCEID_KEY\":\"${this.sourceId}\"}";
  }

  Map<String, dynamic> toJson() => {
        _UID_KEY: this.uid,
        _NICKNAME_KEY: this.nickname,
        _VAULTSOURCE_KEY: this.source,
        _VAULTSOURCEID_KEY: this.sourceId,
      };

  Vault.fromMap(Map input) {
    this.uid = input[_UID_KEY];
    this.nickname = input[_NICKNAME_KEY];
    this.source = input[_VAULTSOURCE_KEY];
    this.sourceId = input[_VAULTSOURCEID_KEY];
  }
}
