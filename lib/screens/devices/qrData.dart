/*
 * Created by Ilan Rasekh on 2020/3/11
 * Copyright (c) 2020 Pseudorand Development. All rights reserved.
 */

import 'package:nullpass/common.dart';
import 'package:uuid/uuid.dart';
import 'package:validators/validators.dart';

class QrData {
  String deviceId;
  String receivedNonce;
  String generatedNonce;

  QrData()
      : deviceId = notify.deviceId,
        generatedNonce = Uuid().v4();

  Map<String, dynamic> toJson() {
    var tmpJson = {
      "device_id": deviceId,
      "generated_nonce": generatedNonce,
    };
    if (receivedNonce != null && receivedNonce.isNotEmpty) {
      tmpJson["received_nonce"] = receivedNonce;
    }

    return tmpJson;
  }

  QrData.fromMap(Map map) {
    deviceId = map["device_id"] != null &&
            (map["device_id"] as String).isNotEmpty &&
            (map["device_id"] as String).trim() != "null"
        ? map["device_id"]
        : null;
    generatedNonce = map["generated_nonce"] != null &&
            isUUID(map["generated_nonce"] as String)
        ? map["generated_nonce"]
        : null;
    receivedNonce =
        map["received_nonce"] != null && isUUID(map["received_nonce"] as String)
            ? map["received_nonce"]
            : null;
  }

  String toJsonString() {
    return this.toJson().toString();
  }

  @override
  String toString() {
    var tmpStr = "{\"device_id\": \"$deviceId\"";
    if (generatedNonce != null && generatedNonce.isNotEmpty) {
      tmpStr = "$tmpStr, \"generated_nonce\":\"$generatedNonce\"";
    }
    if (receivedNonce != null && receivedNonce.isNotEmpty) {
      tmpStr = "$tmpStr, \"received_nonce\":\"$receivedNonce\"";
    }
    return "$tmpStr}";
  }

  bool isValid() {
    if (deviceId != null &&
        deviceId.isNotEmpty &&
        (generatedNonce == null || isUUID(generatedNonce)) &&
        (receivedNonce == null || isUUID(receivedNonce))) return true;
    return false;
  }
}
