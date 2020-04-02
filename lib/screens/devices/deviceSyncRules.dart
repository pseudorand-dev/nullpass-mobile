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

      if (success)
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ManageDevices()),
        );
    }
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
            deviceID: _device.id,
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
            FlatButton(
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
