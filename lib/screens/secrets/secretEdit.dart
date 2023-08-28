/*
 * Created by Ilan Rasekh on 2019/10/2
 * Copyright (c) 2019 Pseudorand Development. All rights reserved.
 */

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:nullpass/common.dart';
import 'package:nullpass/models/auditRecord.dart';
import 'package:nullpass/models/secret.dart';
import 'package:nullpass/models/vault.dart';
import 'package:nullpass/screens/secrets/secretGenerate.dart';
import 'package:nullpass/services/datastore.dart';
import 'package:nullpass/services/logging.dart';
import 'package:nullpass/services/otp_scanning.dart';
import 'package:nullpass/services/sync.dart';
import 'package:nullpass/widgets.dart';
import 'package:uuid/uuid.dart';
import 'package:validators/validators.dart';

enum SecretEditType { Create, Update }

class SecretEdit extends StatefulWidget {
  final Secret secret;
  final SecretEditType edit;

  SecretEdit({Key key, @required this.secret, @required this.edit})
      : super(key: key);

  @override
  _CreateSecretState createState() => _CreateSecretState();
}

class _CreateSecretState extends State<SecretEdit> {
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
  Secret _secret;
  TextEditingController _passwordController = new TextEditingController();
  TextEditingController _otpCodeController = new TextEditingController();
  TextEditingController _otpTitleController = new TextEditingController();

  bool _loading = true;
  Map<String, Vault> vaults;
  Map<String, bool> selectedVaults;
  String defaultVault;
  String newVaultName;

  // Submit sends the new password data to the db to be saved then pop's up one level
  void submit(BuildContext context) async {
    // First validate form.
    if (this._formKey.currentState.validate()) {
      _formKey.currentState.save(); // Save our form now.

      // SAVE
      if (_secret.uuid == null || !isUUID(_secret.uuid.trim(), '4')) {
        _secret.uuid = (new Uuid()).v4();
      }
      _secret.vaults = [];
      selectedVaults.forEach((f, val) {
        if (val) _secret.vaults.add(f);
      });

      if (_secret.otpCode == null || _secret.otpCode.trim().isEmpty) {
        _secret.otpTitle = null;
      } else {
        _secret.otpCode = _secret.otpCode.trim().toUpperCase();
      }

      if (_secret.isOTPTitleStored()) {
        _secret.otpTitle = _secret.otpTitle.trim();
      }

      NullPassDB helper = NullPassDB.instance;
      bool success = false;
      if (widget.edit == SecretEditType.Create) {
        var now = DateTime.now().toUtc();
        _secret.created = now;
        _secret.lastModified = now;
        success = await helper.insertSecret(_secret);
        Log.debug('inserted row(s) - $success');
        // await showSnackBar(context, 'Created!');

        if (success) {
          await NullPassDB.instance.addAuditRecord(AuditRecord(
            type: AuditType.SecretCreated,
            message: 'The "${_secret.nickname}" secret was created.',
            secretsReferenceId: <String>{_secret.uuid},
            vaultsReferenceId: _secret.vaults.toSet(),
            date: _secret.created,
          ));

          // Sync changes to appropriate parties
          Sync.instance.sendSecretAdded(_secret);
        }
      } else if (widget.edit == SecretEditType.Update) {
        _secret.lastModified = DateTime.now().toUtc();
        success = await helper.updateSecret(_secret);
        Log.debug('updated row(s) - $success');
        // await showSnackBar(context, 'Updated!');

        if (success) {
          await NullPassDB.instance.addAuditRecord(AuditRecord(
            type: AuditType.SecretUpdated,
            message: 'The "${_secret.nickname}" secret was updated.',
            secretsReferenceId: <String>{_secret.uuid},
            vaultsReferenceId: _secret.vaults.toSet(),
            date: _secret.lastModified,
          ));

          // Sync changes to appropriate parties
          Sync.instance.sendSecretUpdated(_secret);
        }
      }

      Navigator.pop(context, 'true');
    }
  }

  @override
  void initState() {
    super.initState();
    if (_secret == null) {
      _secret = (widget.secret != null
          ? widget.secret
          : new Secret(nickname: '', website: '', username: '', message: ''));
    }

    _otpCodeController.text = _secret.otpCode ?? '';
    _otpTitleController.text =
        _secret.isOTPTitleStored() ? _secret.otpTitle : '';

    vaults = <String, Vault>{};
    selectedVaults = <String, bool>{};

    defaultVault = sharedPrefs.getString(DefaultVaultIDPrefKey) ?? "";

    NullPassDB.instance.getAllInternallyManagedVaults().then((vaultsList) {
      vaultsList.forEach((v) {
        vaults[v.uid] = v;
        selectedVaults[v.uid] =
            (((this._secret.vaults == null || this._secret.vaults.isEmpty) &&
                    v.uid == defaultVault) ||
                _secret.vaults.contains(v.uid));
      });
      setState(() {
        _loading = false;
      });
    });
  }

  void setPassword(String value) {
    setState(() {
      _secret.message = value;
    });
    _setControllerTextAndMoveCursor(_passwordController, value);
  }

  List<Widget> _generateChips(BuildContext context) {
    var widgetList = <Widget>[];

    this.vaults.forEach((uid, vault) {
      widgetList.add(NullPassFilterChip(
        label: vault.nickname,
        isSelected: this.selectedVaults[uid],
        onSelected: (isSelected) {
          setState(() {
            this.selectedVaults[uid] = isSelected;
          });
        },
      ));
    });

    // /*
    widgetList.add(ActionChip(
      label: Text(
        "Add",
        style: TextStyle(color: Colors.black),
      ),
      avatar: CircleAvatar(
        child: Text(
          "+",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
      ),
      onPressed: () async {
        showDialog<void>(
          context: context,
          // uncomment below to force user to tap button and not just tap outside the alert!
          // barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Add a new Vault'),
              content: TextFormField(
                initialValue: "",
                decoration: InputDecoration(labelText: 'New Vault'),
                onChanged: (input) {
                  newVaultName = input;
                },
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    newVaultName = "";
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Add'),
                  onPressed: () async {
                    // NullPassDB npDB = NullPassDB.instance;
                    // await npDB.deleteAllSecrets();
                    var v = Vault(
                        nickname: newVaultName,
                        manager: VaultManager.Internal,
                        managerId: Vault.InternalSourceID,
                        isDefault: false);
                    var added = await NullPassDB.instance.insertVault(v);
                    newVaultName = "";
                    if (added) {
                      await NullPassDB.instance.addAuditRecord(AuditRecord(
                        type: AuditType.VaultCreated,
                        message: 'The "${v.nickname}" vault was added.',
                          vaultsReferenceId: <String>{v.uid},
                          date: DateTime.now().toUtc(),
                        ));
                        setState(() {
                          this.vaults[v.uid] = v;
                          this.selectedVaults[v.uid] = true;
                        });
                      }
                      Navigator.of(context).pop();
                    })
              ],
            );
          },
        );
      },
      backgroundColor: Colors.white,
      shape: StadiumBorder(side: BorderSide(color: Colors.blue)),
    ));
    // */

    return widgetList;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: (widget.edit == SecretEditType.Create)
              ? Text('New Secret')
              : ((widget.edit == SecretEditType.Update)
                  ? Text('Update Secret')
                  : Text('Secret Action')),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        body: new Container(
          child: CenterLoader(),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: (widget.edit == SecretEditType.Create)
              ? Text('New Secret')
              : ((widget.edit == SecretEditType.Update)
                  ? Text('Update Secret')
                  : Text('Secret Action')),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        body: new Container(
          padding: new EdgeInsets.all(20.0),
          child: new Form(
            key: this._formKey,
            child: new ListView(
              children: <Widget>[
                ListTile(
                  title: TextFormField(
                    onChanged: (value) {
                      setState(() {
                        _secret.nickname = value;
                      });
                      Log.debug('new nickname ${_secret.nickname}');
                    },
                    initialValue: _secret.nickname,
                    decoration: InputDecoration(
                        labelText: 'Nickname', border: InputBorder.none),
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'The Nickname field cannot be empty';
                      }
                      return null;
                    },
                  ),
                ),
                FormDivider(),
                ListTile(
                  title: TextFormField(
                    onChanged: (value) {
                      setState(() {
                        _secret.website = value;
                      });
                      Log.debug('new website ${_secret.website}');
                    },
                    initialValue: _secret.website,
                    decoration: InputDecoration(
                        labelText: 'Website', border: InputBorder.none),
                    keyboardType: TextInputType.url,
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'The Website field cannot be empty';
                      }
                      return null;
                    },
                  ),
                ),
                FormDivider(),
                ListTile(
                  title: TextFormField(
                    onChanged: (value) {
                      setState(() {
                        _secret.username = value;
                      });
                      Log.debug('new username ${_secret.username}');
                    },
                    initialValue: _secret.username,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      border: InputBorder.none,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'The Username field cannot be empty';
                      }
                      return null;
                    },
                  ),
                ),
                FormDivider(),
                PasswordInput(
                  onChange: (value) {
                    setState(() {
                      _secret.message = value;
                    });
                    Log.debug('new password ${_secret.message}');
                  },
                  controller: _passwordController,
                  initialValue: _secret.message,
                  setPassword: setPassword,
                ),
                FormDivider(),
                ListTile(
                  title: TextFormField(
                    textCapitalization: TextCapitalization.characters,
                    controller: _otpCodeController,
                    onChanged: (value) {
                      setState(() {
                        _secret.otpCode = value.toUpperCase();
                      });
                      Log.debug('new otpCode ${_secret.otpCode}');
                    },
                    decoration: InputDecoration(
                        labelText: 'One-Time Passcode',
                        border: InputBorder.none),
                    validator: (value) {
                      if (value.trim().isNotEmpty &&
                          _secret.getOnetimePasscode().trim() == '') {
                        return 'The One-Time Passcode provided is invalid';
                      }
                      return null;
                    },
                  ),
                  trailing: IconButton(
                    icon: Icon(MdiIcons.qrcodeScan),
                    onPressed: () async {
                      try {
                        var results = await OtpQrScan.scan();
                        var title = results.name;
                        if (!title.contains(':') &&
                            !title.contains('(') &&
                            !title.contains(' - ')) {
                          title = '${results.issuer} (${title})';
                        }
                        setState(() {
                          _secret.otpCode = results.secret.toUpperCase();
                          _secret.otpTitle = title.trim();
                        });
                        _setControllerTextAndMoveCursor(
                          _otpCodeController,
                          _secret.otpCode.toUpperCase(),
                        );
                        _setControllerTextAndMoveCursor(
                          _otpTitleController,
                          _secret.otpTitle?.trim(),
                        );
                        Log.debug('new otp secret "${_secret.otpCode}"');
                        Log.debug('new otp title "${_secret.otpTitle}"');
                      } catch (e) {
                        Log.error('Failed to scan QR code', stackTrace: e);
                      }
                    },
                  ),
                ),
                FormDivider(),
                ListTile(
                  title: TextFormField(
                    controller: _otpTitleController,
                    enabled: (_secret.otpCode != null &&
                        _secret.otpCode.trim().isNotEmpty),
                    onChanged: (value) {
                      setState(() {
                        _secret.otpTitle = value?.trim();
                      });
                      Log.debug('new otpTitle ${_secret.otpTitle}');
                    },
                    decoration: InputDecoration(
                        labelText: 'Optional OTP Title',
                        border: InputBorder.none),
                  ),
                ),
                FormDivider(),
                ListTile(
                  title: TextFormField(
                    onChanged: (value) {
                      setState(() {
                        _secret.notes = value;
                      });
                      Log.debug('new notes ${_secret.notes}');
                    },
                    initialValue: _secret.notes,
                    decoration: InputDecoration(
                        labelText: 'Notes', border: InputBorder.none),
                  ),
                ),
                FormDivider(),
                FormField(
                  builder: (fieldState) => ListTile(
                    contentPadding: EdgeInsets.fromLTRB(15, 15, 15, 0),
                    title: Text(
                      "Vaults",
                      style: TextStyle(
                        color: Colors.grey[600],
                        // fontSize: 12.5,
                      ),
                    ),
                    subtitle: Wrap(
                      children: _generateChips(context),
                      spacing: 5.0,
                      runSpacing: 5.0,
                    ),
                  ),
                  validator: (value) {
                    if (!selectedVaults.containsValue(true)) {
                      // TODO: create an error text widget and set it here
                      return 'You must select at least one vault to add your secret to';
                    }
                    return null;
                  },
                ),
                FormDivider(),
                ListTile(
                  title: ElevatedButton(
                    onPressed: () {
                      submit(context);
                    },
                    child: Text(
                      'Save',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                        Colors.blue,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.green,
          onPressed: () async {
            final result = await showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  return new SecretGenerate(inEditor: true);
                });
            if (result != null && result.toString().trim() != '') {
              _secret.message = result.toString();
              setPassword(_secret.message);
            }
          },
          tooltip: 'Generate',
          child: Icon(Icons.lock),
        ),
      );
    }
  }
}

class PasswordInput extends StatefulWidget {
  final Function onChange;
  final String initialValue;
  final TextEditingController controller;
  final Function setPassword;

  PasswordInput(
      {Key key,
      @required this.onChange,
      @required this.controller,
      @required this.setPassword,
      this.initialValue = ''})
      : super(key: key);

  @override
  _PasswordInputState createState() => _PasswordInputState();
}

class _PasswordInputState extends State<PasswordInput> {
  bool _visible = false;
  String _initialValue;
  TextEditingController _controller;
  Function _setPassword;

  @override
  void initState() {
    super.initState();
    if (_initialValue == null) {
      _initialValue = (widget.initialValue != null ? widget.initialValue : '');
    }
    _controller = widget.controller;
    _controller.text = _initialValue;
    _setPassword = widget.setPassword;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: TextFormField(
        controller: _controller,
        onChanged: (value) {
          widget.onChange(value);
        },
        decoration: InputDecoration(
          labelText: 'Password',
          border: InputBorder.none,
        ),
        obscureText: !_visible,
        validator: (value) {
          if (value.isEmpty) {
            return 'The Password field cannot be empty';
          }
          return null;
        },
      ),
      trailing: Container(
        width: 100,
        child: Row(
          children: <Widget>[
            IconButton(
              icon: _visible
                  ? new Icon(FontAwesomeIcons.solidEye, size: 20)
                  : new Icon(FontAwesomeIcons.solidEyeSlash, size: 20),
              onPressed: () {
                // _initialValue = this.widget.
                setState(() {
                  _visible = !_visible;
                });
              },
            ),
            IconButton(
              // icon: new Icon(FontAwesomeIcons.lock, size: 20),
              icon: new Icon(Icons.lock),
              onPressed: () async {
                final result = await showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return new SecretGenerate(inEditor: true);
                    });
                if (result != null && result.toString().trim() != '') {
                  _setPassword(result.toString());
                  setState(() {
                    _initialValue = result.toString();
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

void _setControllerTextAndMoveCursor(
  TextEditingController controller,
  String text,
) {
  controller.text = text;
  controller.selection = TextSelection.fromPosition(
    TextPosition(offset: controller.text.length),
  );
}
