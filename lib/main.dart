/*
 * Created by Ilan Rasekh on 2019/9/27
 * Copyright (c) 2019 Pseudorand Development. All rights reserved.
 */

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app_lock/flutter_app_lock.dart';
import 'package:local_auth/local_auth.dart';
import 'package:nullpass/screens/app.dart';
import 'package:nullpass/screens/lockScreen.dart';
import 'package:nullpass/services/logging.dart';
// TODO: Re-enable after secure_screen_switcher is updated for AGP 8.1+
// import 'package:secure_screen_switcher/secure_screen_switcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO: Re-enable after secure_screen_switcher is updated for AGP 8.1+
  // await SecureScreenSwitcher.secureApp();

  assert((isDebug = true) || true);

  final localAuth = LocalAuthentication();
  canCheckBiometrics = await localAuth.canCheckBiometrics || await localAuth.isDeviceSupported();

  // await getAppPreLoadSharedPreferences();
  sharedPrefs = await SharedPreferences.getInstance();
  bool showLoginScreen = ((sharedPrefs.containsKey(AuthOnLoadPrefKey))
      ? sharedPrefs.getBool(AuthOnLoadPrefKey) ?? false
      : false);
  Duration loginTimeout = Duration(
    seconds: ((sharedPrefs.containsKey(AuthTimeoutSecondsPrefKey))
        ? sharedPrefs.getDouble(AuthTimeoutSecondsPrefKey)?.round() ?? 300
        : 300),
  );

  await runZonedGuarded(
    () async => runApp(AppLock(
      builder: (args) => const NullPassApp(),
      // lockScreen: _TmpLockScreen(),
      lockScreen: const LockScreen(),
      enabled: canCheckBiometrics && showLoginScreen,
      backgroundLockLatency: loginTimeout,
    )),
    (error, stackTrace) => Log.debug(error),
    zoneSpecification: ZoneSpecification(
      handleUncaughtError: (self, parent, zone, error, stackTrace) =>
          Log.debug(error),
      errorCallback: (self, parent, zone, error, stackTrace) {
        Log.debug(error);
        return AsyncError(error, stackTrace);
      },
    ),
  );
}

class _TmpLockScreen extends StatefulWidget {
  @override
  _TmpLockScreenState createState() => _TmpLockScreenState();
}

class _TmpLockScreenState extends State<_TmpLockScreen> {
  void unlock() {
    final appLock = AppLock.of(context);
    if (appLock != null) {
      appLock.didUnlock();
    }
  }

  @override
  Widget build(BuildContext context) {
    var title = "NullPass";
    return MaterialApp(
      title: title,
      home: Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: Container(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  child: const Text("Login"),
                  onPressed: () async {
                    unlock();
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
