/*
 * Created by Ilan Rasekh on 2019/9/27
 * Copyright (c) 2019 Pseudorand Development. All rights reserved.
 */

import 'package:flutter/material.dart';
import 'package:nullpass/screens/app.dart';
import 'package:secure_screen_switcher/secure_screen_switcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SecureScreenSwitcher.secureApp();
  runApp(NullPassApp());
}
