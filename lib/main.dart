/*
 * Created by Ilan Rasekh on 2019/9/27
 * Copyright (c) 2019 Pseudorand Development. All rights reserved.
 */

import 'package:flutter/material.dart';
import 'package:flutter_app_lock/flutter_app_lock.dart';
import 'package:nullpass/screens/app.dart';
// import 'package:nullpass/screens/lockScreen.dart';
import 'package:secure_screen_switcher/secure_screen_switcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SecureScreenSwitcher.secureApp();

  // await getAppPreLoadSharedPreferences();
  var sp = await SharedPreferences.getInstance();
  bool showLoginScreen = ((sp.containsKey(AuthOnLoadPrefKey))
      ? sp.getBool(AuthOnLoadPrefKey)
      : false);
  Duration loginTimeout = Duration(
    seconds: ((sp.containsKey(AuthTimeoutSecondsPrefKey))
        ? sp.getDouble(AuthTimeoutSecondsPrefKey).round()
        : 1),
  );

  runApp(
    AppLock(
      builder: (args) => NullPassApp(),
      lockScreen: TmpLockScreen(),
      // lockScreen: LockScreen(),
      enabled: showLoginScreen,
      backgroundLockLatency: loginTimeout,
    ),
  );
}

class TmpLockScreen extends StatefulWidget {
  @override
  _TmpLockScreenState createState() => _TmpLockScreenState();
}

class _TmpLockScreenState extends State<TmpLockScreen> {
  void unlock() {
    AppLock.of(context).didUnlock();
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
                RaisedButton(
                  child: Text("Login"),
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
