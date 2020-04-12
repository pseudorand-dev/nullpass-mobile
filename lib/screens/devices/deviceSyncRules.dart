/*
 * Created by Ilan Rasekh on 2020/3/13
 * Copyright (c) 2020 Pseudorand Development. All rights reserved.
 */
import 'package:flutter/material.dart';
import 'package:nullpass/models/device.dart';
import 'package:nullpass/models/deviceSync.dart';
import 'package:nullpass/models/vault.dart';
import 'package:nullpass/screens/devices/manageDevices.dart';
import 'package:nullpass/services/datastore.dart';
import 'package:nullpass/services/logging.dart';
import 'package:nullpass/widgets.dart';

class DeviceSyncRules extends StatefulWidget {
  final Device device;
  final bool inSetup;

  DeviceSyncRules(this.device, {Key key, inSetup})
      : this.inSetup = inSetup ?? false,
        super(key: key);

  @override
  _DeviceSyncRulesState createState() => _DeviceSyncRulesState();
}

class _DeviceSyncRulesState extends State<DeviceSyncRules> {
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
  bool _loading = true;
  String _title;
  Device _device;
  bool _inSetup;
  Map<String, DeviceSync> _deviceSyncMap;
  Map<String, DeviceSync> _originalSyncMap;
  List<Vault> _vaults;
  Map<String, Vault> _vaultMap;

  void onSave(BuildContext context) async {
    if (this._formKey.currentState.validate()) {
      _formKey.currentState.save();

      // validate changes against original and update vault sync
      NullPassDB helper = NullPassDB.instance;
      bool success = false;

      if (_inSetup) {
        var now = DateTime.now().toUtc();
        _device.created = now;
        _device.lastModified = now;
        success = await helper.insertDevice(_device);
        Log.debug('inserted row(s) - $success');
        // await showSnackBar(context, 'Created!');
      } else {
        _device.lastModified = DateTime.now().toUtc();
        success = await helper.updateDevice(_device);
        Log.debug('updated row(s) - $success');
        // await showSnackBar(context, 'Updated!');
      }

      if (success) {
        await _storeSyncs();
      }

      if (success) {
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ManageDevices()),
        );
      }
    }
  }

  Future<void> _storeSyncs() async {
    _deviceSyncMap.forEach((vid, ds) async {
      var ods = _originalSyncMap[vid];

      // if the vault doesnt have a sync for this device already and the
      // vault access is set to none for this device then no action is needed
      if (ods == null && ds.vaultAccess == DeviceAccess.None) return;
      if (ods != null && ods.vaultAccess == ds.vaultAccess) return;

      // if there was no original sync for this vault + device and now the access is
      // set to something other than none, create a device sync and trigger a data
      // sync initiation process for sending the vault data to the new device
      // or
      // if the vault is managed internally and there was an original sync with for
      // this vault + device and now the access is set to something other than none
      // then update the device sync and send the new data sync information to the
      // end device
      // or
      // if there was an original sync for this vault + device and now the access is set
      // to none then delete the device sync and notify the other device of cancellation
      // ALSO if the device is externally managed delete the vault and any secrets managed by it
      //      if the device is internally managed send cancellation notice and wait for
      //      response from recipient to delete the sync - possibly add a device sync state
      //      and monitor for deletion

      if (ods == null && ds.vaultAccess != DeviceAccess.None) {
        // add access
        if (await NullPassDB.instance.insertSync(ds)) {
          // start sync
        }
      } else if (ods != null &&
          _vaultMap[vid].manager == VaultManager.Internal &&
          ds.vaultAccess != DeviceAccess.None) {
        // update access
        if (await NullPassDB.instance.insertSync(ds)) {
          // update sync
        }
      } else if (ods != null && ds.vaultAccess == DeviceAccess.None) {
        // remove access
        if (await NullPassDB.instance.deleteSync(ds.id)) {
          // remove sync
        }
      }
    });
  }

  Future<void> setupData() async {
    var vaultList = await NullPassDB.instance.getAllVaults();
    var tmpVMap = <String, Vault>{};
    vaultList?.forEach((v) => tmpVMap[v.uid] = v);

    var tmpDeviceSyncs =
        await NullPassDB.instance.getAllSyncsWithADevice(_device.deviceID);
    var tmpDeviceSyncMap = <String, DeviceSync>{};
    var tmpOrigDeviceSyncMap = <String, DeviceSync>{};
    // var tmpDeviceAccessMap = <String, DeviceAccess>{};
    tmpDeviceSyncs.forEach((ds) {
      tmpDeviceSyncMap[ds.vaultID] = ds.clone();
      tmpOrigDeviceSyncMap[ds.vaultID] = ds;
    });

    setState(() {
      _vaults = vaultList;
      _vaultMap = tmpVMap;
      _deviceSyncMap = tmpDeviceSyncMap;
      _originalSyncMap = tmpOrigDeviceSyncMap;
    });
  }

  @override
  void initState() {
    super.initState();
    _device = this.widget.device;
    _inSetup = this.widget.inSetup ?? false;
    _title = (_inSetup) ? 'Setup Sync Rules' : 'Manage Sync Rules';
    _vaults = <Vault>[];
    _vaultMap = <String, Vault>{};
    setupData().then((vaultList) {
      setState(() {
        _loading = false;
      });
    });
  }

  void changeVaultAccess(String vid, DeviceAccess vaultAccess) {
    var ds = _deviceSyncMap[vid] ??
        DeviceSync(
            deviceID: _device.deviceID,
            syncFromInternal: true,
            vaultID: vid,
            vaultName: _vaultMap[vid]?.nickname ?? "",
            vaultAccess: vaultAccess);

    ds.vaultAccess = vaultAccess;

    setState(() {
      _deviceSyncMap[vid] = ds;
    });
  }

  Future<void> updateVaultAccessDialog(String vid,
      {DeviceAccess vaultAccess = DeviceAccess.None}) async {
    var _radioGroup = vaultAccess;
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_vaultMap[vid]?.nickname ?? "Update Sync Access"),
          actions: <Widget>[
            FlatButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                child: Row(
                  children: <Widget>[
                    Radio(
                      activeColor: Colors.blue,
                      value: DeviceAccess.None,
                      groupValue: _radioGroup,
                      onChanged: (newVal) async {
                        changeVaultAccess(vid, newVal);
                        Navigator.of(context).pop();
                      },
                    ),
                    Text("None"),
                  ],
                ),
              ),
              Container(
                child: Row(
                  children: <Widget>[
                    Radio(
                      activeColor: Colors.blue,
                      value: DeviceAccess.Backup,
                      groupValue: _radioGroup,
                      onChanged: (newVal) async {
                        changeVaultAccess(vid, newVal);
                        Navigator.of(context).pop();
                      },
                    ),
                    Text("Backup"),
                  ],
                ),
              ),
              Container(
                child: Row(
                  children: <Widget>[
                    Radio(
                      activeColor: Colors.blue,
                      value: DeviceAccess.ReadOnly,
                      groupValue: _radioGroup,
                      onChanged: (newVal) async {
                        changeVaultAccess(vid, newVal);
                        Navigator.of(context).pop();
                      },
                    ),
                    Text("Read-Only"),
                  ],
                ),
              ),
              Container(
                child: Row(
                  children: <Widget>[
                    Radio(
                      activeColor: Colors.blue,
                      value: DeviceAccess.Manage,
                      groupValue: _radioGroup,
                      onChanged: (newVal) async {
                        changeVaultAccess(vid, newVal);
                        Navigator.of(context).pop();
                      },
                    ),
                    Text("Manage"),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> generateSyncWidgets() {
    List<Widget> wList = <Widget>[];
    _vaults.forEach((v) {
      Widget trailingWidget;

      var ds = _deviceSyncMap[v.uid];

      if (v.manager == VaultManager.External && ds != null) {
        trailingWidget = FlatButton(
          child: Text(deviceAccessToString(ds.vaultAccess)),
          onPressed: null,
          textColor: Colors.blue,
          disabledTextColor: Colors.grey,
        );
      } else if (v.manager == VaultManager.Internal && ds != null) {
        trailingWidget = FlatButton(
          child: Text(deviceAccessToString(ds.vaultAccess)),
          onPressed: () async {
            await updateVaultAccessDialog(v.uid, vaultAccess: ds.vaultAccess);
          },
          textColor: Colors.blue,
          disabledTextColor: Colors.grey,
        );
      } else if (v.manager == VaultManager.Internal) {
        trailingWidget = trailingWidget = FlatButton(
          child: Text(deviceAccessToString(DeviceAccess.None)),
          onPressed: () async {
            await updateVaultAccessDialog(v.uid);
          },
          textColor: Colors.blue,
          disabledTextColor: Colors.grey,
        );
      }

      wList.add(ListTile(
        title: Text(v.nickname),
        subtitle: (v.manager == VaultManager.External
            ? Text("Synced from ${_device.nickname}")
            : null),
        trailing: trailingWidget,
      ));
    });

    return wList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: <Widget>[
          if (!_inSetup)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () async {
                // TODO: ensure delete of device and all connected syncs removes vault data and sends notifications to sync devices
                await NullPassDB.instance
                    .deleteAllSyncsToDevice(this._device.deviceID);
                await NullPassDB.instance.deleteDevice(this._device.id);
                Navigator.pop(context);
              },
            ),
        ],
      ),
      body: new Container(
        padding: new EdgeInsets.all(20.0),
        child: new Form(
          key: this._formKey,
          child: CustomScrollView(
            slivers: <Widget>[
              SliverList(
                delegate: SliverChildListDelegate.fixed([
                  Container(
                    child: Column(
                      children: <Widget>[
                        ListTile(
                          title: TextFormField(
                            onChanged: (value) {
                              setState(() {
                                this._device.nickname = value;
                              });
                            },
                            initialValue: this._device.nickname,
                            decoration: InputDecoration(
                                labelText: 'Device Nickname',
                                border: InputBorder.none),
                          ),
                        ),
                        FormDivider(),
                      ],
                    ),
                    padding: EdgeInsets.only(bottom: 25.0),
                  ),
                ]),
              ),
              SliverList(
                delegate: SliverChildListDelegate.fixed(generateSyncWidgets()),
              ),
              SliverList(
                  delegate: SliverChildListDelegate.fixed([
                Container(
                  padding: EdgeInsets.only(top: 25.0),
                  child: ListTile(
                    title: RaisedButton(
                      onPressed: () {
                        onSave(context);
                      },
                      child: Text(
                        'Save',
                        style: TextStyle(color: Colors.white),
                      ),
                      color: Colors.blue,
                    ),
                  ),
                ),
              ])),
            ],
          ),
        ),
      ),
    );
  }
}
