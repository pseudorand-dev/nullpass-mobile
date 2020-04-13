/*
 * Created by Ilan Rasekh on 2019/10/2
 * Copyright (c) 2019 Pseudorand Development. All rights reserved.
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nullpass/common.dart';
import 'package:nullpass/models/secret.dart';
import 'package:nullpass/models/vault.dart';
import 'package:nullpass/screens/secrets/secretEdit.dart';
import 'package:nullpass/services/datastore.dart';
import 'package:nullpass/services/logging.dart';
import 'package:nullpass/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class SecretView extends StatefulWidget {
  final Secret secret;

  SecretView({Key key, @required this.secret}) : super(key: key);

  @override
  _SecretViewState createState() => _SecretViewState();
}

class _SecretViewState extends State<SecretView> {
  // TODO: evaluate replacing this expensive scaffold key with a better more efficient method - examples https://medium.com/@ksheremet/flutter-showing-snackbar-within-the-widget-that-builds-a-scaffold-3a817635aeb2
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  Secret secret;
  bool _loading = true;
  Map<String, Vault> selectedVaults;
  bool _editable = false;

  @override
  void initState() {
    super.initState();
    this.secret = this.widget.secret ??
        Secret(nickname: '', website: '', username: '', message: '');

    selectedVaults = <String, Vault>{};
    _getSecretsVault().then((vaultsList) {
      setState(() {
        _loading = false;
      });
    });
  }

  Future<void> _getSecretsVault() async {
    for (var vid in this.secret.vaults) {
      var v = await NullPassDB.instance.getVaultByID(vid);
      selectedVaults[vid] = v;

      // FIXME: need a better way to determine if editing is allowed on a secret
      // If the secret is in any vaults that are managed internally than It can be edited
      if (v.manager == VaultManager.Internal) {
        setState(() {
          _editable = true;
        });
      }
    }
  }

  List<Widget> _generateChips(BuildContext context) {
    var widgetList = <Widget>[];

    this.secret.vaults.forEach((vid) {
      widgetList.add(NullPassFilterChip(
        label: this.selectedVaults[vid].nickname,
        isSelected: true,
        onSelected: (isSelected) {},
      ));
    });
    return widgetList;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(secret.nickname),
        ),
        body: CenterLoader(),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(secret.nickname),
        actions: <Widget>[
          if (_editable)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () async {
                var deleted = await showDialog<bool>(
                      context: context,
                      // uncomment below to force user to tap button and not just tap outside the alert!
                      // barrierDismissible: false,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Delete Secret'),
                          content: Text(
                            'Are you sure you want to delete "${this.secret.nickname}"?\nPlease be sure before proceeding as you will not be able to undo this.',
                          ),
                          actions: <Widget>[
                            FlatButton(
                              child: Text('Cancel'),
                              onPressed: () {
                                Navigator.of(context).pop(false);
                              },
                            ),
                            FlatButton(
                              child: Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                              onPressed: () async {
                                NullPassDB npDB = NullPassDB.instance;
                                bool success =
                                    await npDB.deleteSecret(secret.uuid);
                                Log.debug(success.toString());
                                Navigator.of(context).pop(true);
                              },
                            ),
                          ],
                        );
                      },
                    ) ??
                    false;
                if (deleted) {
                  Navigator.pop(context, 'true');
                }
              },
            ),
          if (_editable)
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
                          vaults: secret.vaults,
                          tags: secret.tags,
                          uuid: secret.uuid),
                    ),
                  ),
                );
                if (isTrue(result)) {
                  setState(() {
                    _loading = true;
                  });
                  Secret s =
                      await NullPassDB.instance.getSecretByID(secret.uuid);
                  setState(() {
                    secret = s;
                  });
                  await _getSecretsVault();
                  setState(() {
                    _loading = false;
                  });
                }
              },
            ),
        ],
      ),
      body: Center(
        child: ListView(
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
                  await Clipboard.setData(ClipboardData(text: secret.website));
                  showSnackBar(_scaffoldKey, 'Website Copied');
                }),
            ListTile(
              title: Text('Username'),
              subtitle: Text(secret.username ?? ''),
              trailing: IconButton(
                  icon: Icon(Icons.content_copy),
                  onPressed: () async {
                    await Clipboard.setData(
                        ClipboardData(text: secret.username));
                    showSnackBar(_scaffoldKey, 'Username Copied');
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
                    showSnackBar(_scaffoldKey, 'Password Copied');
                  }),
              onLongPress: () async {
                await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return SimpleDialog(
                        children: <Widget>[
                          Center(
                            child: SecretPreview(secret.message),
                          ),
                        ],
                      );
                    });
              },
            ),
            ListTile(
              title: Text('Password Difficulty'),
              trailing: IconButton(
                  icon: Icon(Icons.stars, color: secret.strengthColor()),
                  onPressed: () {}),
              onLongPress: () {},
            ),
            ListTile(
              title: Text('Notes'),
              subtitle: Text(secret.notes ?? ''),
              trailing: IconButton(
                  icon: Icon(Icons.content_copy),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: secret.notes));
                    showSnackBar(_scaffoldKey, 'Notes Copied');
                  }),
            ),
            ListTile(
              contentPadding: EdgeInsets.fromLTRB(15, 15, 15, 0),
              title: Text(
                "Vaults",
                style: TextStyle(
                  color: Colors.grey[600],
                  // fontSize: 12.5,
                ),
              ),
              subtitle: Wrap(
                children: _generateChips(context),
                spacing: 5.0,
                runSpacing: 5.0,
              ),
            ),
            if (isDebug)
              ListTile(
                title: Text('Thumbnail'),
                subtitle: Text(secret.thumbnailURI ?? ''),
                onLongPress: () async {
                  await Clipboard.setData(
                      ClipboardData(text: secret.thumbnailURI));
                  _scaffoldKey.currentState.showSnackBar(
                      SnackBar(content: Text('Copied the Thumbnail URL')));
                },
              ),
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

class SecretPreview extends StatelessWidget {
  final String _secretText;
  Runes get _secretRunes => (this._secretText.runes);
  List<TextSpan> get secretSpan {
    List<TextSpan> sList = <TextSpan>[];
    _secretRunes.forEach((int rune) {
      var character = new String.fromCharCode(rune);
      var textColor = Colors.black;
      if (65 <= rune && rune <= 90) {
        // uppercase alpha
        textColor = Colors.blue;
      } else if (97 <= rune && rune <= 122) {
        // lowercase alpha
        textColor = Colors.green;
      } else if (!(48 <= rune && rune <= 57)) {
        // Not a number i.e. a symbol
        textColor = Colors.orange;
      }

      sList.add(new TextSpan(
        text: character,
        style: TextStyle(
            fontWeight: FontWeight.bold, color: textColor, fontSize: 20),
      ));
    });
    return sList;
  }

  SecretPreview(
    this._secretText, {
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SelectableText.rich(
      TextSpan(
        children: secretSpan,
      ),
      textAlign: TextAlign.center,
    );
  }
}
