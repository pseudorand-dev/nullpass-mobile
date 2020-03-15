/*
 * Created by Ilan Rasekh on 2020/3/7
 * Copyright (c) 2020 Pseudorand Development. All rights reserved.
 */

import 'dart:convert';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:community_material_icon/community_material_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nullpass/common.dart';
import 'package:nullpass/models/device.dart';
import 'package:nullpass/screens/appDrawer.dart';
import 'package:nullpass/screens/devices/qrData.dart';
import 'package:nullpass/services/logging.dart';
import 'package:nullpass/services/notification.dart' as np;
import 'package:nullpass/widgets.dart';
import 'package:uuid/uuid.dart';

const String _invalidDataType = "invalid data type";
const String _noDeviceID = "no_device_id";

class QrScanner extends StatefulWidget {
  final Function fabPressFunction;
  final Function(BuildContext) nextStep;
  final Function(Device) setDevice;

  QrScanner(
      {Key key,
      @required this.fabPressFunction,
      @required this.nextStep,
      @required this.setDevice})
      : super(key: key);

  @override
  _QrScannerState createState() => _QrScannerState();
}

class _QrScannerState extends State<QrScanner> {
  final String _title = "NullPass Syncing";
  final QrData _qrData = QrData();
  final String _responseNonce = Uuid().v4();
  Function _fabPressFunction;
  Function(BuildContext) _nextStep;
  Function(Device) _setDevice;
  String _errorText = "";
  BuildContext _context;

  QrData _scannedQrData;
  String _barcodeData = "";
  String _recipient;

  void _syncInitHandshakeStepTwoHandler(dynamic param) {
    Log.debug("in init handler");
    Log.debug("recieved: $param");
    try {
      var scannerInfo = QrData.fromMap(param);

      if (scannerInfo.receivedNonce == _responseNonce) {
        var tmpMap = <String, dynamic>{
          "status": "received",
          "received_nonce": scannerInfo.generatedNonce,
        };
        Log.debug(tmpMap);
        var tmpNote = np.Notification(np.NotificationType.SyncInitStepThree,
            data: tmpMap);
        notify.sendMessageToAnotherDevice(
            deviceIDs: <String>[_recipient], message: tmpNote);

        // go to selector
        Log.debug("Moving on to the next step");
        _setDevice(new Device(deviceID: _recipient));
        _nextStep(_context);
      }
    } catch (e) {
      Log.debug("error in _syncInitResponseHandler: ${e.toString()}");
    }
  }

  Future<void> _sendInitiationMessage() async {
    if (_scannedQrData.isValid()) {
      Log.debug("sending initiation message");

      setState(() {
        _recipient = _scannedQrData.deviceId;
      });

      var tmpMap = <String, dynamic>{
        "device_id": notify.deviceId,
        "received_nonce": _scannedQrData.generatedNonce,
        "generated_nonce": _responseNonce,
      };
      Log.debug(tmpMap);
      var tmpNote =
          np.Notification(np.NotificationType.SyncInitStepOne, data: tmpMap);
      await notify.sendMessageToAnotherDevice(
          deviceIDs: <String>[_recipient], message: tmpNote);
    }
  }

  @override
  void initState() {
    super.initState();
    Log.debug("in initState");
    _fabPressFunction = this.widget.fabPressFunction;
    _nextStep = this.widget.nextStep;
    _setDevice = this.widget.setDevice;

    Log.debug(_qrData.toString());
    Log.debug(_responseNonce);

    notify.syncInitHandshakeStepTwoHandler = _syncInitHandshakeStepTwoHandler;

    scan();
  }

  @override
  Widget build(BuildContext context) {
    final bodyHeight = MediaQuery.of(context).size.height -
        MediaQuery.of(context).viewInsets.bottom;
    setState(() {
      _context = context;
    });

    // check state of barcode and error string
    // if the qr is a valid QrData start processing
    if (_barcodeData != null &&
        _barcodeData.isNotEmpty &&
        _scannedQrData != null &&
        _scannedQrData.isValid()) {
      _sendInitiationMessage();

      return MaterialApp(
        title: _title,
        home: Scaffold(
          appBar: AppBar(
            title: Text(_title),
          ),
          drawer: AppDrawer(
              currentPage: NullPassRoute.QrScanner,
              reloadSecretList: (dynamic) {}),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              if (isDebug)
                Text(
                  "Barcode: ${_scannedQrData.toString()}",
                ),
              CenterLoader(),
              ListTile(
                title: RaisedButton(
                  onPressed: scan,
                  child: Text(
                    "Rescan QR Code",
                    style: TextStyle(color: Colors.white),
                  ),
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _fabPressFunction,
            tooltip: 'QR Code',
            child: Icon(CommunityMaterialIcons.qrcode_edit),
          ),
        ),
      );
    } else if (_errorText.startsWith(_invalidDataType) ||
        _errorText == _noDeviceID) {
      scan();
      return MaterialApp(
        title: _title,
        home: Scaffold(
          appBar: AppBar(
            title: Text(_title),
          ),
          drawer: AppDrawer(
              currentPage: NullPassRoute.QrScanner,
              reloadSecretList: (dynamic) {}),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                "Error: $_errorText",
                style: TextStyle(color: Colors.red),
              ),
              ListTile(
                title: RaisedButton(
                  onPressed: scan,
                  child: Text(
                    "Rescan QR Code",
                    style: TextStyle(color: Colors.white),
                  ),
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _fabPressFunction,
            tooltip: 'QR Code',
            child: Icon(CommunityMaterialIcons.qrcode_edit),
          ),
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
              currentPage: NullPassRoute.QrScanner,
              reloadSecretList: (dynamic) {}),
          body: Center(
            child: RepaintBoundary(
              child: Container(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    if (_errorText != null && _errorText.isNotEmpty)
                      Text(
                        "Error: $_errorText",
                        style: TextStyle(color: Colors.red),
                      ),
                    ListTile(
                      title: RaisedButton(
                        onPressed: scan,
                        child: Text(
                          "Rescan QR Code",
                          style: TextStyle(color: Colors.white),
                        ),
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _fabPressFunction,
            tooltip: 'QR Code',
            child: Icon(CommunityMaterialIcons.qrcode_edit),
          ),
        ),
      );
    }
  }

  Future<void> scan() async {
    try {
      String barcode = await BarcodeScanner.scan();
      Log.debug(barcode);
      var qrd = jsonDecode(barcode);
      var tmpData = QrData.fromMap(qrd);
      if (tmpData.isValid()) {
        setState(() {
          this._errorText = "";
          this._barcodeData = barcode;
          _scannedQrData = QrData.fromMap(qrd);
        });
      } else if (tmpData.deviceId == null || tmpData.deviceId.isEmpty) {
        setState(() {
          this._errorText = _noDeviceID;
          this._barcodeData = "";
          _scannedQrData = null;
        });
      }
    } on TypeError catch (e) {
      setState(() {
        this._errorText = "$_invalidDataType: $e";
        this._barcodeData = "";
      });
    } on PlatformException catch (e) {
      if (e.code == BarcodeScanner.CameraAccessDenied) {
        setState(() {
          this._errorText = "The user did not grant the camera permission!";
          this._barcodeData = "";
        });
      } else {
        setState(() {
          this._errorText = "Unknown error: $e";
          this._barcodeData = "";
        });
      }
    } on FormatException {
      setState(() {
        this._errorText =
            "null (User returned using the 'back'-button before scanning anything)";
        this._barcodeData = "";
      });
    } catch (e) {
      Log.debug(e.runtimeType);
      setState(() {
        this._errorText = "Unknown error: $e";
        this._barcodeData = "";
      });
    }
  }
}
