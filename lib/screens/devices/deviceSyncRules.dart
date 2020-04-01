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
  Device _device;
  bool _inSetup;
  Map<String, DeviceAccess> _deviceAccessMap;
  List<Vault> _vaults;

  void onVaultSelectionChange(String vaultId, DeviceAccess access) {
    setState(() {
      _deviceAccessMap[vaultId] = access;
    });
  }

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

  @override
  void initState() {
    super.initState();
    _device = this.widget.device;
    _inSetup = this.widget.inSetup ?? false;
    _deviceAccessMap = <String, DeviceAccess>{};

    _vaults = <Vault>[];
    NullPassDB.instance.getAllInternallyManagedVaults().then((vaultList) {
      setState(() {
        _vaults = vaultList;
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            (_inSetup) ? Text('Setup Sync Rules') : Text('Manage Sync Rules'),
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
              _VaultSyncList(
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

class _VaultSyncList extends StatelessWidget {
  final Map<String, DeviceAccess> deviceAccessMap;
  final Function(String, DeviceAccess) onSelectionChange;
  final List<Vault> vaults;

  _VaultSyncList(
      {Key key,
      @required this.vaults,
      @required this.deviceAccessMap,
      @required this.onSelectionChange})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (vaults.length > 0) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return ListTile(
              title: Text(vaults[index].nickname),
              // TODO: Set selection for access rule
              trailing: Text("select access"),
            );
          },
          childCount: vaults.length,
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
