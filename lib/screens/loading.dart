/*
 * Created by Ilan Rasekh on 2020/3/12
 * Copyright (c) 2020 Pseudorand Development. All rights reserved.
 */
import 'package:flutter/material.dart';
import 'package:nullpass/screens/appDrawer.dart';
import 'package:nullpass/widgets.dart';

class LoadingPage extends StatelessWidget {
  final String title;
  final NullPassRoute route;

  LoadingPage({this.title, this.route});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      home: Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        drawer: AppDrawer(currentPage: route, reloadSecretList: (dynamic) {}),
        body: Container(
          child: CenterLoader(),
        ),
      ),
    );
  }
}
