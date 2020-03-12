/*
 * Created by Ilan Rasekh on 2020/3/7
 * Copyright (c) 2020 Pseudorand Development. All rights reserved.
 */

import 'package:community_material_icon/community_material_icon.dart';
import 'package:flutter/material.dart';
import 'package:nullpass/common.dart';
import 'package:nullpass/screens/appDrawer.dart';
import 'package:nullpass/screens/devices/qrData.dart';
import 'package:nullpass/services/logging.dart';
import 'package:nullpass/services/notification.dart' as np;
import 'package:nullpass/services/notificationManager.dart';
import 'package:qr_flutter/qr_flutter.dart' as qr;
import 'package:uuid/uuid.dart';

class QrCode extends StatefulWidget {
  final Function fabPressFunction;
  final Function(bool) nextStep;
  QrCode({Key key, @required this.fabPressFunction, @required this.nextStep})
      : super(key: key);

  @override
  _QrCodeState createState() => _QrCodeState();
}

class _QrCodeState extends State<QrCode> {
  final String _title = "NullPass Syncing";
  final QrData _qrData = QrData();
  final String _responseNonce = Uuid().v4();
  Function _fabPressFunction;
  Function(bool) _nextStep;
  bool _syncFrom = false;
  String _errorText = "";
  String _debugLog = "DEBUG LOG";

  Future<bool> _onWillPop() async {
    Log.debug("in _onWillPop");
    notify.syncInitHandshakeStepOneHandler =
        defaultSyncInitHandshakeStepOneHandler;
    notify.syncInitHandshakeStepThreeHandler =
        defaultSyncInitHandshakeStepThreeHandler;
    return true;
  }

  Future<void> _syncInitHandshakeStepOneHandler(dynamic param) async {
    Log.debug("in init handler");
    Log.debug("recieved: $param");
    setState(() {
      _debugLog = "$_debugLog\n\nIn Init Handler";
    });
    try {
      var scannerInfo = QrData.fromMap(param);

      if (_qrData.generatedNonce == scannerInfo.receivedNonce) {
        var tmpMap = <String, dynamic>{
          "status": "received",
          "received_nonce": scannerInfo.generatedNonce,
          "generated_nonce": _responseNonce,
        };
        var tmpNote = np.Notification(np.NotificationType.CodeSyncInitResponse,
            data: tmpMap);
        await notify.sendMessageToAnotherDevice(
            deviceIDs: <String>[scannerInfo.deviceId], message: tmpNote);

        Log.debug("sending: $tmpMap");

        setState(() {
          _debugLog = "$_debugLog\nsent response";
        });
      }
    } catch (e) {
      Log.debug("error in _syncInitHandler: ${e.toString()}");
    }
    // }
  }

  void _syncInitHandshakeStepThreeHandler(dynamic param) {
    Log.debug("in init response handler");
    Log.debug("recieved: $param");

    setState(() {
      _debugLog = "$_debugLog\n\nIn Init response Handler";
    });

    try {
      var scannerInfo = QrData.fromMap(param);

      if (_responseNonce == scannerInfo.receivedNonce) {
        Log.debug("success");
        setState(() {
          _debugLog = "$_debugLog\nhandshake completed successfully!!!";
        });
        _nextStep(_syncFrom);
      }
    } catch (e) {
      Log.debug("error in _syncInitResponseHandler: ${e.toString()}");
    }
  }

  @override
  void initState() {
    super.initState();
    Log.debug("in initState");
    _fabPressFunction = this.widget.fabPressFunction;
    _nextStep = this.widget.nextStep;

    Log.debug(_qrData.toString());
    Log.debug(_responseNonce);

    notify.syncInitHandshakeStepOneHandler = _syncInitHandshakeStepOneHandler;

    notify.syncInitHandshakeStepThreeHandler =
        _syncInitHandshakeStepThreeHandler;
  }

  @override
  void deactivate() {
    Log.debug("in deactivate");
    _onWillPop();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final bodyHeight = MediaQuery.of(context).size.height -
        MediaQuery.of(context).viewInsets.bottom;

    return new WillPopScope(
      onWillPop: _onWillPop,
      child: MaterialApp(
        title: _title,
        home: Scaffold(
          appBar: AppBar(
            title: Text(_title),
          ),
          drawer: AppDrawer(
              currentPage: NullPassRoute.QrCode,
              reloadSecretList: (dynamic) {}),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                RepaintBoundary(
                  child: qr.QrImage(
                    data: _qrData.toString(),
                    size: 0.5 * bodyHeight,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text("Sync From This Device: "),
                    Switch(
                        value: _syncFrom,
                        onChanged: (bool) {
                          setState(() {
                            _syncFrom = !_syncFrom;
                          });
                        }),
                  ],
                ),
                if (_debugLog == null || _debugLog.isEmpty)
                  Text(
                    _errorText,
                    style: TextStyle(color: Colors.red),
                  ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _fabPressFunction,
            tooltip: 'QR Scanner',
            child: Icon(CommunityMaterialIcons.qrcode_scan),
          ),
        ),
      ),
    );
  }
}
