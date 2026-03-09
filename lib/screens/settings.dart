/*
 * Created by Ilan Rasekh on 2019/10/2
 * Copyright (c) 2019 Pseudorand Development. All rights reserved.
 */

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_app_lock/flutter_app_lock.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:nullpass/common.dart';
import 'package:nullpass/models/auditRecord.dart';
import 'package:nullpass/models/secret.dart';
import 'package:nullpass/models/vault.dart';
import 'package:nullpass/screens/appDrawer.dart';
import 'package:nullpass/services/datastore.dart';
import 'package:nullpass/setup.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final _title = 'Settings';
  int _secretLength = 512;
  int _passwordPreviewFontSize = 20;
  double _authTimeoutSeconds = 300;
  bool _authOnLoad = false;
  bool _alphaCharacters = true;
  bool _numericCharacters = true;
  bool _symbolCharacters = true;
  bool _inAppWebpages = true;
  bool _syncAccessNotifications = true;

  String _importText = '';

  @override
  void initState() {
    super.initState();

    bool spSet = sharedPrefs.getBool(SharedPrefSetupKey) ?? false;
    if (!spSet) setupSharedPreferences(encryptionKeyCallback: () {});

    _secretLength = sharedPrefs.getInt(SecretLengthPrefKey) ?? 512;
    _alphaCharacters = sharedPrefs.getBool(AlphaCharactersPrefKey) ?? true;
    _numericCharacters = sharedPrefs.getBool(NumericCharactersPrefKey) ?? true;
    _symbolCharacters = sharedPrefs.getBool(SymbolCharactersPrefKey) ?? true;
    _inAppWebpages = sharedPrefs.getBool(InAppWebpagesPrefKey) ?? true;
    _syncAccessNotifications =
        sharedPrefs.getBool(SyncdDataNotificationsPrefKey) ?? true;
    _passwordPreviewFontSize =
        sharedPrefs.getInt(PasswordPreviewSizePrefKey) ?? 20;

    // Auth Options
    _authOnLoad = ((sharedPrefs.containsKey(AuthOnLoadPrefKey))
            ? sharedPrefs.getBool(AuthOnLoadPrefKey)
            : false) ??
        false;
    _authTimeoutSeconds = ((sharedPrefs.containsKey(AuthTimeoutSecondsPrefKey))
            ? sharedPrefs.getDouble(AuthTimeoutSecondsPrefKey)
            : 300) ??
        300;
  }

  String doubleToString(double input) {
    var str = _authTimeoutSeconds.toString();

    if (str.endsWith(".0")) str = str.substring(0, str.indexOf(".0"));

    return str;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      home: Scaffold(
        appBar: AppBar(
          title: Text(_title),
        ),
        drawer: AppDrawer(
            currentPage: NullPassRoute.Settings, reloadSecretList: () {}),
        body: Center(
          child: ListView(
            children: <Widget>[
              Container(
                  color: Colors.blueGrey[100],
                  padding: const EdgeInsets.fromLTRB(10, 20, 20, 20),
                  child: const Text(
                    'Default Password Generation',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  )),
              ListTile(
                title: const Text('Password Length'),
                subtitle: Text(
                    'By default when generating a new password, make that password $_secretLength characters long.'),
                trailing: SizedBox(
                  width: 50,
                  child: TextFormField(
                    textAlign: TextAlign.end,
                    keyboardType: TextInputType.number,
                    initialValue: _secretLength.toString(),
                    autocorrect: true,
                    onChanged: (value) async {
                      int tempVal = -1;
                      try {
                        tempVal = int.parse(value);
                      } catch (e) {}
                      if (tempVal < 1) tempVal = _secretLength;
                      sharedPrefs.setInt(SecretLengthPrefKey, tempVal);
                      setState(() {
                        _secretLength = tempVal;
                      });
                    },
                    decoration: const InputDecoration(border: InputBorder.none),
                  ),
                ),
                contentPadding: const EdgeInsets.fromLTRB(15, 10, 20, 10),
              ),
              ListTile(
                title: const Text('Include Alpha Characters'),
                subtitle: const Text(
                    'Should alphabet characters be included into passwords by default.'),
                trailing: Switch(
                    value: _alphaCharacters,
                    onChanged: (value) async {
                      sharedPrefs.setBool(AlphaCharactersPrefKey, value);
                      setState(() {
                        _alphaCharacters = value;
                      });
                    }),
                contentPadding: const EdgeInsets.fromLTRB(15, 10, 10, 10),
              ),
              ListTile(
                title: const Text('Include Numeric Characters'),
                subtitle: const Text(
                    'Should numeric characters be included into passwords by default.'),
                trailing: Switch(
                    value: _numericCharacters,
                    onChanged: (value) async {
                      sharedPrefs.setBool(NumericCharactersPrefKey, value);
                      setState(() {
                        _numericCharacters = value;
                      });
                    }),
                contentPadding: const EdgeInsets.fromLTRB(15, 5, 10, 10),
              ),
              ListTile(
                title: const Text('Include Symbol Characters'),
                subtitle: const Text(
                    'Should symbol characters be included into passwords by default.'),
                trailing: Switch(
                    value: _symbolCharacters,
                    onChanged: (value) async {
                      sharedPrefs.setBool(SymbolCharactersPrefKey, value);
                      setState(() {
                        _symbolCharacters = value;
                      });
                    }),
                contentPadding: const EdgeInsets.fromLTRB(15, 5, 10, 10),
              ),
              Container(
                color: Colors.blueGrey[100],
                padding: const EdgeInsets.fromLTRB(10, 20, 20, 20),
                child: const Text(
                  'App Security',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                enabled: canCheckBiometrics,
                title: const Text('Lock Screen'),
                subtitle: const Text(
                    'If on, an auth screen will be prompted everytime you load the app and upon returning from background (tacking into account the Background Lock Timeout), otherwise no authentication will be required to access your secrets.'),
                trailing: Switch(
                    value: !canCheckBiometrics ? false : _authOnLoad,
                    onChanged: !canCheckBiometrics
                        ? null
                        : (value) {
                            sharedPrefs
                                .setBool(AuthOnLoadPrefKey, value)
                                .then((worked) {
                              // TODO: causes a refresh of the screen and therefore requires better routing support to maintain current screen
                              // AppLock.of(context).setEnabled(value);
                              setState(() {
                                _authOnLoad = value;
                              });
                            });
                          }),
                contentPadding: const EdgeInsets.fromLTRB(15, 5, 10, 10),
              ),
              ListTile(
                enabled: canCheckBiometrics,
                title: const Text('Background Lock Timeout'),
                subtitle: const Text(
                  'The number of seconds the app is allowed to be in the background before requiring the lock screen to be shown. (Note: this will take effect on the next launch of the app)',
                ),
                trailing: SizedBox(
                  width: 50,
                  child: TextFormField(
                      enabled: canCheckBiometrics,
                      textAlign: TextAlign.end,
                      keyboardType: TextInputType.number,
                      initialValue: !canCheckBiometrics
                          ? "--"
                          : doubleToString(_authTimeoutSeconds),
                      autocorrect: true,
                      onChanged: (value) async {
                        double tempVal = -1.0;
                        try {
                          tempVal = double.parse(value);
                        } catch (e) {}
                        if (tempVal < 1) tempVal = _authTimeoutSeconds;
                        sharedPrefs.setDouble(
                            AuthTimeoutSecondsPrefKey, tempVal);
                        setState(() {
                          _authTimeoutSeconds = tempVal;
                        });
                      },
                      decoration: const InputDecoration(border: InputBorder.none)),
                ),
                contentPadding: const EdgeInsets.fromLTRB(15, 5, 20, 10),
              ),
              Container(
                color: Colors.blueGrey[100],
                padding: const EdgeInsets.fromLTRB(10, 20, 20, 20),
                child: const Text(
                  'App Specifics',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                title: const Text('Password Font Size'),
                subtitle: const Text(
                  'This will be the font size when password preview (the popup from long pressing on the password item in the details screens)',
                ),
                trailing: SizedBox(
                  width: 50,
                  child: TextFormField(
                      textAlign: TextAlign.end,
                      keyboardType: TextInputType.number,
                      initialValue: _passwordPreviewFontSize.toString(),
                      autocorrect: true,
                      onChanged: (value) async {
                        int tempVal = -1;
                        try {
                          tempVal = int.parse(value);
                        } catch (e) {}
                        if (tempVal < 1) tempVal = _passwordPreviewFontSize;
                        sharedPrefs.setInt(PasswordPreviewSizePrefKey, tempVal);
                        setState(() {
                          _passwordPreviewFontSize = tempVal;
                        });
                      },
                      decoration: const InputDecoration(border: InputBorder.none)),
                ),
                contentPadding: const EdgeInsets.fromLTRB(15, 5, 20, 10),
              ),
              ListTile(
                title: const Text('Open websites in app'),
                subtitle: const Text(
                    'If on, launching websites will be opened in the app, otherwise they will be opened externally.'),
                trailing: Switch(
                    value: _inAppWebpages,
                    onChanged: (value) {
                      sharedPrefs
                          .setBool(InAppWebpagesPrefKey, value)
                          .then((worked) {
                        setState(() {
                          _inAppWebpages = value;
                        });
                      });
                    }),
                contentPadding: const EdgeInsets.fromLTRB(15, 5, 10, 10),
              ),
              Container(
                color: Colors.blueGrey[100],
                padding: const EdgeInsets.fromLTRB(10, 20, 20, 20),
                child: const Text(
                  'Device Syncing',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                title: const Text('Notifications'),
                subtitle: const Text(
                    "Show me a notification everytime a password I have shared with another device is accessed. (Notes: This is when the password is edited, copied, or viewed; This occurs for vaults that are set to be 'Manage' or 'Read-Only')"),
                trailing: Switch(
                    value: _syncAccessNotifications,
                    onChanged: (value) {
                      sharedPrefs
                          .setBool(SyncdDataNotificationsPrefKey, value)
                          .then((worked) {
                        setState(() {
                          _syncAccessNotifications = value;
                        });
                      });
                    }),
                contentPadding: const EdgeInsets.fromLTRB(15, 5, 10, 10),
              ),
              Container(
                  color: Colors.blueGrey[100],
                  padding: const EdgeInsets.fromLTRB(10, 20, 20, 20),
                  child: const Text(
                    'Data Management',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  )),
              ListTile(
                title: const Text('Import Passwords'),
                subtitle: const Text(
                    'Import password data that has been backed up or extracted from an external source. The file must be a NullPass JSON export or a csv format with the header row.'),
                contentPadding: const EdgeInsets.fromLTRB(15, 5, 10, 10),
                trailing: IconButton(
                  icon: const Icon(FontAwesomeIcons.fileDownload,
                      size: 20, color: Colors.blue),
                  onPressed: () async {
                    showDialog<void>(
                      context: context,
                      // uncomment below to force user to tap button and not just tap outside the alert!
                      // barrierDismissible: false,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Import Data'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Text(
                                  'Paste a JSON blob containing a list of NullPass Secrets.'),
                              TextFormField(
                                maxLines: 10,
                                minLines: 1,
                                autofocus: true,
                                onChanged: (value) {
                                  setState(() {
                                    _importText = value;
                                  });
                                },
                              ),
                            ],
                          ),
                          actions: <Widget>[
                            TextButton(
                                child: const Text('Cancel'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                }),
                            TextButton(
                                child: const Text('Import'),
                                onPressed: () async {
                                  await importSecretsAndVaults(_importText);
                                  var v = await NullPassDB.instance
                                      .getDefaultVault();
                                  if (v != null) {
                                    sharedPrefs.setString(
                                        DefaultVaultIDPrefKey, v.uid);
                                  }
                                  Navigator.of(context).pop();
                                })
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              ListTile(
                title: const Text('Export NullPass Data'),
                subtitle: const Text(
                    'Export your NullPass data in JSON fromat and save it to a file. (NOTE: at this time this is not encrypted and is considered insecure)'),
                contentPadding: const EdgeInsets.fromLTRB(15, 5, 10, 10),
                trailing: IconButton(
                  icon: const Icon(FontAwesomeIcons.fileUpload,
                      size: 20, color: Colors.blue),
                  onPressed: () async {
                    showDialog<void>(
                      context: context,
                      // uncomment below to force user to tap button and not just tap outside the alert!
                      // barrierDismissible: false,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Export Data'),
                          content: const Text(
                              'This will export all of your password data. Be sure before proceeding as this will decrypt all data and copy it to your clipboard which can be available to many applications and services.'),
                          actions: <Widget>[
                            TextButton(
                                child: const Text('Cancel'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                }),
                            TextButton(
                                child: const Text('Export'),
                                onPressed: () async {
                                  await exportSecretsAndVaults();
                                  Navigator.of(context).pop();
                                })
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              ListTile(
                contentPadding: const EdgeInsets.fromLTRB(15, 5, 10, 10),
                title: const Text("Create Default Vault"),
                subtitle: const Text(
                  "If there is no default vault, then create one. This is only needed if you delete all data and do not run an import from a NullPass export",
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.blue),
                  onPressed: () async {
                    var v = await NullPassDB.instance.createDefaultVault();
                    if (v != null) {
                      sharedPrefs.setString(DefaultVaultIDPrefKey, v.uid);
                    }
                  },
                ),
              ),
              ListTile(
                title: const Text('Delete All Data'),
                subtitle: const Text(
                    'Permanantly delete all data. (NOTE: THIS IS NOT RECOVERABLE)'),
                contentPadding: const EdgeInsets.fromLTRB(15, 5, 10, 10),
                // trailing: IconButton(icon: Icon(FontAwesomeIcons.trash, size: 18, color: Colors.red)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    showDialog<void>(
                      context: context,
                      // uncomment below to force user to tap button and not just tap outside the alert!
                      // barrierDismissible: false,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Delete All Data'),
                          content: const Text(
                              'This will delete all password data. Be sure before proceeding as this is not undoable or recoverable.'),
                          actions: <Widget>[
                            TextButton(
                                child: const Text('Cancel'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                }),
                            TextButton(
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                                onPressed: () async {
                                  NullPassDB npDB = NullPassDB.instance;
                                  await npDB.deleteAllDevices();
                                  await npDB.deleteAllSyncs();
                                  await npDB.deleteAllSecrets();
                                  await npDB.deleteAllVaults();
                                  sharedPrefs.setString(
                                      DefaultVaultIDPrefKey, "");
                                  Navigator.of(context).pop();
                                })
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> exportSecretsAndVaults() async {
  // TODO: require re-authn (biometric validation) prior to allowing export of data
  NullPassDB npDB = NullPassDB.instance;
  List<Secret> secretsList = await npDB.getAllSecrets() ?? <Secret>[];
  List<Vault> vaultsList = await npDB.getAllVaults() ?? <Vault>[];

  Set<String> sids = <String>{};
  Set<String> vids = <String>{};

  List<Map<String, dynamic>> secretsJsonList = <Map<String, dynamic>>[];
  for (var s in secretsList) {
    secretsJsonList.add(s.toJson());
    sids.add(s.uuid);
  }

  List<Map<String, dynamic>> vaultsJsonList = <Map<String, dynamic>>[];
  for (var v in vaultsList) {
    vaultsJsonList.add(v.toJson());
    vids.add(v.uid);
  }

  await Clipboard.setData(ClipboardData(
    text: jsonEncode(<String, dynamic>{
      "secrets": secretsJsonList,
      "vaults": vaultsJsonList
    }),
  ));

  await NullPassDB.instance.addAuditRecord(AuditRecord(
    type: AuditType.AppDataExported,
    message: 'All Secret and Vault data was exported.',
    secretsReferenceId: sids,
    vaultsReferenceId: vids,
    date: DateTime.now().toUtc(),
  ));
}

Future<void> importSecretsAndVaults(String input) async {
  // TODO: require re-authn (biometric validation) prior to allowing import of data
  NullPassDB npDB = NullPassDB.instance;

  Map<String, dynamic> decodedInput = jsonDecode(input);
  // var secretsJsonList = decodedInput["secrets"];
  // var vaultsJsonList = decodedInput["vaults"];

  var secretsList = <Secret>[];
  var vaultsList = <Vault>[];

  Set<String> sids = <String>{};
  Set<String> vids = <String>{};

  for (var sMap in (decodedInput["secrets"] as List)) {
    var s = Secret.fromJson(sMap);
    secretsList.add(s);
    sids.add(s.uuid);
  }
  for (var vMap in (decodedInput["vaults"] as List)) {
    var v = Vault.fromMap(vMap);
    vaultsList.add(v);
    vids.add(v.uid);
  }

  // await npDB.bulkInsertSecrets(secretsListFromJsonString(input));
  await npDB.bulkInsertVaults(vaultsList);
  await npDB.bulkInsertSecrets(secretsList);
  await NullPassDB.instance.addAuditRecord(AuditRecord(
    type: AuditType.AppDataImported,
    message: 'Secret and Vault data was imported.',
    secretsReferenceId: sids,
    vaultsReferenceId: vids,
    date: DateTime.now().toUtc(),
  ));
}
