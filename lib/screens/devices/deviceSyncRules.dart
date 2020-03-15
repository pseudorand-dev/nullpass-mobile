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
  final bool isSetup;
  final bool syncFromDevice;

  DeviceSyncRules(this.device,
      {Key key, @required this.isSetup, @required this.syncFromDevice})
      : super(key: key);

  @override
  _DeviceSyncRulesState createState() => _DeviceSyncRulesState();
}

class _DeviceSyncRulesState extends State<DeviceSyncRules> {
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
  Device _device;
  bool _isSetup;
  bool _syncFromDevice;
  Map<String, DeviceAccess> _deviceAccessMap;
  List<Vault> _vaults;

  void onVaultSelectionChange(String vaultId, DeviceAccess access) {
    setState(() {
      _deviceAccessMap[vaultId] = access;
    });
  }

  void onContinue(BuildContext context) async {
    if (this._formKey.currentState.validate()) {
      _formKey.currentState.save();
      NullPassDB helper = NullPassDB.instance;
      bool success = false;

      if (_isSetup) {
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

  @override
  void initState() {
    super.initState();
    _device = this.widget.device;
    _isSetup = this.widget.isSetup;
    _syncFromDevice = this.widget.syncFromDevice;
    _deviceAccessMap = <String, DeviceAccess>{};
    // TODO: getVaults
    _vaults = <Vault>[];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            (_isSetup) ? Text('Setup Sync Rules') : Text('Manage Sync Rules'),
        actions: <Widget>[
          if (!_isSetup)
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
                            /*
                            validator: (value) {
                              if (value.isEmpty) {
                                return 'The Device Nickname field cannot be empty';
                              }
                              return null;
                            },
                            */
                          ),
                        ),
                        FormDivider(),
                      ],
                    ),
                    padding: EdgeInsets.only(bottom: 25.0),
                  ),
                  Container(
                    child: ListTile(
                      title: Text('Sync from this device'),
                      // subtitle: Text(
                      //     'Should any vaults from this device be synchronized to the new device'),
                      trailing: Switch(
                          value: _syncFromDevice,
                          onChanged: (value) async {
                            setState(() {
                              this._syncFromDevice = !_syncFromDevice;
                            });
                          }),
                      contentPadding: new EdgeInsets.fromLTRB(15, 5, 10, 10),
                    ),
                  ),
                ]),
              ),
              /*
                    if (_syncFromDevice && _vaults.length > 0)
                      SliverList(
                        delegate: SliverChildListDelegate.fixed([
                          FormDivider(),
                          Container(
                            // color: Colors.blueGrey[100],
                            child: ListTile(
                              title: Text(
                                'Vault Sync Rules',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            margin: EdgeInsets.only(top: 25, left: 15, bottom: 10),
                            // padding: new EdgeInsets.fromLTRB(10, 20, 20, 20),
                          ),
                        ]),
                      ),
                      */
              _VaultSyncList(
                syncFromDevice: this._syncFromDevice,
                vaults: this._vaults,
                deviceAccessMap: this._deviceAccessMap,
                onSelectionChange: this.onVaultSelectionChange,
              ),
              SliverList(
                  delegate: SliverChildListDelegate.fixed([
                Container(
                  padding: EdgeInsets.only(top: 25.0),
                  child: ListTile(
                    title: RaisedButton(
                      onPressed: () {
                        onContinue(context);
                      },
                      child: Text(
                        'Continue',
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

class _VaultSyncList extends StatefulWidget {
  final bool syncFromDevice;
  final Map<String, DeviceAccess> deviceAccessMap;
  final Function(String, DeviceAccess) onSelectionChange;
  final List<Vault> vaults;

  _VaultSyncList(
      {Key key,
      @required this.syncFromDevice,
      @required this.vaults,
      @required this.deviceAccessMap,
      @required this.onSelectionChange})
      : super(key: key);

  @override
  _VaultSyncListState createState() => _VaultSyncListState();
}

class _VaultSyncListState extends State<_VaultSyncList> {
  Map<String, DeviceAccess> _deviceAccessMap;
  Function(String, DeviceAccess) _onSelectionChange;
  List<Vault> _vaults;

  @override
  void initState() {
    super.initState();
    _deviceAccessMap = this.widget.deviceAccessMap;
    _onSelectionChange = this.widget.onSelectionChange;
    _vaults = this.widget.vaults;
  }

  @override
  Widget build(BuildContext context) {
    if (this.widget.syncFromDevice && _vaults.length > 0) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return ListTile(
              title: Text(_vaults[index].nickname),
              // TODO: Set selection for access rule
              trailing: Text("select access"),
            );
          },
          childCount: _vaults.length,
        ),
      );
    } else {
      return SliverList(
        delegate: SliverChildListDelegate.fixed([
          Container(),
        ]),
      );
    }
  }
}
