import 'package:nullpass/services/datastore.dart';
import 'package:nullpass/services/logging.dart';
import 'package:openpgp/key_options.dart';
import 'package:openpgp/key_pair.dart';
import 'package:openpgp/openpgp.dart';
import 'package:openpgp/options.dart';

class Crypto {
  get hasKeyPair {
    return _hasKeyPair;
  }

  bool _hasKeyPair = false;

  static final Crypto _singleton = new Crypto._internal();
  Crypto._internal();

  static Future<Crypto> instance = _init();
  static Future<Crypto> _init() async {
    var dbKP = await NullPassDB.instance.getEncryptionKeyPair();
    if (!_isKeyPairValid(dbKP)) {
      var newkp = await _setupKeyPair();
      if (!_isKeyPairValid(newkp)) {
        throw Exception("Could not setup and store a valid key pair");
      }
    }
    _singleton._hasKeyPair = true;
    return _singleton;
  }
}

Future<KeyPair> _setupKeyPair() async {
  try {
    var kp = await OpenPGP.generate(
      options: Options(
        keyOptions: KeyOptions(
          cipher: Cypher.aes256,
          compression: Compression.none,
          compressionLevel: 0,
          hash: Hash.sha512,
          rsaBits: 4096,
        ),
      ),
    );

    Log.debug("publicKey: ${kp.publicKey}");
    Log.debug("privateKey: ${kp.privateKey}");

    if (await NullPassDB.instance.insertEncryptionKeyPair(kp)) return kp;
  } catch (e) {
    Log.debug(
        "An error occurred while trying to setup encryption key pair: ${e.toString()}");
  }
  return null;
}

bool _isKeyPairValid(KeyPair kp) {
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
