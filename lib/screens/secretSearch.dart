/*
 * Created by Ilan Rasekh on 2019/10/2
 * Copyright (c) 2019 Pseudorand Development. All rights reserved.
 */

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nullpass/screens/secretView.dart';
import 'package:nullpass/secret.dart';
import 'package:nullpass/services/logging.dart';
import 'package:nullpass/widgets.dart';

class SecretSearch extends StatefulWidget {
  _SecretSearchState createState() => _SecretSearchState();
}

class _SecretSearchState extends State<SecretSearch> {
  TextEditingController _tec;
  String _searchText;
  List<Secret> _secrets;

  @override
  void initState() {
    super.initState();
    _searchText = '';
    // _tec = new TextEditingController(text: _searchText);
    _tec = new TextEditingController();
    _secrets = <Secret>[];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: // _searchField(_searchText, (value) {
            _searchField(_tec, (value) async {
          setState(() {
            _searchText = value;
            // _tec.text = value;
          });
          List<Secret> tempSecrets = <Secret>[];
          if ((value as String).trim().isNotEmpty) {
            NullPassDB npDB = NullPassDB.instance;
            tempSecrets = await npDB.find(value);
          }
          setState(() {
            _secrets = tempSecrets;
            // _tec.text = value;
          });
        }),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: () {
              Log.debug("clear");
              setState(() {
                _tec.clear();
                // _searchText = '';
              });
            },
            // onPressed: () async {
            //   await Navigator.push(
            //     context,
            //     MaterialPageRoute(
            //         builder: (context) => SecretSearch()),
            //   );
            //   await this.reloadSecretList('true');
            // }
          ),
        ],
      ),
      body: _SecretListWidget(
          items: _secrets,
          reloadSecretList: (str) async {
            List<Secret> tempSecrets = <Secret>[];
            if ((_searchText as String).trim().isNotEmpty) {
              NullPassDB npDB = NullPassDB.instance;
              tempSecrets = await npDB.find(_searchText);
            }
            setState(() {
              _secrets = tempSecrets;
              // _tec.text = value;
            });
          }),
    );
  }
}

class _searchField extends StatelessWidget {
  Function _onChanged;
  // String _searchText;
  TextEditingController _tec;

  // _searchField(this._searchText, this._onChanged, {Key key}) : super(key: key);
  _searchField(this._tec, this._onChanged, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      // decoration: InputDecoration(fillColor: Colors.white),
      controller: _tec,
      // initialValue: _searchText,
      onChanged: _onChanged,
      autofocus: true,
      decoration: InputDecoration(border: InputBorder.none),
      cursorColor: Colors.white,
      style: TextStyle(fontSize: 25, color: Colors.white),
    );
  }
}

class _SecretListWidget extends StatelessWidget {
  final List<Secret> items;
  final Function reloadSecretList;

  _SecretListWidget(
      {Key key, @required this.items, @required this.reloadSecretList})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: items != null ? items.length : 0,
      itemBuilder: (context, index) {
        return ListTile(
          leading: Thumbnail(items[index].thumbnailURI),
          title: Text(items[index].nickname),
          subtitle: Text(items[index].username),
          trailing: Icon(Icons.arrow_forward_ios),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => SecretView(secret: items[index])),
            );
            await this.reloadSecretList('true');
          },
        );
      },
    );
  }
}

class Thumbnail extends StatelessWidget {
  final String _imageUrl;

  Thumbnail(this._imageUrl, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25.0),
      child: CachedNetworkImage(
        fit: BoxFit.cover,
        width: 40,
        height: 40,
        imageUrl: _imageUrl,
        placeholder: (context, url) => DefaultThumbnnail(),
        errorWidget: (context, url, error) => DefaultThumbnnail(),
        fadeInDuration: Duration(),
        fadeOutDuration: Duration(),
      ),
    );
  }
}
