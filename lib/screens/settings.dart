/*
 * Created by Ilan Rasekh on 2019/10/2
 * Copyright (c) 2019 Pseudorand Development. All rights reserved.
 */

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:nullpass/common.dart';
import 'package:nullpass/models/secret.dart';
import 'package:nullpass/models/vault.dart';
import 'package:nullpass/screens/appDrawer.dart';
import 'package:nullpass/services/datastore.dart';

class Settings extends StatefulWidget {
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final _title = 'Settings';
  int _secretLength = 512;
  bool _alphaCharacters = true;
  bool _numericCharacters = true;
  bool _symbolCharacters = true;
  bool _inAppWebpages = true;

  String _importText = '';

  @override
  void initState() {
    super.initState();

    bool spSet = sharedPrefs.getBool(SharedPrefSetupKey);
    if (spSet == null || !spSet) setupSharedPreferences();

    _secretLength = sharedPrefs.getInt(SecretLengthPrefKey);
    _alphaCharacters = sharedPrefs.getBool(AlphaCharactersPrefKey);
    _numericCharacters = sharedPrefs.getBool(NumericCharactersPrefKey);
    _symbolCharacters = sharedPrefs.getBool(SymbolCharactersPrefKey);
    _inAppWebpages = sharedPrefs.getBool(InAppWebpagesPrefKey);
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
                  child: Text(
                    'Default Password Generation',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  padding: new EdgeInsets.fromLTRB(10, 20, 20, 20)),
              ListTile(
                title: Text('Password Length'),
                subtitle: Text(
                    'By default when generating a new password, make that password $_secretLength characters long.'),
                trailing: Container(
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
                      decoration: InputDecoration(border: InputBorder.none)),
                ),
                contentPadding: new EdgeInsets.fromLTRB(15, 10, 20, 10),
              ),
              ListTile(
                title: Text('Include Alpha Characters'),
                subtitle: Text(
                    'Should alphabet characters be included into passwords by default.'),
                trailing: Switch(
                    value: _alphaCharacters,
                    onChanged: (value) async {
                      sharedPrefs.setBool(AlphaCharactersPrefKey, value);
                      setState(() {
                        this._alphaCharacters = value;
                      });
                    }),
                contentPadding: new EdgeInsets.fromLTRB(15, 10, 10, 10),
              ),
              ListTile(
                title: Text('Include Numeric Characters'),
                subtitle: Text(
                    'Should numeric characters be included into passwords by default.'),
                trailing: Switch(
                    value: _numericCharacters,
                    onChanged: (value) async {
                      sharedPrefs.setBool(NumericCharactersPrefKey, value);
                      setState(() {
                        this._numericCharacters = value;
                      });
                    }),
                contentPadding: new EdgeInsets.fromLTRB(15, 5, 10, 10),
              ),
              ListTile(
                title: Text('Include Symbol Characters'),
                subtitle: Text(
                    'Should symbol characters be included into passwords by default.'),
                trailing: Switch(
                    value: _symbolCharacters,
                    onChanged: (value) async {
                      sharedPrefs.setBool(SymbolCharactersPrefKey, value);
                      setState(() {
                        this._symbolCharacters = value;
                      });
                    }),
                contentPadding: new EdgeInsets.fromLTRB(15, 5, 10, 10),
              ),
              Container(
                  color: Colors.blueGrey[100],
                  child: Text(
                    'Default Password Generation',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  padding: new EdgeInsets.fromLTRB(10, 20, 20, 20)),
              ListTile(
                title: Text('Open websites in app'),
                subtitle: Text(
                    'If on, launching websites will be opened in the app, otherwise they will be opened externally.'),
                trailing: Switch(
                    value: _inAppWebpages,
                    onChanged: (value) {
                      sharedPrefs
                          .setBool(InAppWebpagesPrefKey, value)
                          .then((worked) {
                        setState(() {
                          this._inAppWebpages = value;
                        });
                      });
                    }),
                contentPadding: new EdgeInsets.fromLTRB(15, 5, 10, 10),
              ),
              ListTile(
                title: Text('Logging'),
                subtitle: Text(
                    'If on, launching websites will be opened in the app, otherwise they will be opened externally.'),
                trailing: Switch(
                    value: _inAppWebpages,
                    onChanged: (value) {
                      sharedPrefs
                          .setBool(InAppWebpagesPrefKey, value)
                          .then((worked) {
                        setState(() {
                          this._inAppWebpages = value;
                        });
                      });
                    }),
                contentPadding: new EdgeInsets.fromLTRB(15, 5, 10, 10),
              ),
              Container(
                  color: Colors.blueGrey[100],
                  child: Text(
                    'Data Management',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  padding: new EdgeInsets.fromLTRB(10, 20, 20, 20)),
              ListTile(
                title: Text('Import Passwords'),
                subtitle: Text(
                    'Import password data that has been backed up or extracted from an external source. The file must be a NullPass JSON export or a csv format with the header row.'),
                contentPadding: new EdgeInsets.fromLTRB(15, 5, 10, 10),
                trailing: IconButton(
                  icon: Icon(FontAwesomeIcons.fileDownload,
                      size: 20, color: Colors.blue),
                  onPressed: () async {
                    showDialog<void>(
                      context: context,
                      // uncomment below to force user to tap button and not just tap outside the alert!
                      // barrierDismissible: false,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Import Data'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
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
                            FlatButton(
                                child: Text('Cancel'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                }),
                            FlatButton(
                                child: Text('Import'),
                                onPressed: () async {
                                  await importSecretsAndVaults(_importText);
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
                title: Text('Export NullPass Data'),
                subtitle: Text(
                    'Export your NullPass data in JSON fromat and save it to a file. (NOTE: at this time this is not encrypted and is considered insecure)'),
                contentPadding: new EdgeInsets.fromLTRB(15, 5, 10, 10),
                trailing: IconButton(
                  icon: Icon(FontAwesomeIcons.fileUpload,
                      size: 20, color: Colors.blue),
                  onPressed: () async {
                    showDialog<void>(
                      context: context,
                      // uncomment below to force user to tap button and not just tap outside the alert!
                      // barrierDismissible: false,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Export Data'),
                          content: Text(
                              'This will export all of your password data. Be sure before proceeding as this will decrypt all data and copy it to your clipboard which can be available to many applications and services.'),
                          actions: <Widget>[
                            FlatButton(
                                child: Text('Cancel'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                }),
                            FlatButton(
                                child: Text('Export'),
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
                contentPadding: new EdgeInsets.fromLTRB(15, 5, 10, 10),
                title: Text("Create Default Vault"),
                subtitle: Text(
                  "If there is no default vault, then create one. This is only needed if you delete all data and do not run an import from a NullPass export",
                ),
                trailing: IconButton(
                  icon: Icon(Icons.add_circle, color: Colors.blue),
                  onPressed: () async {
                    var v = await NullPassDB.instance.createDefaultVault();
                    sharedPrefs.setString(DefaultVaultIDPrefKey, v.uid);
                  },
                ),
              ),
              ListTile(
                title: Text('Delete All Data'),
                subtitle: Text(
                    'Permanantly delete all data. (NOTE: THIS IS NOT RECOVERABLE)'),
                contentPadding: new EdgeInsets.fromLTRB(15, 5, 10, 10),
                // trailing: IconButton(icon: Icon(FontAwesomeIcons.trash, size: 18, color: Colors.red)),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    showDialog<void>(
                      context: context,
                      // uncomment below to force user to tap button and not just tap outside the alert!
                      // barrierDismissible: false,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Delete All Data'),
                          content: Text(
                              'This will delete all password data. Be sure before proceeding as this is not undoable or recoverable.'),
                          actions: <Widget>[
                            FlatButton(
                                child: Text('Cancel'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                }),
                            FlatButton(
                                child: Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                                onPressed: () async {
                                  NullPassDB npDB = NullPassDB.instance;
                                  await npDB.deleteAllDevices();
                                  await npDB.deleteAllSyncs();
                                  await npDB.deleteAllSecrets();
                                  await npDB.deleteAllVaults();
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
  NullPassDB npDB = NullPassDB.instance;
  List<Secret> secretsList = await npDB.getAllSecrets() ?? <Secret>[];
  List<Vault> vaultsList = await npDB.getAllVaults() ?? <Vault>[];

  List<Map<String, dynamic>> secretsJsonList = <Map<String, dynamic>>[];
  secretsList.forEach((s) => secretsJsonList.add(s.toJson()));

  List<Map<String, dynamic>> vaultsJsonList = <Map<String, dynamic>>[];
  vaultsList.forEach((v) => vaultsJsonList.add(v.toJson()));

  await Clipboard.setData(ClipboardData(
    text: jsonEncode(<String, dynamic>{
      "secrets": secretsJsonList,
      "vaults": vaultsJsonList
    }),
  ));
}

Future<void> importSecretsAndVaults(String input) async {
  NullPassDB npDB = NullPassDB.instance;

  Map<String, dynamic> decodedInput = jsonDecode(input);
  // var secretsJsonList = decodedInput["secrets"];
  // var vaultsJsonList = decodedInput["vaults"];

  var secretsList = <Secret>[];
  var vaultsList = <Vault>[];

  (decodedInput["secrets"] as List)
      .forEach((sMap) => secretsList.add(Secret.fromJson(sMap)));
  (decodedInput["vaults"] as List)
      .forEach((vMap) => vaultsList.add(Vault.fromMap(vMap)));

  // await npDB.bulkInsertSecrets(secretsListFromJsonString(input));
  await npDB.bulkInsertVaults(vaultsList);
  await npDB.bulkInsertSecrets(secretsList);
}
