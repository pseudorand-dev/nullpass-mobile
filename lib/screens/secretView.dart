/*
 * Created by Ilan Rasekh on 2019/10/2
 * Copyright (c) 2019 Pseudorand Development. All rights reserved.
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nullpass/common.dart';
import 'package:nullpass/screens/secretEdit.dart';
import 'package:nullpass/secret.dart';
import 'package:url_launcher/url_launcher.dart';

class SecretView extends StatefulWidget {
  Secret secret;

  SecretView({Key key, @required this.secret}) : super(key: key);

  @override
  _SecretViewState createState() => _SecretViewState(secret: this.secret);
}

class _SecretViewState extends State<SecretView> {
  // TODO: evaluate replacing this expensive scaffold key with a better more efficient method - examples https://medium.com/@ksheremet/flutter-showing-snackbar-within-the-widget-that-builds-a-scaffold-3a817635aeb2
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  Secret secret;

  _SecretViewState({@required secret}) {
    if (secret == null) {
      secret = new Secret(nickname: '', website: '', username: '', message: '');
    }
    this.secret = secret;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(secret.nickname),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.delete),
              onPressed: () async {
                NullPassDB npDB = NullPassDB.instance;
                bool success = await npDB.delete(secret.uuid);
                print(success);
                // await showSnackBar(context, 'Deleted!');
                Navigator.pop(context, 'true');
              }),
          IconButton(
              icon: Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => SecretEdit(
                          edit: SecretEditType.Update,
                          secret: new Secret(
                              nickname: secret.nickname,
                              website: secret.website,
                              username: secret.username,
                              message: secret.message,
                              notes: secret.notes,
                              thumbnailURI: secret.thumbnailURI,
                              uuid: secret.uuid))),
                );
                if (isTrue(result)) {
                  NullPassDB npDB = NullPassDB.instance;
                  Secret s = await npDB.getSecretByID(secret.uuid);
                  setState(() {
                    secret = s;
                  });
                }
              }),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            ListTile(
                title: Text('Website'),
                subtitle: Text(secret.website ?? ''),
                trailing: IconButton(
                    icon: Icon(Icons.launch),
                    onPressed: () async {
                      bool openWebpagesInApp =
                          sharedPrefs.getBool(InAppWebpagesPrefKey);
                      var webpage = secret.website;
                      if (!webpage.startsWith('http') &&
                          !webpage.contains('://'))
                        webpage = 'https://' + webpage;
                      if (await canLaunch(webpage)) {
                        await Clipboard.setData(
                            ClipboardData(text: secret.message));
                        await launch(webpage, forceWebView: openWebpagesInApp);
                      } else {
                        _scaffoldKey.currentState.showSnackBar(SnackBar(
                            content: Text('Can\'t launch this website')));
                      }
                    }),
                onLongPress: () async {
                  await Clipboard.setData(
                      ClipboardData(text: secret.thumbnailURI));
                  _scaffoldKey.currentState.showSnackBar(
                      SnackBar(content: Text('Copied the Website')));
                }),
            ListTile(
              title: Text('Username'),
              subtitle: Text(secret.username ?? ''),
              trailing: IconButton(
                  icon: Icon(Icons.content_copy),
                  onPressed: () async {
                    await Clipboard.setData(
                        ClipboardData(text: secret.username));
                    _scaffoldKey.currentState.showSnackBar(
                        SnackBar(content: Text('Copied the Username')));
                  }),
            ),
            ListTile(
              title: Text('Password'),
              subtitle: Text('Hold to view password'),
              trailing: IconButton(
                  icon: Icon(Icons.content_copy),
                  onPressed: () async {
                    await Clipboard.setData(
                        ClipboardData(text: secret.message));
                    _scaffoldKey.currentState.showSnackBar(
                        SnackBar(content: Text('Copied the Password')));
                  }),
              onLongPress: () async {
                await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return SimpleDialog(
                        children: <Widget>[
                          Center(
                            // TODO: customize text:
                            //       - increasing fonts
                            //       - add color so all numbers are a unique color, as well as
                            //         each of lowercase, uppercase, and symbol characters
                            child: SelectableText(secret.message),
                          ),
                        ],
                      );
                    });
              },
            ),
            ListTile(
              title: Text('Password Difficulty'),
              trailing: IconButton(icon: Icon(Icons.stars), onPressed: () {}),
              onLongPress: () {},
            ),
            ListTile(
              title: Text('Notes'),
              subtitle: Text(secret.notes ?? ''),
              trailing: IconButton(
                  icon: Icon(Icons.content_copy),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: secret.notes));
                    _scaffoldKey.currentState.showSnackBar(
                        SnackBar(content: Text('Copied the Notes')));
                  }),
            ),
            ListTile(
                title: Text('Thumbnail'),
                subtitle: Text(secret.thumbnailURI ?? ''),
                onLongPress: () async {
                  await Clipboard.setData(
                      ClipboardData(text: secret.thumbnailURI));
                  _scaffoldKey.currentState.showSnackBar(
                      SnackBar(content: Text('Copied the Thumbnail URL')));
                }),
            /*
            ListTile(
              title: CachedNetworkImage(
                fadeInDuration: Duration(),
                fadeOutDuration: Duration(),
                imageUrl: secret.thumbnailURI,
                placeholder: (context, url) => DefaultThumbnnail(),
                errorWidget: (context, url, error) => DefaultThumbnnail(),
              ),
            ),
            */
          ],
        ),
      ),
    );
  }
}