/*
 * Created by Ilan Rasekh on 2020/3/10
 * Copyright (c) 2020 Pseudorand Development. All rights reserved.
 */

import 'package:flutter/material.dart';
import 'package:nullpass/models/device.dart';
import 'package:nullpass/screens/appDrawer.dart';
import 'package:nullpass/screens/devices/manageSync.dart';
import 'package:nullpass/screens/devices/scanQrCode.dart';
import 'package:nullpass/screens/loading.dart';

import 'deviceQrCode.dart';

enum SyncState { qrcode, scan, processing, selector, unknown }

class SyncDevices extends StatefulWidget {
  final SyncState syncState;

  SyncDevices({Key? key, this.syncState = SyncState.qrcode}) : super(key: key);

  @override
  _SyncDevicesState createState() => _SyncDevicesState();
}

class _SyncDevicesState extends State<SyncDevices> {
  SyncState? _syncState;
  Device? newDevice;

  void fabPress() {
    if (_syncState == SyncState.qrcode) {
      setState(() {
        _syncState = SyncState.scan;
      });
    } else if (_syncState == SyncState.scan) {
      setState(() {
        _syncState = SyncState.qrcode;
      });
    }
  }

  Future<void> finishSetup(BuildContext? context) async {
    await Navigator.push(
        context!,
        MaterialPageRoute(
            builder: (context) => ManageSync(newDevice, inSetup: true)));
  }

  void setDevice(Device d) {
    setState(() {
      newDevice = d;
    });
  }

  @override
  void initState() {
    super.initState();
    _syncState = this.widget.syncState;
  }

  @override
  Widget build(BuildContext context) {
    switch (_syncState) {
      case SyncState.qrcode:
        {
          return QrCode(
              fabPressFunction: fabPress,
              nextStep: finishSetup,
              setDevice: setDevice);
        }
        break;

      case SyncState.scan:
        {
          return QrScanner(
              fabPressFunction: fabPress,
              nextStep: finishSetup,
              setDevice: setDevice);
        }
        break;

      case SyncState.selector:
        {
          // return LoadingPage(
          //     title: "Setup Sync", route: NullPassRoute.ManageDevices);
          return MaterialApp(
            home: ManageSync(newDevice, inSetup: true),
          );
        }
        break;

      case SyncState.processing:
        {
          return LoadingPage(
              title: "Setup Sync", route: NullPassRoute.ManageDevices);
        }
        break;

      default:
        {
          return LoadingPage(
              title: "Sync Devices", route: NullPassRoute.ManageDevices);
        }
        break;
    }
  }
}
