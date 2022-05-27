import 'dart:core';
import 'package:barcode_scan2/barcode_scan2.dart';
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

enum OTPAlgorithm { UNSPECIFIED, SHA1, SHA256, SHA512, MD5 }
const List<String> OTPAlgorithmNames = [
  'UNSPECIFIED',
  'SHA1',
  'SHA256',
  'SHA512',
  'MD5'
];
const Map<OTPAlgorithm, String> OTPAlgorithmToString = {
  OTPAlgorithm.UNSPECIFIED: 'UNSPECIFIED',
  OTPAlgorithm.SHA1: 'SHA1',
  OTPAlgorithm.SHA256: 'SHA256',
  OTPAlgorithm.SHA512: 'SHA512',
  OTPAlgorithm.MD5: 'MD5',
};
OTPAlgorithm OTPAlgorithmFromString(String value, [OTPAlgorithm defaultValue]) {
  if (value != null && value.trim().toUpperCase() == 'SHA1') {
    return OTPAlgorithm.SHA1;
  } else if (value != null && value.trim().toUpperCase() == 'SHA256') {
    return OTPAlgorithm.SHA256;
  } else if (value != null && value.trim().toUpperCase() == 'SHA512') {
    return OTPAlgorithm.SHA512;
  } else if (value != null && value.trim().toUpperCase() == 'MD5') {
    return OTPAlgorithm.MD5;
  } else {
    return defaultValue ?? OTPAlgorithm.UNSPECIFIED;
  }
}

enum OTPType { UNSPECIFIED, HOTP, TOTP }
const List<String> OTPTypeNames = ['UNSPECIFIED', 'HOTP', 'TOTP'];
const Map<OTPType, String> OTPTypeToString = {
  OTPType.UNSPECIFIED: 'UNSPECIFIED',
  OTPType.HOTP: 'HOTP',
  OTPType.TOTP: 'TOTP',
};
OTPType OTPTypeFromString(String value, [OTPType defaultValue]) {
  if (value != null && value.trim().toUpperCase() == OTPType.TOTP) {
    return OTPType.TOTP;
  } else if (value != null && value.trim().toUpperCase() == OTPType.HOTP) {
    return OTPType.HOTP;
  } else {
    return defaultValue ?? OTPType.UNSPECIFIED;
  }
}

enum OTPDigitCount { UNSPECIFIED, SIX, EIGHT }
const List<String> OTPDigitCountNames = ['UNSPECIFIED', 'SIX', 'EIGHT'];
const Map<OTPDigitCount, String> OTPDigitCountToString = {
  OTPDigitCount.UNSPECIFIED: 'UNSPECIFIED',
  OTPDigitCount.SIX: 'SIX',
  OTPDigitCount.EIGHT: 'EIGHT',
};
const Map<OTPDigitCount, int> OTPDigitCountToInt = {
  OTPDigitCount.UNSPECIFIED: -1,
  OTPDigitCount.SIX: 6,
  OTPDigitCount.EIGHT: 8,
};
OTPDigitCount OTPDigitCountFromInt(int value, [OTPDigitCount defaultValue]) {
  if (value == 6) {
    return OTPDigitCount.SIX;
  } else if (value == 8) {
    return OTPDigitCount.EIGHT;
  } else {
    return defaultValue ?? OTPDigitCount.UNSPECIFIED;
  }
}

class OTPDetails {
  String secret;
  String name;
  String issuer;
  OTPAlgorithm algorithm;
  OTPType type;
  int counter;
  OTPDigitCount _digits;
  int get digits => OTPDigitCountToInt[_digits] ?? -1;
  set digits(int value) => _digits = OTPDigitCountFromInt(value);

  OTPDetails({
    String secret,
    String name,
    String issuer,
    OTPAlgorithm algorithm,
    OTPType type,
    int counter,
    OTPDigitCount digits,
  }) {
    this.secret = secret;
    this.name = name;
    this.issuer = issuer;
    this.algorithm = algorithm;
    this.type = type;
    this.counter = counter;
    this._digits = digits;
  }

  @override
  String toString() {
    return '{secret: $secret, name: $name, issuer: $issuer, algorithm: ${algorithm.name}, digits: $digits, type: ${type.name}, counter: $counter}';
  }

  Map<String, dynamic> toJson() {
    return {
      'secret': secret,
      'name': name,
      'issuer': issuer,
      'algorithm': algorithm.name,
      'digits': digits,
      'type': type.name,
      'counter': counter.toInt(),
    };
  }
}
