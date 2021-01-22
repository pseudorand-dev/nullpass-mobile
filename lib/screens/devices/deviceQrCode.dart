/*
 * Created by Ilan Rasekh on 2020/3/7
 * Copyright (c) 2020 Pseudorand Development. All rights reserved.
 */

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:nullpass/common.dart';
import 'package:nullpass/models/device.dart';
import 'package:nullpass/models/notification.dart' as np;
import 'package:nullpass/models/qrData.dart';
import 'package:nullpass/models/syncRegistration.dart';
import 'package:nullpass/screens/appDrawer.dart';
import 'package:nullpass/services/datastore.dart';
import 'package:nullpass/services/logging.dart';
import 'package:openpgp/key_pair.dart';
import 'package:openpgp/openpgp.dart';
import 'package:qr_flutter/qr_flutter.dart' as qr;
import 'package:uuid/uuid.dart';

class QrCode extends StatefulWidget {
  final Function fabPressFunction;
  final Function(BuildContext) nextStep;
  final Function(Device) setDevice;

  QrCode(
      {Key key,
      @required this.fabPressFunction,
      @required this.nextStep,
      @required this.setDevice})
      : super(key: key);

  @override
  _QrCodeState createState() => _QrCodeState();
}

class _QrCodeState extends State<QrCode> {
  final String _title = "NullPass Syncing";
  Function _fabPressFunction;
  Function(Device) _setDevice;
  Function(BuildContext) _nextStep;

  QrData _qrData;
  String _responseNonce;
  KeyPair _encryptionKeyPair;
  String _scannerDeviceId;
  String _scannerPubKey;
  String _errorText = "";
  BuildContext _context;

  String _debugLog = "DEBUG LOG";

  Future<void> _syncInitHandshakeStepOneHandler(dynamic param) async {
    // TODO: handle the function parameters better
    Log.debug("in init step one handler");
    Log.debug("recieved: $param");
    setState(() {
      _debugLog = "$_debugLog\n\nIn Init Handler";
    });
    try {
      var decryptedMsg = await OpenPGP.decryptSymmetric(
          param as String, _qrData.generatedNonce);
      var syncRegMap = jsonDecode(decryptedMsg);
      var scannerInfo = SyncRegistration.fromMap(syncRegMap);

      if (_qrData.generatedNonce == scannerInfo.receivedNonce) {
        setState(() {
          _scannerPubKey = scannerInfo.pgpPubKey;
        });

        if (_encryptionKeyPair == null) {
          _encryptionKeyPair = await NullPassDB.instance.getEncryptionKeyPair();
        }

        var sd = SyncRegistration(
          deviceId: sharedPrefs.getString(DeviceNotificationIdPrefKey),
          pgpPubKey: _encryptionKeyPair.publicKey,
          generatedNonce: _responseNonce,
          receivedNonce: scannerInfo.generatedNonce,
        );

        var encryptedMsg = await OpenPGP.encrypt(sd.toString(), _scannerPubKey);
        var tmpNote = np.Notification(np.NotificationType.SyncInitStepTwo,
            data: encryptedMsg);
        await notify.sendMessageToAnotherDevice(
            deviceIDs: <String>[scannerInfo.deviceId], message: tmpNote);

        Log.debug("sending: $encryptedMsg");

        setState(() {
          _scannerDeviceId = scannerInfo.deviceId;
          _debugLog = "$_debugLog\nsent response";
        });
      }
    } catch (e) {
      Log.debug("error init step one handler: ${e.toString()}");
    }
  }

  Future<void> _syncInitHandshakeStepThreeHandler(dynamic param) async {
    // TODO: handle the function parameters better
    Log.debug("in init response handler");
    Log.debug("recieved: $param");

    setState(() {
      _debugLog = "$_debugLog\n\nIn Init response Handler";
    });

    try {
      var decryptedMsg = await OpenPGP.decrypt(
          param as String, _encryptionKeyPair.privateKey, "");
      var syncRegMap = jsonDecode(decryptedMsg);
      var scannerInfo = SyncRegistration.fromMap(syncRegMap);

      if (_responseNonce == scannerInfo.receivedNonce) {
        var sd = SyncRegistration(
          deviceId: sharedPrefs.getString(DeviceNotificationIdPrefKey),
          receivedNonce: scannerInfo.generatedNonce,
        );

        var encryptedMsg = await OpenPGP.encrypt(sd.toString(), _scannerPubKey);

        Log.debug(encryptedMsg);
        var tmpNote = np.Notification(np.NotificationType.SyncInitStepFour,
            data: encryptedMsg);
        notify.sendMessageToAnotherDevice(
            deviceIDs: <String>[scannerInfo.deviceId], message: tmpNote);

        Log.debug("success");
        setState(() {
          _debugLog = "$_debugLog\nhandshake completed successfully!!!";
        });

        // TODO: make sure this sets and resets handlers properly as folks move through pages
        notify.setDefaultNotificationHandlers();

        _setDevice(new Device(
            deviceID: _scannerDeviceId, encryptionKey: _scannerPubKey));
        _nextStep(_context);
      }
    } catch (e) {
      Log.debug("error init step three handler: ${e.toString()}");
    }
  }

  @override
  void initState() {
    super.initState();
    Log.debug("in initState");
    _fabPressFunction = this.widget.fabPressFunction;
    _nextStep = this.widget.nextStep;
    _setDevice = this.widget.setDevice;

    _qrData = QrData.generate();
    _responseNonce = Uuid().v4();

    Log.debug(_qrData.toString());
    // Log.debug(base64.encode(utf8.encode(_qrData.toString())));
    // Log.debug(_qrData.toString().length);
    // Log.debug(base64.encode(utf8.encode(_qrData.toString())).length);

    // TODO: make sure this sets and resets handlers properly as folks move through pages
    notify.syncInitHandshakeStepOneHandler = _syncInitHandshakeStepOneHandler;
    notify.syncInitHandshakeStepThreeHandler =
        _syncInitHandshakeStepThreeHandler;
  }

  @override
  Widget build(BuildContext context) {
    final bodyHeight = MediaQuery.of(context).size.height -
        MediaQuery.of(context).viewInsets.bottom;
    setState(() {
      _context = context;
    });

    return MaterialApp(
      title: _title,
      home: Scaffold(
        appBar: AppBar(
          title: Text(_title),
        ),
        drawer: AppDrawer(
          currentPage: NullPassRoute.QrCode,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              qr.QrImage(
                data: _qrData.toString(),
                version: qr.QrVersions.auto,
                errorCorrectionLevel: qr.QrErrorCorrectLevel.Q,
                // foregroundColor: Colors.deepOrangeAccent,
                size: 0.5152 * bodyHeight,
              ),
              // TODO: add valuable error details in release
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
          child: Icon(MdiIcons.qrcodeScan),
        ),
      ),
    );
  }
}
