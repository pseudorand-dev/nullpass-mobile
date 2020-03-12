/*
 * Created by Ilan Rasekh on 2020/2/28
 * Copyright (c) 2020 Pseudorand Development. All rights reserved.
 */

import 'dart:convert';
import 'package:nullpass/services/logging.dart';

class Notification {
  final NotificationType notificationType;
  final dynamic data;

  Notification(
    this.notificationType, {
    dynamic data,
  }) : this.data = data;

  Map<String, dynamic> toJson() => {
        'type': notificationTypeToString(this.notificationType),
        'data': data,
      };

  static Notification fromJson(String json) {
    var decodedBlob = jsonDecode(json) as Map<String, dynamic>;
    var nType = notificationTypeFromString(decodedBlob["type"]);
    dynamic data;
    if (decodedBlob["data"].runtimeType == String) {
      // String
      data = decodedBlob["data"] as String;
    } else if (decodedBlob["data"].runtimeType ==
        (<String, dynamic>{}).runtimeType) {
      // Map
      data = decodedBlob["data"];
    } else if (decodedBlob["data"].runtimeType == (<dynamic>[]).runtimeType) {
      // List
      data = decodedBlob["data"];
    } else {
      // other
      Log.debug(
          "data object is unexpectedly not a string, a Map<String, dynamic> or List<dynamic>. it is a: ${decodedBlob["data"].runtimeType}");
      try {
        Log.debug("trying to convert it from a List to a string");
        data = (decodedBlob["data"] as List).toString();
      } catch (e) {
        Log.debug(
            "The object could also not be parsed as a list so just passing it as is");
        data = decodedBlob["data"];
      }
    }

    return Notification(nType, data: data);
  }

  static Notification fromMap(Map<String, dynamic> input) {
    if (input == null) return null;

    var nType = notificationTypeFromString(input["type"]);
    var nData = input["data"] as Map;
    return Notification(nType, data: nData);
  }

  Map toMap() {
    return <String, dynamic>{
      "type": notificationTypeToString(this.notificationType),
      "data": this.data,
    };
  }
}

NotificationType notificationTypeFromString(String nType) {
  var ret = NotificationType.Unknown;
  try {
    ret = NotificationType.values.firstWhere((e) =>
        e
            .toString()
            .toUpperCase()
            .substring(e.toString().lastIndexOf(".") + 1) ==
        nType.toUpperCase());
  } catch (e) {
    Log.debug(
        "An error occurred while trying to translate string to NotificationType: ${e.toString()}");
  }

  return ret;
}

String notificationTypeToString(NotificationType notificationType) {
  return notificationType
      .toString()
      .substring(notificationType.toString().lastIndexOf(".") + 1);
}

enum NotificationType {
  ScanSyncInit,
  ScanSyncInitResponse,
  CodeSyncInitResponse,
  SyncUpdate,
  SyncUpdateReceived,
  Unknown
}
