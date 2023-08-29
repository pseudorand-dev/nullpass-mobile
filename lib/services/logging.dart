/*
 * Created by Ilan Rasekh on 2020/3/8
 * Copyright (c) 2020 Pseudorand Development. All rights reserved.
 */

import 'dart:developer' as developer;

// Is the App in Debug Mode
bool isDebug = false;

// The package name to log under
const String _logPackage = "dev.pseudorand.nullpass";

//              0           100      250    500   1000  1500    1750   2000
enum LogLevel { everything, verbose, debug, info, warn, error, fatal, panic }

class Log {
  static LogLevel? logLevel;

  static void debug(dynamic message,
      {String? source, Object? error, StackTrace? stackTrace, int severity: 250}) {
    if (isDebug) {
      developer.log(
        "[DEBUG] " + message.toString(),
        name: _logPackage,
        time: DateTime.now(),
      );
    }
  }

  static void error(dynamic message,
      {String? source,
      Object? error,
      StackTrace? stackTrace,
      int severity: 1500}) {
    developer.log(
      "[ERROR] " + message.toString(),
      name: _logPackage,
      time: DateTime.now(),
    );
  }
}
