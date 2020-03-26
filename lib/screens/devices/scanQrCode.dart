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
import 'package:nullpass/models/qrData.dart';
import 'package:nullpass/models/syncRegistration.dart';
import 'package:nullpass/screens/appDrawer.dart';
import 'package:nullpass/services/datastore.dart';
import 'package:nullpass/services/logging.dart';
import 'package:nullpass/services/notification.dart' as np;
import 'package:nullpass/widgets.dart';
import 'package:openpgp/key_options.dart';
import 'package:openpgp/key_pair.dart';
import 'package:openpgp/openpgp.dart';
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
  Function _fabPressFunction;
  Function(BuildContext) _nextStep;
  Function(Device) _setDevice;
  String _errorText = "";
  BuildContext _context;

  String _responseNonce;
  KeyPair _encryptionKeyPair;

  String _barcodeData = "";
  bool _initiated = false;
  QrData _scannedQrData;
  String _recipient;
  String _scannedPublicKey;

  Future<void> _initiateHandshake() async {
    if (_scannedQrData.isValid()) {
      Log.debug("sending initiation message");

      setState(() {
        _recipient = _scannedQrData.deviceId;
      });

      if (_encryptionKeyPair == null) {
        _encryptionKeyPair = await NullPassDB.instance.getEncryptionKeyPair();
      }

      var receivedNonce = _scannedQrData.generatedNonce;

      var sd = SyncRegistration(
        deviceId: notify.deviceId,
        pgpPubKey: _encryptionKeyPair.publicKey,
        generatedNonce: _responseNonce,
        receivedNonce: receivedNonce,
      );

      var encryptedMsg = await OpenPGP.encryptSymmetric(
          sd.toString(), receivedNonce,
          options: KeyOptions(cipher: Cypher.aes256));

      // var tmpMap = await sd.toEncryptedMap(_scannedQrData.pgpPubKey);
      // QrData(
      //   deviceId: notify.deviceId,
      //   receivedNonce: _scannedQrData.generatedNonce,
      //   generatedNonce: _responseNonce,
      //   pgpPubKey: encryptionKeyPair.publicKey,
      // ).toMap();
      // <String, dynamic>{
      //   "device_id": notify.deviceId,
      //   "received_nonce": _scannedQrData.generatedNonce,
      //   "generated_nonce": _responseNonce,
      // };
      Log.debug(encryptedMsg);
      Log.debug(encryptedMsg.length);

      var tmpNotification = np.Notification(np.NotificationType.SyncInitStepOne,
          data: encryptedMsg);

      await notify.sendMessageToAnotherDevice(
          deviceIDs: <String>[_recipient], message: tmpNotification);
    }
  }

  void _syncInitHandshakeStepTwoHandler(dynamic param) async {
    Log.debug("in init step two handler");
    Log.debug("recieved: $param");
    try {
      var decryptedMsg = await OpenPGP.decrypt(
          param as String, _encryptionKeyPair.privateKey, "");
      var syncRegMap = jsonDecode(decryptedMsg);
      var scannedResp = SyncRegistration.fromMap(syncRegMap);

      if (scannedResp.receivedNonce == _responseNonce) {
        setState(() {
          _scannedPublicKey = scannedResp.pgpPubKey;
          _responseNonce = Uuid().v4();
        });

        var sd = SyncRegistration(
          deviceId: notify.deviceId,
          receivedNonce: scannedResp.generatedNonce,
          generatedNonce: _responseNonce,
        );

        var encryptedMsg =
            await OpenPGP.encrypt(sd.toString(), scannedResp.pgpPubKey);

        Log.debug(encryptedMsg);
        var tmpNote = np.Notification(np.NotificationType.SyncInitStepThree,
            data: encryptedMsg);
        notify.sendMessageToAnotherDevice(
            deviceIDs: <String>[_recipient], message: tmpNote);

        /*
        // go to selector
        Log.debug("Moving on to the next step");
        notify.setDefaultNotificationHandlers();

        _setDevice(
            new Device(deviceID: _recipient, encryptionKey: _scannedPublicKey));
        _nextStep(_context);
        */
      }
    } catch (e) {
      Log.debug("error init step two handler: ${e.toString()}");
    }
  }

  void _syncInitHandshakeStepFourHandler(dynamic param) async {
    Log.debug("in init step four handler");
    Log.debug("recieved: $param");
    try {
      var decryptedMsg = await OpenPGP.decrypt(
          param as String, _encryptionKeyPair.privateKey, "");
      var syncRegMap = jsonDecode(decryptedMsg);
      var scannedResp = SyncRegistration.fromMap(syncRegMap);

      if (scannedResp.receivedNonce == _responseNonce) {
        // go to selector
        Log.debug("Moving on to the next step");
        notify.setDefaultNotificationHandlers();

        _setDevice(
            new Device(deviceID: _recipient, encryptionKey: _scannedPublicKey));
        _nextStep(_context);
      }
    } catch (e) {
      Log.debug("error init step four handler: ${e.toString()}");
    }
  }

  @override
  void initState() {
    super.initState();
    Log.debug("in initState");
    _fabPressFunction = this.widget.fabPressFunction;
    _nextStep = this.widget.nextStep;
    _setDevice = this.widget.setDevice;

    _responseNonce = Uuid().v4();
    Log.debug(_responseNonce);

    notify.syncInitHandshakeStepTwoHandler = _syncInitHandshakeStepTwoHandler;
    notify.syncInitHandshakeStepFourHandler = _syncInitHandshakeStepFourHandler;

    scan();
    NullPassDB.instance.getEncryptionKeyPair().then((kp) {
      setState(() {
        _encryptionKeyPair = kp;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    setState(() {
      _context = context;
    });

    // check state of barcode and error string
    // if the qr is a valid QrData start processing
    if (_barcodeData != null &&
        _barcodeData.isNotEmpty &&
        _scannedQrData != null &&
        _scannedQrData.isValid()) {
      if (!_initiated) {
        _initiateHandshake();
        _initiated = true;
      }

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

  // TODO: return valuable errors
  Future<void> scan() async {
    try {
      _initiated = false;
      String barcode = await BarcodeScanner.scan();
      Log.debug(barcode);
      var qrd = jsonDecode(barcode);
      var tmpData = QrData.fromMap(qrd);
      if (tmpData.isValid()) {
        setState(() {
          this._errorText = "";
          this._barcodeData = barcode;
          // _scannedQrData = QrData.fromMap(qrd);
          _scannedQrData = tmpData;
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
    } on FormatException catch (e) {
      Log.debug("format exception ${e.toString()}");
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
