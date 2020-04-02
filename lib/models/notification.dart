/*
 * Created by Ilan Rasekh on 2020/2/28
 * Copyright (c) 2020 Pseudorand Development. All rights reserved.
 */

import 'dart:convert';
import 'package:nullpass/services/logging.dart';

const int _MESSAGE_CHUNK_MAX_SIZE = 1500;
const String _TYPE_KEY = "type";
const String _DATA_KEY = "data";
const String _PARTS_KEY = "parts";
const String _POSITION_KEY = "position";

class Notification {
  final NotificationType notificationType;
  int parts;
  int position;
  final dynamic data;

  Notification(
    this.notificationType, {
    dynamic data,
    this.parts,
    this.position,
  }) : this.data = data;

  Map<String, dynamic> toJson() => {
        'type': notificationTypeToString(this.notificationType),
        'data': data,
        'parts': parts ?? 1,
        'position': position ?? 1,
      };

  static Notification fromJson(String json) {
    var decodedBlob = jsonDecode(json) as Map<String, dynamic>;
    var nType = notificationTypeFromString(decodedBlob[_TYPE_KEY]);
    var nParts = decodedBlob[_PARTS_KEY] as int;
    var nPos = decodedBlob[_POSITION_KEY] as int;

    dynamic data;
    if (decodedBlob[_DATA_KEY].runtimeType == String) {
      // String
      data = decodedBlob[_DATA_KEY] as String;
    } else if (decodedBlob[_DATA_KEY].runtimeType ==
        (<String, dynamic>{}).runtimeType) {
      // Map
      data = decodedBlob[_DATA_KEY];
    } else if (decodedBlob[_DATA_KEY].runtimeType ==
        (<dynamic>[]).runtimeType) {
      // List
      data = decodedBlob[_DATA_KEY];
    } else {
      // other
      Log.debug(
          "data object is unexpectedly not a string, a Map<String, dynamic> or List<dynamic>. it is a: ${decodedBlob[_DATA_KEY].runtimeType}");
      try {
        Log.debug("trying to convert it from a List to a string");
        data = (decodedBlob[_DATA_KEY] as List).toString();
      } catch (e) {
        Log.debug(
            "The object could also not be parsed as a list so just passing it as is");
        data = decodedBlob[_DATA_KEY];
      }
    }

    return Notification(nType, data: data, parts: nParts, position: nPos);
  }

  static Notification fromMap(Map<String, dynamic> input) {
    if (input == null) return null;

    var nType = notificationTypeFromString(input[_TYPE_KEY]);
    // var nData = input[_DATA_KEY] as Map;
    var nData = input[_DATA_KEY] as String;

    var nParts = input[_PARTS_KEY] as int;
    var nPos = input[_POSITION_KEY] as int;

    return Notification(nType, data: nData, parts: nParts, position: nPos);
  }

  Map toMap() {
    return <String, dynamic>{
      _TYPE_KEY: notificationTypeToString(this.notificationType),
      _DATA_KEY: this.data,
    };
  }

  List<Map> toDataChunks() {
    var msgChunks = <Map<String, dynamic>>[];

    var b64Data = base64.encode(utf8.encode(this.data.toString()));
    var b64Len = b64Data.length;
    var chunks = (b64Len / _MESSAGE_CHUNK_MAX_SIZE).ceil();
    // var mod = b64Len % _MESSAGE_CHUNK_MAX_SIZE;
    // if (mod > 0) chunks++;

    var currChunk = 1;
    var currPos = 0;
    var chunkEnd = _MESSAGE_CHUNK_MAX_SIZE;
    while (true) {
      // if im on the last chunk
      if (currChunk == chunks) {
        // add the rest of the string then break out
        msgChunks.add(chunkMap(chunks, currChunk, b64Data.substring(currPos)));
        break;
      }

      // if im not on the last chunk
      // get a substring from current position + 1500 (to give buffer for 2048 byte limit)
      msgChunks.add(
          chunkMap(chunks, currChunk, b64Data.substring(currPos, chunkEnd)));
      // then increase all positions
      currChunk++;
      currPos = chunkEnd;
      chunkEnd += _MESSAGE_CHUNK_MAX_SIZE;
    }

    return msgChunks;
  }

  Map<String, dynamic> chunkMap(int totalChunks, int currChunk, String data) =>
      {
        _TYPE_KEY: notificationTypeToString(this.notificationType),
        _DATA_KEY: data,
        _PARTS_KEY: totalChunks,
        _POSITION_KEY: currChunk,
      };
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
  SyncInitStepOne,
  SyncInitStepTwo,
  SyncInitStepThree,
  SyncInitStepFour,
  SyncUpdate,
  SyncUpdateReceived,
  Unknown
}
