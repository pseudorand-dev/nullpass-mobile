/*
 * Created by Ilan Rasekh on 2020/3/8
 * Copyright (c) 2020 Pseudorand Development. All rights reserved.
 */

import 'dart:developer' as developer;

// Is the App in Debug Mode
bool isDebug = false;

// The package name to log under
const String _logPackage = "dev.pseudorand.nullpass";

enum LogLevel { everything, verbose, debug, info, warn, error, fatal, panic }

class Log {
  static LogLevel logLevel;

  static void debug(dynamic message,
      {String source, Object error, StackTrace stackTrace, int severity: 0}) {
    if (isDebug) {
      developer.log(message.toString(),
          name: _logPackage, time: DateTime.now());
    }
  }
}
