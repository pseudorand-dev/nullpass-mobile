/*
 * Created by Ilan Rasekh on 2019/10/2
 * Copyright (c) 2019 Pseudorand Development. All rights reserved.
 */

import 'package:community_material_icon/community_material_icon.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:nullpass/common.dart';
import 'package:nullpass/models/secret.dart';
import 'package:nullpass/screens/app.dart';
import 'package:nullpass/screens/devices/manageDevices.dart';
import 'package:nullpass/screens/devices/syncDevices.dart';
import 'package:nullpass/screens/secretEdit.dart';
import 'package:nullpass/screens/secretGenerate.dart';
import 'package:nullpass/screens/secretSearch.dart';
import 'package:nullpass/screens/settings.dart';
import 'package:nullpass/widgets.dart';

class AppDrawer extends StatelessWidget {
  final NullPassRoute currentPage;
  final Function reloadSecretList;

  AppDrawer(
      {Key key, @required this.currentPage, @required this.reloadSecretList})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // FlutterStatusbarcolor.setStatusBarColor(Colors.lightBlue[800]);
    return Container(
      color: Colors.blue,
      width: 275,
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: const EdgeInsets.all(0.0),
          children: <Widget>[
            /*
            DrawerHeader(
                child: Container(
                    child: Text('nullpass-dev@gmail.com')
                ),
              decoration: BoxDecoration(color: Colors.blue),
            ),
            */
            UserAccountsDrawerHeader(
                accountName: Text('NullPass Test'),
                accountEmail: Text('nullpass-dev@gmail.com')),
            ListTile(
              selected: (currentPage == NullPassRoute.ViewSecretsList),
              leading: Icon(Icons.dehaze),
              title: Text('View Secrets',
                  style: TextStyle(
                      color: (currentPage == NullPassRoute.ViewSecretsList)
                          ? ThemeData.light().accentColor
                          : ThemeData.light().unselectedWidgetColor)),
              onTap: () {
                Navigator.pop(context);
                if (currentPage != NullPassRoute.ViewSecretsList) {
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) => NullPassApp()));
                }
              },
            ),
            ListTile(
              selected: (currentPage == NullPassRoute.FindSecret),
              leading: Icon(Icons.search),
              title: Text('Find Secrets',
                  style: TextStyle(
                      color: (currentPage == NullPassRoute.FindSecret)
                          ? ThemeData.light().accentColor
                          : ThemeData.light().unselectedWidgetColor)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => SecretSearch()));
              },
            ),
            ListTile(
              selected: (currentPage == NullPassRoute.NewSecret),
              leading: Icon(Icons.edit),
              title: Text('New Secret',
                  style: TextStyle(
                      color: (currentPage == NullPassRoute.NewSecret)
                          ? ThemeData.light().accentColor
                          : ThemeData.light().unselectedWidgetColor)),
              onTap: () async {
                Navigator.pop(context);
                if (currentPage != NullPassRoute.NewSecret) {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          // builder: (context) => SecretEdit(edit: SecretEditType.Create, // SecretNew(
                          builder: (context) => SecretEdit(
                              edit: SecretEditType.Create,
                              secret: new Secret(
                                  nickname: '',
                                  website: '',
                                  username: '',
                                  message: ''))));
                  this.reloadSecretList('true');
                }
              },
            ),
            ListTile(
              selected: (currentPage == NullPassRoute.GenerateSecret),
              leading: Icon(Icons.lock),
              title: Text('Generate Secret',
                  style: TextStyle(
                      color: ThemeData.light().unselectedWidgetColor)),
              onTap: () async {
                Navigator.pop(context);
                await showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return new SecretGenerate(inEditor: false);
                    });
                /*
                if (result != null && result.toString().trim() != '') {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          // builder: (context) => SecretEdit(edit: SecretEditType.Create, // SecretNew(
                          builder: (context) => SecretAlt(
                              edit: SecretAltType.Create,
                              secret: new Secret(
                                  nickname: '',
                                  website: '',
                                  username: '',
                                  password: result.toString()))));
                }
                */
                // this.reloadSecretList('true');
              },
            ),
            FormDivider(),
            ListTile(
              selected: (currentPage == NullPassRoute.QrCode),
              leading: new Icon(CommunityMaterialIcons.qrcode_edit),
              title: Text('Sync To This Device',
                  style: TextStyle(
                      color: (currentPage == NullPassRoute.QrCode)
                          ? ThemeData.light().accentColor
                          : ThemeData.light().unselectedWidgetColor)),
              onTap: () {
                Navigator.pop(context);
                if (currentPage != NullPassRoute.QrCode) {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              SyncDevices(syncState: SyncState.qrcode)));
                }
              },
            ),
            ListTile(
              selected: (currentPage == NullPassRoute.QrScanner),
              leading: new Icon(CommunityMaterialIcons.qrcode_scan),
              title: Text('Sync To New Device',
                  style: TextStyle(
                      color: (currentPage == NullPassRoute.QrScanner)
                          ? ThemeData.light().accentColor
                          : ThemeData.light().unselectedWidgetColor)),
              onTap: () {
                Navigator.pop(context);
                if (currentPage != NullPassRoute.QrScanner) {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              SyncDevices(syncState: SyncState.scan)));
                }
              },
            ),
            ListTile(
              selected: (currentPage == NullPassRoute.ManageDevices),
              leading: Icon(Icons.devices_other),
              title: Text('Manage Devices',
                  style: TextStyle(
                      color: (currentPage == NullPassRoute.ManageDevices)
                          ? ThemeData.light().accentColor
                          : ThemeData.light().unselectedWidgetColor)),
              onTap: () {
                Navigator.pop(context);
                if (currentPage != NullPassRoute.ManageDevices) {
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) => ManageDevices()));
                }
              },
            ),
            FormDivider(),
            ListTile(
              selected: (currentPage == NullPassRoute.Settings),
              leading: Icon(Icons.settings),
              title: Text('Settings',
                  style: TextStyle(
                      color: (currentPage == NullPassRoute.Settings)
                          ? ThemeData.light().accentColor
                          : ThemeData.light().unselectedWidgetColor)),
              onTap: () {
                Navigator.pop(context);
                if (currentPage != NullPassRoute.Settings) {
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) => Settings()));
                  // Navigator.push(context, MaterialPageRoute(builder: (context) => Settings()));
                }
              },
            ),
            ListTile(
              selected: (currentPage == NullPassRoute.HelpAndFeedback),
              leading: Icon(Icons.feedback),
              title: Text(
                'Help & Feedback',
                style: TextStyle(
                    color: (currentPage == NullPassRoute.HelpAndFeedback)
                        ? ThemeData.light().accentColor
                        : ThemeData.light().unselectedWidgetColor),
              ),
              onTap: () {
                Navigator.pop(context);
                // if (currentPage != NullPassRoute.HelpAndFeedback) {
                //   Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => NullPassApp()));
                // }
              },
            ),
            ListTile(
              selected: false,
              leading: Icon(Icons.info),
              title: Text('About NullPass',
                  style: TextStyle(
                      color: ThemeData.light().unselectedWidgetColor)),
              onTap: () {
                Navigator.pop(context);
                showAboutDialog(
                    context: context,
                    applicationName: 'NullPass',
                    applicationVersion: '0.1.0',
                    applicationLegalese: 'Pseudorand Development',
                    applicationIcon: new Container(
                        height: 50.0,
                        width: 50.0,
                        child: Image.asset(
                            'assets/images/null_iosScaledDown_1500_Transparent.png'))
                    // children: aboutBoxChildren,
                    );
              },
            )
            /*
            AboutListTile(
              applicationName: 'NullPass',
              applicationVersion: '0.1.0',
              applicationLegalese: 'Pseudorand Development',
              applicationIcon: new Container(
                  height: 50.0,
                  width: 50.0,
                  child: Image.asset(
                      'assets/images/null_iosScaledDown_1500_Transparent.png')),
            ),
             */
          ],
        ),
      ),
    );
  }
}
