import 'dart:core';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:nullpass/models/otp_details.dart';
import 'package:nullpass/screens/devices/scanQrCode.dart';
import 'package:nullpass/services/logging.dart';

class OtpQrScan {
  final String otp = "";

  static OTPDetails _parseOtpQrPayload(Uri input) {
    // otpauth://totp/ACME%20Co:john@example.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=ACME%20Co&algorithm=SHA1&digits=6&period=30
    // otpauth://totp/{username}?secret={key}&issuer={provider_name}

    if (input == null || !input.isScheme('otpauth')) {
      throw ArgumentError('the input provided is not a valid otpauth:// url');
    }

    var inputPath = Uri.decodeComponent(input.path);
    if (inputPath.startsWith('/') && inputPath.length > 1) {
      inputPath = inputPath.substring(1);
    }

    final type = Uri.decodeComponent(input.host);
    final identifier = inputPath;
    final params = input.queryParameters;
    final secret = Uri.decodeComponent(params['secret']);
    final issuer = Uri.decodeComponent(params['issuer']);
    final algorithm = Uri.decodeComponent(params['algorithm']);
    final digits = Uri.decodeComponent(params['digits']);
    final period = Uri.decodeComponent(params['period']);

    final otpDetails = OTPDetails(
      secret: secret,
      name: identifier,
      issuer: issuer,
      algorithm: OTPAlgorithmFromString(algorithm, OTPAlgorithm.SHA1),
      type: OTPTypeFromString(type, OTPType.TOTP),
      counter: int.tryParse(period),
      digits: OTPDigitCountFromInt(int.tryParse(digits), OTPDigitCount.SIX),
    );

    return otpDetails;
  }

  static Future<OTPDetails> scan() async {
    var scanResult = await BarcodeScanner.scan(
      options: ScanOptions(
        restrictFormat: [BarcodeFormat.qr],
      ),
    );
    if (scanResult.type != ResultType.Barcode) {
      if (scanResult.type == ResultType.Error) {
        throw Exception("The barcode scan returned an error:\n" +
            "Raw Content - ${scanResult.rawContent}" +
            "Scan Result - $scanResult");
      }
      if (scanResult.type == ResultType.Cancelled) {
        throw FormatException("The scan was cancelled:\n" +
            "Raw Content - ${scanResult.rawContent}" +
            "Scan Result - $scanResult");
      }
      throw Exception("The barcode was not scanned:\n" +
          "Raw Content - ${scanResult.rawContent}" +
          "Scan Result - $scanResult");
    }

    if (scanResult.format != BarcodeFormat.qr) {
      throw BarcodeFormatError("The barcode scanned was invalid:\n" +
          "Format Type - ${scanResult.format.name}\n" +
          "Format Note - ${scanResult.formatNote}\n" +
          "Raw Content - ${scanResult.rawContent}" +
          "Scan Result - $scanResult");
    }

    String qrcode = scanResult.rawContent;
    Log.debug(qrcode);
    var qrd = _parseOtpQrPayload(Uri.tryParse(qrcode));

    return qrd;
  }
}
