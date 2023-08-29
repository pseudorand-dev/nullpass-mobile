/*
 * Created by Ilan Rasekh on 2020/3/15
 * Copyright (c) 2020 Pseudorand Development. All rights reserved.
 */

import 'package:nullpass/services/datastore.dart';
import 'package:nullpass/services/logging.dart';
import 'package:openpgp/openpgp.dart';

class Crypto {
  get hasKeyPair {
    return _hasKeyPair;
  }

  bool _hasKeyPair = false;

  static final Crypto _singleton = new Crypto._internal();
  Crypto._internal();

  static Future<Crypto> instance = _init();
  static Future<Crypto> _init() async {
    var dbEncKP = await NullPassDB.instance.getEncryptionKeyPair();
    if (!Crypto.isKeyPairValid(dbEncKP)) {
      var newkp = await _setupEncryptionKeyPair();
      if (!Crypto.isKeyPairValid(newkp)) {
        throw Exception("Could not setup and store a valid key pair");
      }
    }
    _singleton._hasKeyPair = true;

    return _singleton;
  }

  static bool isKeyPairValid(KeyPair? kp) {
    if (kp != null &&
        kp.publicKey != null &&
        kp.privateKey != null &&
        kp.publicKey.isNotEmpty &&
        kp.privateKey.isNotEmpty) {
      return true;
    } else {
      return false;
    }
  }
}

Future<KeyPair?> _setupEncryptionKeyPair() async {
  try {
    var kp = await OpenPGP.generate(
        options: Options()
          ..keyOptions = (KeyOptions()
            ..hash = Hash.SHA512
            ..rsaBits = 4096
            ..compressionLevel = 0
            ..cipher = Cipher.AES256
            ..compression = Compression.NONE));

    Log.debug("publicKey: ${kp.publicKey}");
    Log.debug("privateKey: ${kp.privateKey}");

    if (await NullPassDB.instance.insertEncryptionKeyPair(kp)) return kp;
  } catch (e) {
    Log.debug(
        "An error occurred while trying to setup encryption key pair: ${e.toString()}");
  }
  return null;
}
