/*
 * Created by Ilan Rasekh on 2019/10/2
 * Copyright (c) 2019 Pseudorand Development. All rights reserved.
 */

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:nullpass/common.dart';
import 'package:nullpass/models/auditRecord.dart';
import 'package:nullpass/models/secret.dart';
import 'package:nullpass/models/vault.dart';
import 'package:nullpass/screens/secrets/secretGenerate.dart';
import 'package:nullpass/services/datastore.dart';
import 'package:nullpass/services/logging.dart';
import 'package:nullpass/services/sync.dart';
import 'package:nullpass/widgets.dart';
import 'package:uuid/uuid.dart';
import 'package:validators/validators.dart';

enum SecretEditType { Create, Update }

class SecretEdit extends StatefulWidget {
  final Secret secret;
  final SecretEditType edit;

  const SecretEdit({super.key, required this.secret, required this.edit});

  @override
  _CreateSecretState createState() => _CreateSecretState();
}

class _CreateSecretState extends State<SecretEdit> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late Secret _secret;
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = true;
  late Map<String, Vault> vaults;
  late Map<String, bool> selectedVaults;
  String? defaultVault;
  String? newVaultName;

  // Submit sends the new password data to the db to be saved then pop's up one level
  void submit(BuildContext context) async {
    // First validate form.
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save(); // Save our form now.

      // SAVE
      if (!isUUID(_secret.uuid.trim(), '4')) {
        _secret.uuid = (const Uuid()).v4();
      }
      _secret.vaults = [];
      selectedVaults.forEach((f, val) {
        if (val) _secret.vaults.add(f);
      });

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
    _secret = widget.secret;

    vaults = <String, Vault>{};
    selectedVaults = <String, bool>{};

    // _secret.vaults.forEach((v) => )

    defaultVault = sharedPrefs.getString(DefaultVaultIDPrefKey) ?? "";

    NullPassDB.instance.getAllInternallyManagedVaults().then((vaultsList) {
      for (var v in vaultsList) {
        vaults[v.uid] = v;
        selectedVaults[v.uid] =
            (((_secret.vaults.isEmpty) &&
                    v.uid == defaultVault) ||
                _secret.vaults.contains(v.uid));
      }
      setState(() {
        _loading = false;
      });
    });
  }

  void setPassword(String value) {
    setState(() {
      _secret.message = value;
    });
    _passwordController.text = value;
  }

  List<Widget> _generateChips(BuildContext context) {
    var widgetList = <Widget>[];

    vaults.forEach((uid, vault) {
      widgetList.add(NullPassFilterChip(
        label: vault.nickname,
        isSelected: selectedVaults[uid] ?? false,
        onSelected: (isSelected) {
          setState(() {
            selectedVaults[uid] = isSelected;
          });
        },
      ));
    });

    // /*
    widgetList.add(ActionChip(
      label: const Text(
        "Add",
        style: TextStyle(color: Colors.black),
      ),
      avatar: const CircleAvatar(
        backgroundColor: Colors.blue,
        child: Text(
          "+",
          style: TextStyle(color: Colors.white),
        ),
      ),
      onPressed: () async {
        showDialog<void>(
          context: context,
          // uncomment below to force user to tap button and not just tap outside the alert!
          // barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Add a new Vault'),
              content: TextFormField(
                initialValue: "",
                decoration: const InputDecoration(labelText: 'New Vault'),
                onChanged: (input) {
                  newVaultName = input;
                },
              ),
              actions: <Widget>[
                TextButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                      newVaultName = "";
                      Navigator.of(context).pop();
                    }),
                TextButton(
                    child: const Text('Add'),
                    onPressed: () async {
                      // NullPassDB npDB = NullPassDB.instance;
                      // await npDB.deleteAllSecrets();
                      var v = Vault(
                          nickname: newVaultName ?? '',
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
                          vaults[v.uid] = v;
                          selectedVaults[v.uid] = true;
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
      shape: const StadiumBorder(side: BorderSide(color: Colors.blue)),
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
              ? const Text('New Secret')
              : ((widget.edit == SecretEditType.Update)
                  ? const Text('Update Secret')
                  : const Text('Secret Action')),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        body: Container(
          child: const CenterLoader(),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: (widget.edit == SecretEditType.Create)
              ? const Text('New Secret')
              : ((widget.edit == SecretEditType.Update)
                  ? const Text('Update Secret')
                  : const Text('Secret Action')),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        body: Container(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: ListView(
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
                    decoration: const InputDecoration(
                        labelText: 'Nickname', border: InputBorder.none),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'The Nickname field cannot be empty';
                      }
                      return null;
                    },
                  ),
                ),
                const FormDivider(),
                ListTile(
                  title: TextFormField(
                    onChanged: (value) {
                      setState(() {
                        _secret.website = value;
                      });
                      Log.debug('new website ${_secret.website}');
                    },
                    initialValue: _secret.website,
                    decoration: const InputDecoration(
                        labelText: 'Website', border: InputBorder.none),
                    keyboardType: TextInputType.url,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'The Website field cannot be empty';
                      }
                      return null;
                    },
                  ),
                ),
                const FormDivider(),
                ListTile(
                  title: TextFormField(
                    onChanged: (value) {
                      setState(() {
                        _secret.username = value;
                      });
                      Log.debug('new username ${_secret.username}');
                    },
                    initialValue: _secret.username,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: InputBorder.none,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'The Username field cannot be empty';
                      }
                      return null;
                    },
                  ),
                ),
                const FormDivider(),
                PasswordInput(
                  onChange: (value) {
                    setState(() {
                      _secret.message = value;
                    });
                    Log.debug('new password ${_secret.message}');
                  },
                  controller: _passwordController,
                  initialValue: _secret.message ?? '',
                  setPassword: setPassword,
                ),
                const FormDivider(),
                ListTile(
                  title: TextFormField(
                    onChanged: (value) {
                      setState(() {
                        _secret.otpCode = value.toUpperCase();
                      });
                      Log.debug('new otpCode ${_secret.otpCode}');
                    },
                    initialValue: _secret.otpCode?.toUpperCase(),
                    decoration: const InputDecoration(
                        labelText: 'One-Time Passcode',
                        border: InputBorder.none),
                    validator: (value) {
                      if ((value?.trim().isNotEmpty ?? false) &&
                          _secret.getOnetimePasscode().trim() == '') {
                        return 'The One-Time Passcode provided is invalid';
                      }
                      return null;
                    },
                  ),
                ),
                const FormDivider(),
                ListTile(
                  title: TextFormField(
                    onChanged: (value) {
                      setState(() {
                        _secret.notes = value;
                      });
                      Log.debug('new notes ${_secret.notes}');
                    },
                    initialValue: _secret.notes,
                    decoration: const InputDecoration(
                        labelText: 'Notes', border: InputBorder.none),
                  ),
                ),
                const FormDivider(),
                FormField(
                  builder: (fieldState) => ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
                    title: Text(
                      "Vaults",
                      style: TextStyle(
                        color: Colors.grey[600],
                        // fontSize: 12.5,
                      ),
                    ),
                    subtitle: Wrap(
                      spacing: 5.0,
                      runSpacing: 5.0,
                      children: _generateChips(context),
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
                const FormDivider(),
                ListTile(
                  title: ElevatedButton(
                    onPressed: () {
                      submit(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(color: Colors.white),
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
                  return const SecretGenerate(inEditor: true);
                });
            if (result != null && result.toString().trim() != '') {
              _secret.message = result.toString();
              setPassword(_secret.message ?? '');
            }
          },
          tooltip: 'Generate',
          child: const Icon(Icons.lock),
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

  const PasswordInput(
      {super.key,
      required this.onChange,
      required this.controller,
      required this.setPassword,
      this.initialValue = ''});

  @override
  _PasswordInputState createState() => _PasswordInputState();
}

class _PasswordInputState extends State<PasswordInput> {
  bool _visible = false;
  String? _initialValue;
  late TextEditingController _controller;
  late Function _setPassword;

  @override
  void initState() {
    super.initState();
    _initialValue ??= (widget.initialValue ?? '');
    _controller = widget.controller;
    _controller.text = _initialValue ?? '';
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
        decoration: const InputDecoration(
          labelText: 'Password',
          border: InputBorder.none,
        ),
        // initialValue: _initialValue,
        obscureText: !_visible,
        validator: (value) {
          if (value?.isEmpty ?? true) {
            return 'The Password field cannot be empty';
          }
          return null;
        },
      ),
      trailing: SizedBox(
        width: 100,
        child: Row(
          children: <Widget>[
            IconButton(
              icon: _visible
                  ? const Icon(FontAwesomeIcons.solidEye, size: 20)
                  : const Icon(FontAwesomeIcons.solidEyeSlash, size: 20),
              onPressed: () {
                // _initialValue = this.widget.
                setState(() {
                  _visible = !_visible;
                });
              },
            ),
            IconButton(
              // icon: new Icon(FontAwesomeIcons.lock, size: 20),
              icon: const Icon(Icons.lock),
              onPressed: () async {
                final result = await showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return const SecretGenerate(inEditor: true);
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
