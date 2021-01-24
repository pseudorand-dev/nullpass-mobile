import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_lock/flutter_app_lock.dart';
import 'package:local_auth/auth_strings.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:nullpass/common.dart';
import 'package:nullpass/services/logging.dart';

class LockScreen extends StatefulWidget {
  @override
  _LockScreenState createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final String _title = "NullPass";
  LocalAuthentication localAuth;

  @override
  void initState() {
    super.initState();
    localAuth = LocalAuthentication();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await authenticate();
    });
  }

  Future<void> authenticate() async {
    try {
      if (await LocalAuthentication().canCheckBiometrics) {
        bool didAuthenticate = await localAuth.authenticateWithBiometrics(
          androidAuthStrings: (Platform.isAndroid)
              ? AndroidAuthMessages(
                  signInTitle: "Unlock NullPass",
                  fingerprintHint: "",
                )
              : null,
          iOSAuthStrings: IOSAuthMessages(),
          localizedReason: (Platform.isAndroid) ? "" : "Unlock NullPass",
          stickyAuth: true,
          useErrorDialogs: false,
        );
        if (didAuthenticate) {
          unlock();
        }
      }
    } on PlatformException catch (e) {
      if (e.code == auth_error.passcodeNotSet) {
        Log.debug("The user has not set a passcode:\n\t$e");
      } else if (e.code == auth_error.notEnrolled) {
        Log.debug(
            "The user has not enrolled biometric data on the device:\n\t$e");
      } else if (e.code == auth_error.notAvailable) {
        Log.debug("The biometric scanner not available on this device:\n\t$e");
      } else if (e.code == auth_error.otherOperatingSystem) {
        Log.debug("The OS is not Android or iOS:\n\t$e");
      } else if (e.code == auth_error.lockedOut) {
        Log.debug(
            "The user is currently locked out please try again later:\n\t$e");
      } else if (e.code == auth_error.permanentlyLockedOut) {
        Log.debug("The user is permanently locked out:\n\t$e");
      } else {
        Log.debug(
            "An unknown error occurred while trying to authenticate the user:\n\t$e");
      }
    }
  }

  void unlock() {
    AppLock.of(context).didUnlock();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      home: Scaffold(
        appBar: AppBar(
          title: Text(_title),
          centerTitle: true,
        ),
        body: Container(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: EdgeInsets.all(24),
                  child: RaisedButton(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(42.0),
                      side: BorderSide(color: Theme.of(context).accentColor),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        "Unlock NullPass",
                        style: TextStyle(
                          backgroundColor: Colors.transparent,
                          color: Theme.of(context).accentColor,
                          fontSize: 30,
                        ),
                      ),
                    ),
                    color: Colors.white,
                    onPressed: () async {
                      await authenticate();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}