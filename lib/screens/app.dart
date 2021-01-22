/*
 * Created by Ilan Rasekh on 2019/9/27
 * Copyright (c) 2019 Pseudorand Development. All rights reserved.
 */

import 'package:flutter/material.dart';
import 'package:nullpass/common.dart';
import 'package:nullpass/models/secret.dart';
import 'package:nullpass/screens/secrets/secretList.dart';
import 'package:nullpass/services/datastore.dart';
import 'package:nullpass/services/logging.dart';
import 'package:nullpass/setup.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NullPassApp extends StatefulWidget {
  @override
  _NullPassAppState createState() => _NullPassAppState();
}

class _NullPassAppState extends State<NullPassApp> {
  List<Secret> _secrets = <Secret>[];
  bool _loading = true;
  static bool _completeSecretsPull = false;
  static bool _completeEncryptionKeyGeneration = false;

  Future<void> encryptionKeyCallback() async {
    _completeEncryptionKeyGeneration =
        sharedPrefs.getBool(EncryptionKeyPairSetupPrefKey);
    if (_completeEncryptionKeyGeneration && _completeSecretsPull) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> secretsPullCallback(List<Secret> result) async {
    _secrets = result;
    _completeSecretsPull = true;
    if (_completeEncryptionKeyGeneration && _completeSecretsPull) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    assert((isDebug = true) || true);

    if (isDebug) {
      // print('debug on');
      Log.debug('debug on');
    }

    setupNotifications().then((_) {
      // print('OneSignal Setup');
      Log.debug('OneSignal Setup');
    });

    if (sharedPrefs == null) {
      SharedPreferences.getInstance().then((sp) {
        sharedPrefs = sp;
        setupSharedPreferences(encryptionKeyCallback: encryptionKeyCallback);
      });
    } else {
      encryptionKeyCallback();
    }

    NullPassDB helper = NullPassDB.instance;

    helper.getAllSecrets().then(secretsPullCallback);
  }

  void _reloadSecretList(result) async {
    if (isTrue(result)) {
      NullPassDB npDB = NullPassDB.instance;
      List<Secret> sList = await npDB.getAllSecrets();
      setState(() {
        _secrets = sList;
      });
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'NullPass',
        theme: ThemeData(
          // This is the theme of your application.
          //
          // Try running your application with "flutter run". You'll see the
          // application has a blue toolbar. Then, without quitting the app, try
          // changing the primarySwatch below to Colors.green and then invoke
          // "hot reload" (press "r" in the console where you ran "flutter run",
          // or simply save your changes to "hot reload" in a Flutter IDE).
          // Notice that the counter didn't reset back to zero; the application
          // is not restarted.
          primarySwatch: Colors.blue,
        ),
        home: SecretList(
          loading: _loading,
          items: _secrets,
          reloadSecretList: _reloadSecretList,
        ));
  }
}
