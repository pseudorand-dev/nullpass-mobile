/*
 * Created by Ilan Rasekh on 2019/10/2
 * Copyright (c) 2019 Pseudorand Development. All rights reserved.
 */

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nullpass/common.dart';
import 'package:nullpass/screens/appDrawer.dart';
import 'package:nullpass/screens/secretEdit.dart';
import 'package:nullpass/screens/secretSearch.dart';
import 'package:nullpass/screens/secretView.dart';
import 'package:nullpass/secret.dart';
import 'package:nullpass/widgets.dart';

class SecretList extends StatelessWidget {
  final List<Secret> items;
  bool loading = true;
  final Function reloadSecretList;

  SecretList(
      {Key key,
      @required this.items,
      @required this.loading,
      @required this.reloadSecretList})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return _SecretListContainer(
          bodyWidget: _SecretLoading(), reloadSecretList: () {});
    } else if (items != null && items.length > 0) {
      return _SecretListContainer(
          bodyWidget: SecretListWidget(
              items: items, reloadSecretList: reloadSecretList),
          reloadSecretList: reloadSecretList);
    } else {
      return _SecretListContainer(
          bodyWidget: _SecretEmptyListView(),
          reloadSecretList: reloadSecretList);
    }
  }
}

class _SecretListContainer extends StatelessWidget {
  final Widget bodyWidget;
  final Function reloadSecretList;

  _SecretListContainer(
      {Key key, @required this.bodyWidget, @required this.reloadSecretList})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final title = 'NullPass';

    return MaterialApp(
      title: title,
      home: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: <Widget>[
            IconButton(
                icon: Icon(Icons.search),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SecretSearch()),
                  );
                  await this.reloadSecretList('true');
                }),
          ],
        ),
        drawer: AppDrawer(currentPage: NullPassRoute.ViewSecretsList),
        body: bodyWidget,
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(
                context,
                MaterialPageRoute(
                    // builder: (context) => SecretEdit(edit: SecretEditType.Create, // SecretNew(
                    builder: (context) => SecretEdit(
                        edit: SecretEditType.Create, // SecretNew(
                        secret: new Secret(
                          nickname: '',
                          website: '',
                          username: '',
                          message: '',
                        ))));
            await this.reloadSecretList(result);
          },
          tooltip: 'Increment',
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}

class SecretListWidget extends StatelessWidget {
  final List<Secret> items;
  final Function reloadSecretList;

  SecretListWidget(
      {Key key, @required this.items, @required this.reloadSecretList})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: items.length,
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

class _SecretEmptyListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'There are no secrets - create one now',
          ),
        ],
      ),
    );
  }
}

class _SecretLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[CircularProgressIndicator()],
      ),
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

      ///*
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
      //*/
      /*
      child: FadeInImage.assetNetwork(
        placeholder: 'assets/images/null_iosScaledDown_1500_Transparent.png',
        // image: _imageUrl,
        image: 'http://pluspng.com/img-png/google-logo-png-open-2000.png',
        fit: BoxFit.cover,
        width: 40,
        height: 40,
        fadeInDuration: Duration(),
        fadeOutDuration: Duration(),
      ),
      */
    );
  }
}
