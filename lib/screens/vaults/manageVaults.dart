/*
 * Created by Ilan Rasekh on 2020/3/27
 * Copyright (c) 2020 Pseudorand Development. All rights reserved.
 */

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nullpass/common.dart';
import 'package:nullpass/models/auditRecord.dart';
import 'package:nullpass/models/vault.dart';
import 'package:nullpass/services/datastore.dart';
import 'package:nullpass/widgets.dart';

class ManageVault extends StatefulWidget {
  @override
  ManageVaultState createState() => ManageVaultState();
}

class ManageVaultState extends State<ManageVault> {
  bool _loading = true;
  List<Vault> _vaults;

  @override
  void initState() {
    super.initState();

    NullPassDB.instance.getAllVaults().then((vList) {
      setState(() {
        _vaults = vList ?? <Vault>[];
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('Manage Vaults')),
        body: new Container(child: CenterLoader()),
      );
    } else {
      return Scaffold(
        appBar: AppBar(title: Text('Manage Vaults')),
        body: ListView.builder(
          itemCount: this._vaults.length,
          itemBuilder: (context, index) {
            return ListTile(
              contentPadding: EdgeInsets.fromLTRB(15, 0, 0, 5),
              title: Text(this._vaults[index].nickname),
              subtitle: this._vaults[index].manager == VaultManager.Internal
                  ? ((this._vaults[index].isDefault) ? Text("Default") : null)
                  : Text("Synced from External Device"),
              trailing: Container(
                width: 100,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    if (this._vaults[index].manager == VaultManager.Internal)
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () async {
                          showDialog<void>(
                            context: context,
                            builder: (BuildContext context) {
                              return NewVaultDialog(
                                  vault: this._vaults[index],
                                  onUpdate: () async {
                                    var lv = await NullPassDB.instance
                                        .getAllVaults();
                                    setState(() {
                                      this._vaults = lv;
                                    });
                                  });
                            },
                          );
                        },
                      ),
                    IconButton(
                      icon: Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                      onPressed: () async {
                        showDialog<void>(
                          context: context,
                          // uncomment below to force user to tap button and not just tap outside the alert!
                          // barrierDismissible: false,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Delete Vault'),
                              content: Text(
                                  'This will delete the Vault and any passwords that live only with in it. Be sure before proceeding as this is not undoable or recoverable.'),
                              actions: <Widget>[
                                TextButton(
                                  child: Text('Cancel'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                TextButton(
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  onPressed: () async {
                                    NullPassDB npDB = NullPassDB.instance;
                                    // TODO: await npDB.deleteAllSecrets(); that only live in that vault and remove the vault from all secrets
                                    await npDB
                                        .deleteVault(this._vaults[index].uid);
                                    await NullPassDB.instance
                                        .addAuditRecord(AuditRecord(
                                      type: AuditType.VaultDeleted,
                                      message:
                                          'The "${this._vaults[index].nickname}" vault was deleted.',
                                      vaultsReferenceId: <String>{
                                        this._vaults[index].uid
                                      },
                                      date: DateTime.now().toUtc(),
                                    ));
                                    var lv = await NullPassDB.instance
                                        .getAllVaults();
                                    setState(() {
                                      this._vaults = lv;
                                    });
                                    Navigator.of(context).pop();
                                  },
                                )
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.blue,
          onPressed: () async {
            showDialog<void>(
              context: context,
              builder: (BuildContext context) {
                return NewVaultDialog(
                    isNew: true,
                    onUpdate: () async {
                      var lv = await NullPassDB.instance.getAllVaults();
                      setState(() {
                        this._vaults = lv;
                      });
                    });
              },
            );
          },
          tooltip: 'Add',
          child: Icon(Icons.add),
        ),
      );
    }
  }
}

// typedef AsyncVaultCallback = Future<void> Function(Vault);

class NewVaultDialog extends StatefulWidget {
  final Vault vault;
  final AsyncCallback onUpdate;
  final bool isNew;

  NewVaultDialog({this.vault, @required this.onUpdate, this.isNew = false});

  @override
  _NewVaultDialogState createState() => _NewVaultDialogState();
}

class _NewVaultDialogState extends State<NewVaultDialog> {
  Vault _vaultCopy;
  bool isNew;

  Future<void> addVault() async {
    var v = Vault(
      nickname: _vaultCopy.nickname,
      isDefault: _vaultCopy.isDefault,
      manager: VaultManager.Internal,
      managerId: Vault.InternalSourceID,
    );
    if (await NullPassDB.instance.insertVault(v)) {
      await NullPassDB.instance.addAuditRecord(AuditRecord(
        type: AuditType.VaultCreated,
        message: 'The "${v.nickname}" vault was created.',
        vaultsReferenceId: <String>{v.uid},
        date: DateTime.now().toUtc(),
      ));
      if (v.isDefault) {
        await setVaultAsDefault(v.uid);
      }
      await this.widget.onUpdate();
    }
  }

  Future<void> updateVault() async {
    var v = Vault(
      nickname: _vaultCopy.nickname,
      isDefault: _vaultCopy.isDefault,
      uid: this.widget.vault.uid,
      manager: this.widget.vault.manager,
      managerId: this.widget.vault.managerId,
      createdAt: this.widget.vault.createdAt,
      modifiedAt: this.widget.vault.modifiedAt,
    );
    if (await NullPassDB.instance.updateVault(v)) {
      await NullPassDB.instance.addAuditRecord(AuditRecord(
        type: AuditType.VaultUpdated,
        message: 'The "${v.nickname}" vault was updated.',
        vaultsReferenceId: <String>{v.uid},
        date: DateTime.now().toUtc(),
      ));
      if (v.isDefault && !this.widget.vault.isDefault) {
        await setVaultAsDefault(v.uid);
      }

      if (!v.isDefault && this.widget.vault.isDefault) {
        sharedPrefs.setString(DefaultVaultIDPrefKey, "");
      }
      await this.widget.onUpdate();
    }
  }

  Future<void> setVaultAsDefault(vid) async {
    await NullPassDB.instance.setVaultAsDefault(vid);
    sharedPrefs.setString(DefaultVaultIDPrefKey, vid);
  }

  @override
  void initState() {
    super.initState();

    this.isNew = this.widget.isNew;

    if (this.widget.vault != null) {
      _vaultCopy = Vault(
        uid: this.widget.vault.uid,
        managerId: this.widget.vault.managerId,
        manager: this.widget.vault.manager,
        nickname: this.widget.vault.nickname,
        modifiedAt: this.widget.vault.modifiedAt,
        isDefault: this.widget.vault.isDefault,
        createdAt: this.widget.vault.createdAt,
      );
    } else {
      _vaultCopy = Vault(
        nickname: "",
        isDefault: false,
        manager: VaultManager.Internal,
        managerId: Vault.InternalSourceID,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: (this.isNew) ? Text('Add Vault') : Text('Edit Vault'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextFormField(
            initialValue: _vaultCopy.nickname,
            decoration: InputDecoration(labelText: 'Vault Name'),
            onChanged: (input) {
              setState(() {
                _vaultCopy.nickname = input;
              });
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.fromLTRB(2, 10, 0, 0),
            title: (this.isNew) ? Text('Set As Default') : Text("Default"),
            trailing: Switch(
                value: _vaultCopy.isDefault,
                onChanged: (newValue) async {
                  setState(() {
                    _vaultCopy.isDefault = newValue;
                  });
                }),
          )
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: (this.isNew) ? Text('Add') : Text('Update'),
          onPressed: () async {
            // NullPassDB npDB = NullPassDB.instance;
            // await npDB.deleteAllSecrets();
            if (this.isNew)
              await addVault();
            else
              await updateVault();
            Navigator.of(context).pop();
          },
        )
      ],
    );
  }
}
