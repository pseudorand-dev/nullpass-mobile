/*
 * Created by Ilan Rasekh on 2019/10/4
 * Copyright (c) 2019 Pseudorand Development. All rights reserved.
 */

import 'package:shared_preferences/shared_preferences.dart';

SharedPreferences sharedPrefs;
const String SecretLengthPrefKey = 'SecretLength';
const String AlphaCharactersPrefKey = 'AlphaCharacters';
const String NumericCharactersPrefKey = 'NumericCharacters';
const String SymbolCharactersPrefKey = 'SymbolCharacters';
const String SharedPrefSetupKey = 'SpSetup';
const String InAppWebpagesPrefKey = 'InAppWebpages';

void setupSharedPreferences() {
  if (!sharedPrefs.containsKey(SecretLengthPrefKey))
    sharedPrefs.setInt(SecretLengthPrefKey, 512).then((worked) {
      if (worked) print('Added $SecretLengthPrefKey');
    });

  if (!sharedPrefs.containsKey(AlphaCharactersPrefKey))
    sharedPrefs.setBool(AlphaCharactersPrefKey, true).then((worked) {
      if (worked) print('Added $AlphaCharactersPrefKey');
    });

  if (!sharedPrefs.containsKey(NumericCharactersPrefKey))
    sharedPrefs.setBool(NumericCharactersPrefKey, true).then((worked) {
      if (worked) print('Added $NumericCharactersPrefKey');
    });

  if (!sharedPrefs.containsKey(SymbolCharactersPrefKey))
    sharedPrefs.setBool(SymbolCharactersPrefKey, true).then((worked) {
      if (worked) print('Added $SymbolCharactersPrefKey');
    });

  if (!sharedPrefs.containsKey(InAppWebpagesPrefKey))
    sharedPrefs.setBool(InAppWebpagesPrefKey, true).then((worked) {
      if (worked) print('Added $InAppWebpagesPrefKey');
    });

  if (!sharedPrefs.containsKey(SharedPrefSetupKey))
    sharedPrefs.setBool(SharedPrefSetupKey, true).then((worked) {
      if (worked) print('Shared Preference Setup Complete');
    });
}
