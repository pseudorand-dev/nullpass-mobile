/*
 * Created by Ilan Rasekh on 2020/3/11
 * Copyright (c) 2020 Pseudorand Development. All rights reserved.
 */
import 'dart:convert';

import 'package:nullpass/common.dart';
import 'package:uuid/uuid.dart';
import 'package:validators/validators.dart';

class QrData {
  String deviceId;
  String generatedNonce;

  QrData({this.deviceId, this.generatedNonce});

  static QrData generate() {
    var dID = notify.deviceId;
    var genNonce = Uuid().v4();
    return QrData(deviceId: dID, generatedNonce: genNonce);
  }

  @override
  String toString() {
    var tmpStr = "{\"device_id\":\"$deviceId\"";
    if (generatedNonce != null && generatedNonce.isNotEmpty) {
      tmpStr = "$tmpStr,\"generated_nonce\":\"$generatedNonce\"";
    }
    return "$tmpStr}";
  }

  Map<String, dynamic> toJson() {
    var tmpJson = {
      "device_id": deviceId,
      "generated_nonce": generatedNonce,
    };

    return tmpJson;
  }

  static QrData fromString(String input) {
    var decoded = jsonDecode(input);
    return QrData.fromMap(decoded);
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
  }

  String toJsonString() {
    return this.toJson().toString();
  }

  bool isValid() {
    if (deviceId != null &&
        deviceId.isNotEmpty &&
        (generatedNonce == null || isUUID(generatedNonce))) return true;
    return false;
  }
}
