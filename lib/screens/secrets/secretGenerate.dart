/*
 * Created by Ilan Rasekh on 2019/10/2
 * Copyright (c) 2019 Pseudorand Development. All rights reserved.
 */

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nullpass/common.dart';
import 'package:nullpass/models/secret.dart';
import 'package:nullpass/screens/secrets/secretEdit.dart';

class SecretGenerate extends StatefulWidget {
  final bool inEditor;
  SecretGenerate({Key key, this.inEditor = false}) : super(key: key);
  _SecretGenerateState createState() => _SecretGenerateState();
}

class _SecretGenerateState extends State<SecretGenerate> {
  String _secretText = 'randomlylongtextfieldthatisnotactuallychangingyet';
  int _secretLength;
  bool _alphaCharacters;
  bool _numericCharacters;
  bool _symbolCharacters;

  @override
  void initState() {
    super.initState();

    bool spSet = sharedPrefs.getBool(SharedPrefSetupKey);
    if (spSet == null || !spSet) setupSharedPreferences();

    _secretLength = sharedPrefs.getInt(SecretLengthPrefKey);
    _alphaCharacters = sharedPrefs.getBool(AlphaCharactersPrefKey);
    _numericCharacters = sharedPrefs.getBool(NumericCharactersPrefKey);
    _symbolCharacters = sharedPrefs.getBool(SymbolCharactersPrefKey);
  }

  String generateSecretMessage([int length = 32]) {
    if (!_alphaCharacters && !_numericCharacters && !_symbolCharacters) {
      return 'At least one character set must be selected';
    }

    Set<int> invalidCodes = Set<int>();

    if (!_alphaCharacters) {
      // TODO: just do an AddAll on a static charCode set
      // const LOWER_ALPHA_START = 97;
      // const LOWER_ALPHA_END = 122;
      for (int x = 97; x <= 122; x++) {
        invalidCodes.add(x);
      }

      // const UPPER_ALPHA_START = 65;
      // const UPPER_ALPHA_END = 90;
      for (int x = 65; x <= 90; x++) {
        invalidCodes.add(x);
      }
    }

    if (!_numericCharacters) {
      // TODO: just do an AddAll on a static charCode set
      // const NUMERIC_START = 48;
      // const NUMERIC_END = 57;
      for (int x = 48; x <= 57; x++) {
        invalidCodes.add(x);
      }
    }

    if (!_symbolCharacters) {
      // TODO: just do an AddAll on a static charCode set
      // const ASCII_START = 33;
      // const ASCII_END = 126;
      // less alpha and numeric
      for (int x = 33; x <= 47; x++) {
        invalidCodes.add(x);
      }
      for (int x = 58; x <= 64; x++) {
        invalidCodes.add(x);
      }
      for (int x = 91; x <= 96; x++) {
        invalidCodes.add(x);
      }
      for (int x = 123; x <= 126; x++) {
        invalidCodes.add(x);
      }
    }

    final Random _random = Random.secure();
    List<int> charCodes = <int>[];
    int attempts = 0;
    int pos = 0;
    while (pos < length) {
      attempts = 1;
      int rInt = (_random.nextInt(93)) + 33;
      if (!invalidCodes.contains(rInt)) {
        charCodes.add(rInt);
        pos++;
      }

      if (attempts == 250000) {
        return 'failed to generate secret: reached max attempts';
      }
    }

    return String.fromCharCodes(charCodes);
  }

  @override
  Widget build(BuildContext context) {
    _secretText = generateSecretMessage(_secretLength);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          ListTile(
            title: SelectableText(
              _secretText,
              maxLines: 1,
            ),
            trailing: IconButton(
                icon: Icon(Icons.content_copy),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: _secretText));
                }),
          ),
          ListTile(
            title: Text('Password Length'),
            trailing: Container(
              width: 50,
              child: TextFormField(
                  textAlign: TextAlign.end,
                  keyboardType: TextInputType.number,
                  initialValue: _secretLength.toString(),
                  autocorrect: true,
                  onChanged: (value) {
                    int tempVal = -1;
                    try {
                      tempVal = int.parse(value);
                    } catch (e) {}
                    if (tempVal < 1) tempVal = _secretLength;

                    setState(() {
                      _secretLength = tempVal;
                      _secretText = generateSecretMessage(tempVal);
                    });
                  },
                  decoration: InputDecoration(border: InputBorder.none)),
            ),
          ),
          ListTile(
            title: Text('Alpha Characters'),
            trailing: Switch(
                value: _alphaCharacters,
                onChanged: (value) {
                  setState(() {
                    this._alphaCharacters = value;
                    _secretText = generateSecretMessage(_secretLength);
                  });
                }),
          ),
          ListTile(
            title: Text('Numeric Characters'),
            trailing: Switch(
                value: _numericCharacters,
                onChanged: (value) {
                  setState(() {
                    this._numericCharacters = value;
                    _secretText = generateSecretMessage(_secretLength);
                  });
                }),
          ),
          ListTile(
            title: Text('Symbol Characters'),
            trailing: Switch(
                value: _symbolCharacters,
                onChanged: (value) {
                  setState(() {
                    this._symbolCharacters = value;
                    _secretText = generateSecretMessage(_secretLength);
                  });
                }),
          ),
          ListTile(
            title: RaisedButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: _secretText));
                Navigator.pop(context, _secretText);
                if (!widget.inEditor) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          // builder: (context) => SecretEdit(edit: SecretEditType.Create, // SecretNew(
                          builder: (context) => SecretEdit(
                              edit: SecretEditType.Create, // SecretNew(
                              secret: new Secret(
                                nickname: '',
                                website: '',
                                username: '',
                                message: _secretText,
                              ))));
                }
              },
              child: Text(
                'Use',
                style: TextStyle(color: Colors.white),
              ),
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}
