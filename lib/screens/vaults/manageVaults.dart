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
  const ManageVault({super.key});

  @override
  ManageVaultState createState() => ManageVaultState();
}

class ManageVaultState extends State<ManageVault> {
  bool _loading = true;
  late List<Vault> _vaults;

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
        appBar: AppBar(title: const Text('Manage Vaults')),
        body: Container(child: const CenterLoader()),
      );
    } else {
      return Scaffold(
        appBar: AppBar(title: const Text('Manage Vaults')),
        body: ListView.builder(
          itemCount: _vaults.length,
          itemBuilder: (context, index) {
            return ListTile(
              contentPadding: const EdgeInsets.fromLTRB(15, 0, 0, 5),
              title: Text(_vaults[index].nickname),
              subtitle: _vaults[index].manager == VaultManager.Internal
                  ? ((_vaults[index].isDefault) ? const Text("Default") : null)
                  : const Text("Synced from External Device"),
              trailing: SizedBox(
                width: 100,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    if (_vaults[index].manager == VaultManager.Internal)
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          showDialog<void>(
                            context: context,
                            builder: (BuildContext context) {
                              return NewVaultDialog(
                                  vault: _vaults[index],
                                  onUpdate: () async {
                                    var lv = await NullPassDB.instance
                                        .getAllVaults();
                                    setState(() {
                                      _vaults = lv;
                                    });
                                  });
                            },
                          );
                        },
                      ),
                    IconButton(
                      icon: const Icon(
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
                              title: const Text('Delete Vault'),
                              content: const Text(
                                  'This will delete the Vault and any passwords that live only with in it. Be sure before proceeding as this is not undoable or recoverable.'),
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
                                    // TODO: await npDB.deleteAllSecrets(); that only live in that vault and remove the vault from all secrets
                                    await npDB
                                        .deleteVault(_vaults[index].uid);
                                    await NullPassDB.instance
                                        .addAuditRecord(AuditRecord(
                                      type: AuditType.VaultDeleted,
                                      message:
                                          'The "${_vaults[index].nickname}" vault was deleted.',
                                      vaultsReferenceId: <String>{
                                        _vaults[index].uid
                                      },
                                      date: DateTime.now().toUtc(),
                                    ));
                                    var lv = await NullPassDB.instance
                                        .getAllVaults();
                                    setState(() {
                                      _vaults = lv;
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
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            showDialog<void>(
              context: context,
              builder: (BuildContext context) {
                return NewVaultDialog(
                    isNew: true,
                    onUpdate: () async {
                      var lv = await NullPassDB.instance.getAllVaults();
                      setState(() {
                        _vaults = lv;
                      });
                    });
              },
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Vault'),
        ),
      );
    }
  }
}

// typedef AsyncVaultCallback = Future<void> Function(Vault);

class NewVaultDialog extends StatefulWidget {
  final Vault? vault;
  final AsyncCallback onUpdate;
  final bool isNew;

  const NewVaultDialog({super.key, this.vault, required this.onUpdate, this.isNew = false});

  @override
  _NewVaultDialogState createState() => _NewVaultDialogState();
}

class _NewVaultDialogState extends State<NewVaultDialog> {
  late Vault _vaultCopy;
  late bool isNew;

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
      await widget.onUpdate();
    }
  }

  Future<void> updateVault() async {
    if (widget.vault == null) return;
    
    var v = Vault(
      nickname: _vaultCopy.nickname,
      isDefault: _vaultCopy.isDefault,
      uid: widget.vault!.uid,
      manager: widget.vault!.manager,
      managerId: widget.vault!.managerId,
      createdAt: widget.vault!.createdAt,
      modifiedAt: widget.vault!.modifiedAt,
    );
    if (await NullPassDB.instance.updateVault(v)) {
      await NullPassDB.instance.addAuditRecord(AuditRecord(
        type: AuditType.VaultUpdated,
        message: 'The "${v.nickname}" vault was updated.',
        vaultsReferenceId: <String>{v.uid},
        date: DateTime.now().toUtc(),
      ));
      if (v.isDefault && !widget.vault!.isDefault) {
        await setVaultAsDefault(v.uid);
      }

      if (!v.isDefault && widget.vault!.isDefault) {
        sharedPrefs.setString(DefaultVaultIDPrefKey, "");
      }
      await widget.onUpdate();
    }
  }

  Future<void> setVaultAsDefault(vid) async {
    await NullPassDB.instance.setVaultAsDefault(vid);
    sharedPrefs.setString(DefaultVaultIDPrefKey, vid);
  }

  @override
  void initState() {
    super.initState();

    isNew = widget.isNew;

    if (widget.vault != null) {
      _vaultCopy = Vault(
        uid: widget.vault!.uid,
        managerId: widget.vault!.managerId,
        manager: widget.vault!.manager,
        nickname: widget.vault!.nickname,
        modifiedAt: widget.vault!.modifiedAt,
        isDefault: widget.vault!.isDefault,
        createdAt: widget.vault!.createdAt,
      );
    } else {
      _vaultCopy = Vault(
        nickname: '',
        manager: VaultManager.Internal,
        managerId: Vault.InternalSourceID,
        isDefault: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: (isNew) ? const Text('Add Vault') : const Text('Edit Vault'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextFormField(
            initialValue: _vaultCopy.nickname,
            decoration: const InputDecoration(labelText: 'Vault Name'),
            onChanged: (input) {
              setState(() {
                _vaultCopy.nickname = input;
              });
            },
          ),
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(2, 10, 0, 0),
            title: (isNew) ? const Text('Set As Default') : const Text("Default"),
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
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            }),
        TextButton(
            child: (isNew) ? const Text('Add') : const Text('Update'),
            onPressed: () async {
              // NullPassDB npDB = NullPassDB.instance;
              // await npDB.deleteAllSecrets();
              if (isNew) {
                await addVault();
              } else {
                await updateVault();
              }
              Navigator.of(context).pop();
            })
      ],
    );
  }
}
