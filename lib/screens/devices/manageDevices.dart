/*
 * Created by Ilan Rasekh on 2020/3/7
 * Copyright (c) 2020 Pseudorand Development. All rights reserved.
 */

import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:nullpass/common.dart';
import 'package:nullpass/models/device.dart';
import 'package:nullpass/screens/appDrawer.dart';
import 'package:nullpass/screens/devices/manageSync.dart';
import 'package:nullpass/screens/devices/syncDevices.dart';
import 'package:nullpass/services/datastore.dart';
import 'package:nullpass/services/logging.dart';
import 'package:nullpass/widgets.dart';

class ManageDevices extends StatefulWidget {
  @override
  _ManageDevicesState createState() => _ManageDevicesState();
}

class _ManageDevicesState extends State<ManageDevices> {
  String _title = "Manage Devices";
  bool _loading = true;
  List<Device> _devices = <Device>[];
  NullPassDB _npDB;

  @override
  void initState() {
    super.initState();

    _npDB = NullPassDB.instance;

    _reloadDeviceList().then((worked) {
      setState(() {
        _loading = false;
      });
    });
  }

  Future<bool> _reloadDeviceList() async {
    try {
      List<Device> dList = await _npDB.getAllDevices();
      setState(() {
        _devices = dList;
      });
      return true;
    } catch (e) {
      Log.debug(e);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return MaterialApp(
        title: _title,
        home: Scaffold(
          appBar: AppBar(
            title: Text(_title),
          ),
          drawer: AppDrawer(
              currentPage: NullPassRoute.ManageDevices,
              reloadSecretList: (dynamic) {}),
          body: CenterLoader(),
        ),
      );
    } else {
      return MaterialApp(
        title: _title,
        home: Scaffold(
          appBar: AppBar(
            title: Text(_title),
          ),
          drawer: AppDrawer(
              currentPage: NullPassRoute.ManageDevices,
              reloadSecretList: (dynamic) {}),
          body: _DeviesList(
            devices: _devices,
            reloadDevicesListFunction: _reloadDeviceList,
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              await Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        SyncDevices(syncState: SyncState.scan)),
              );
            },
            tooltip: 'Add New Device',
            child: Icon(MdiIcons.qrcodeScan),
          ),
        ),
      );
    }
  }
}

class _DeviesList extends StatelessWidget {
  final List<Device> devices;
  final AsyncBoolCallback reloadDevicesListFunction;

  _DeviesList(
      {Key key,
      @required this.devices,
      @required this.reloadDevicesListFunction})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (devices == null || devices.length < 1) {
      return Container();
    } else {
      return ListView.builder(
        itemCount: devices.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Icon(Icons.phone_android),
            title: Text(devices[index].nickname ?? ""),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ManageSync(this.devices[index]),
                ),
              );
              await reloadDevicesListFunction();
            },
          );
        },
      );
    }
  }
}
