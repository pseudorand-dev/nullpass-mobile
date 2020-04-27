/*
 * Created by Ilan Rasekh on 2020/3/18
 * Copyright (c) 2020 Pseudorand Development. All rights reserved.
 */
import 'dart:convert';

import 'package:nullpass/common.dart';
import 'package:nullpass/services/datastore.dart';
import 'package:uuid/uuid.dart';
import 'package:validators/validators.dart';

const String _DEVICEID_KEY = "device_id";
const String _PUBKEY_KEY = "pub_key";
const String _GENERATEDNONCE_KEY = "generated_nonce";
const String _RECIEVEDNONCE_KEY = "recevied_nonce";

class SyncRegistration {
  String deviceId;
  String pgpPubKey;
  String generatedNonce;
  String receivedNonce;
  // bool received;

  SyncRegistration(
      {this.deviceId, this.pgpPubKey, this.generatedNonce, this.receivedNonce});

  static Future<SyncRegistration> generate({String receivedNonce}) async {
    var dID = sharedPrefs.getString(DeviceNotificationIdPrefKey);
    var pubKey = await NullPassDB.instance.getEncryptionPublicKey();
    var genNonce = Uuid().v4();
    return SyncRegistration(
        deviceId: dID,
        pgpPubKey: pubKey,
        generatedNonce: genNonce,
        receivedNonce: receivedNonce);
  }

  @override
  String toString() {
    var tmpStr = "{\"$_DEVICEID_KEY\":\"$deviceId\"";

    if (pgpPubKey != null && pgpPubKey.isNotEmpty) {
      var tmpPGP = pgpPubKey.replaceAll("\n", "\\n");
      tmpStr = "$tmpStr,\"$_PUBKEY_KEY\":\"$tmpPGP\"";
    }

    if (generatedNonce != null && generatedNonce.isNotEmpty) {
      tmpStr = "$tmpStr,\"$_GENERATEDNONCE_KEY\":\"$generatedNonce\"";
    }

    if (receivedNonce != null && receivedNonce.isNotEmpty) {
      tmpStr = "$tmpStr,\"$_RECIEVEDNONCE_KEY\":\"$receivedNonce\"";
    }

    return "$tmpStr}";
  }

  Map<String, dynamic> toJson() {
    var tmpJson = {
      _DEVICEID_KEY: deviceId,
      _PUBKEY_KEY: pgpPubKey,
      _GENERATEDNONCE_KEY: generatedNonce,
      _RECIEVEDNONCE_KEY: receivedNonce,
    };

    return tmpJson;
  }

  static SyncRegistration fromString(String input) {
    var decoded = jsonDecode(input);
    return SyncRegistration.fromMap(decoded);
  }

  SyncRegistration.fromMap(Map map) {
    deviceId = map[_DEVICEID_KEY] != null &&
            (map[_DEVICEID_KEY] as String).isNotEmpty &&
            (map[_DEVICEID_KEY] as String).trim() != "null"
        ? map[_DEVICEID_KEY]
        : null;
    pgpPubKey = map[_PUBKEY_KEY] != null &&
            (map[_PUBKEY_KEY] as String).isNotEmpty &&
            (map[_PUBKEY_KEY] as String).trim() != "null"
        ? map[_PUBKEY_KEY]
        : null;
    generatedNonce = map[_GENERATEDNONCE_KEY] != null &&
            isUUID(map[_GENERATEDNONCE_KEY] as String)
        ? map[_GENERATEDNONCE_KEY]
        : null;
    receivedNonce = map[_RECIEVEDNONCE_KEY] != null &&
            isUUID(map[_RECIEVEDNONCE_KEY] as String)
        ? map[_RECIEVEDNONCE_KEY]
        : null;
  }

  String toJsonString() {
    return this.toJson().toString();
  }

  bool isValid() {
    if (deviceId != null &&
        deviceId.isNotEmpty &&
        // pgpPubKey != null &&
        // pgpPubKey.isNotEmpty &&
        receivedNonce != null &&
        isUUID(receivedNonce) &&
        (generatedNonce == null || isUUID(generatedNonce))) return true;
    return false;
  }
}
