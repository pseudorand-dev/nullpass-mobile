/*
 * Created by Ilan Rasekh on 2020/3/10
 * Copyright (c) 2020 Pseudorand Development. All rights reserved.
 */

import 'package:flutter/material.dart';
import 'package:nullpass/common.dart';
import 'package:nullpass/screens/devices/scanQrCode.dart';
import 'package:nullpass/screens/loading.dart';

import 'deviceQrCode.dart';

enum SyncState { qrcode, scan, processing, selector, unknown }

class SyncDevices extends StatefulWidget {
  final SyncState syncState;

  SyncDevices({Key key, this.syncState = SyncState.qrcode}) : super(key: key);

  @override
  _SyncDevicesState createState() => _SyncDevicesState();
}

class _SyncDevicesState extends State<SyncDevices> {
  SyncState _syncState;

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

  void process(bool syncFrom) {
    setState(() {
      _syncState = syncFrom ? SyncState.selector : SyncState.processing;
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
          return QrCode(fabPressFunction: fabPress, nextStep: process);
        }
        break;
      case SyncState.scan:
        {
          return QrScanner(fabPressFunction: fabPress, nextStep: process);
        }
        break;
      case SyncState.processing:
        {
          return LoadingPage(
              title: "Setting Up Sync", route: NullPassRoute.ManageDevices);
        }
        break;

      case SyncState.selector:
        {
          return LoadingPage(
              title: "Sync Rules", route: NullPassRoute.ManageDevices);
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
