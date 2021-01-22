/*
 * Created by Ilan Rasekh on 2019/10/2
 * Copyright (c) 2019 Pseudorand Development. All rights reserved.
 */

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widgets/flutter_widgets.dart';
import 'package:nullpass/common.dart';
import 'package:nullpass/models/auditRecord.dart';
import 'package:nullpass/models/secret.dart';
import 'package:nullpass/screens/appDrawer.dart';
import 'package:nullpass/screens/secrets/secretEdit.dart';
import 'package:nullpass/screens/secrets/secretSearch.dart';
import 'package:nullpass/screens/secrets/secretView.dart';
import 'package:nullpass/services/datastore.dart';
import 'package:nullpass/widgets.dart';
import 'package:provider/provider.dart';

class SecretSet with ChangeNotifier {
  List<Secret> data;
  String vaultId;

  SecretChangeNotifier _secretEventListener;

  SecretSet({List<Secret> data, String vaultId}) {
    this.data = data ?? <Secret>[];
    this.vaultId = vaultId;
    _secretEventListener = NullPassDB.instance.secretEvents;
    _secretEventListener.addListener(_update);
    _update();
  }

  void _update() async {
    var tmpSecretList = <Secret>[];
    if (vaultId == null) {
      tmpSecretList = await NullPassDB.instance.getAllSecrets();
    } else {
      tmpSecretList = await NullPassDB.instance.getAllSecretsInVault(vaultId);
    }
    data = tmpSecretList ?? <Secret>[];
    notifyListeners();
  }
}

class SecretList extends StatelessWidget {
  final bool loading;

  SecretList({Key key, @required this.loading}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Provider.of<SecretSet>(context, listen: false);

    if (loading) {
      return _SecretListContainer(
        bodyWidget: _SecretLoading(),
      );
    }
    return _SecretListContainer(
      bodyWidget: Consumer<SecretSet>(
        builder: (context, secretSet, child) => SecretListWidget(
          items: secretSet.data,
        ),
      ),
    );
  }
}

class _SecretListContainer extends StatelessWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final Widget bodyWidget;
  static Size screenSize;
  static Rect screenRect;

  _SecretListContainer({Key key, @required this.bodyWidget}) : super(key: key);

  void visibilityHasChanged(VisibilityInfo info) {
    if (screenSize == null) screenSize = info.size;
    if (screenRect == null) screenRect = info.visibleBounds;
  }

  @override
  Widget build(BuildContext context) {
    final title = 'NullPass';

    return VisibilityDetector(
      key: _scaffoldKey,
      onVisibilityChanged: visibilityHasChanged,
      child: MaterialApp(
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
                  }),
            ],
          ),
          drawer: AppDrawer(
            currentPage: NullPassRoute.ViewSecretsList,
          ),
          body: bodyWidget,
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SecretEdit(
                    edit: SecretEditType.Create,
                    secret: new Secret(
                      nickname: '',
                      website: '',
                      username: '',
                      message: '',
                    ),
                  ),
                ),
              );
            },
            tooltip: 'Increment',
            child: Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}

class SecretListWidget extends StatelessWidget {
  final List<Secret> items;

  SecretListWidget({Key key, @required this.items}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (items == null || items.length < 1) {
      return _SecretEmptyListView();
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: Thumbnail(items[index].thumbnailURI),
          title: Text(items[index].nickname),
          subtitle: Text(items[index].username),
          trailing: Icon(Icons.arrow_forward_ios),
          onTap: () async {
            await NullPassDB.instance.addAuditRecord(AuditRecord(
              type: AuditType.SecretViewed,
              message: 'The "${items[index].nickname}" secret was viewed.',
              secretsReferenceId: <String>{items[index].uuid},
              vaultsReferenceId: items[index].vaults.toSet(),
              date: DateTime.now().toUtc(),
            ));
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SecretView(secret: items[index]),
              ),
            );
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
