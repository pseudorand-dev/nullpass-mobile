/*
 * Created by Ilan Rasekh on 2019/10/30
 * Copyright (c) 2019 Pseudorand Development. All rights reserved.
 */
import 'package:flutter/material.dart';

class DefaultThumbnnail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Colors.transparent,
      backgroundImage:
          AssetImage('assets/images/null_iosScaledDown_1500_Transparent.png'),
    );
  }
}

class FormDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 0.5,
      thickness: 1,
      indent: 16,
      endIndent: 16,
    );
  }
}
