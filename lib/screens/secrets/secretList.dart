/*
 * Created by Ilan Rasekh on 2019/10/2
 * Copyright (c) 2019 Pseudorand Development. All rights reserved.
 */

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nullpass/models/auditRecord.dart';
import 'package:nullpass/models/secret.dart';
import 'package:nullpass/screens/appDrawer.dart';
import 'package:nullpass/screens/secrets/secretEdit.dart';
import 'package:nullpass/screens/secrets/secretSearch.dart';
import 'package:nullpass/screens/secrets/secretView.dart';
import 'package:nullpass/services/datastore.dart';
import 'package:nullpass/widgets.dart';
import 'package:visibility_detector/visibility_detector.dart';

class SecretList extends StatelessWidget {
  final List<Secret> items;
  final bool loading;
  final Function reloadSecretList;

  const SecretList(
      {super.key,
      required this.items,
      required this.loading,
      required this.reloadSecretList});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return _SecretListContainer(
          bodyWidget: _SecretLoading(), reloadSecretList: (dynamic d) {});
    } else if (items.isNotEmpty) {
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Widget bodyWidget;
  final Function reloadSecretList;
  static Size? screenSize;
  static Rect? screenRect;

  _SecretListContainer(
      {required this.bodyWidget, required this.reloadSecretList});

  void visibilityHasChanged(VisibilityInfo info) {
    if (info.size != Size.zero &&
        info.size != screenSize &&
        info.visibleBounds != Rect.zero &&
        info.visibleBounds != screenRect) {
      reloadSecretList('true');
    }
    screenSize ??= info.size;
    screenRect ??= info.visibleBounds;
  }

  @override
  Widget build(BuildContext context) {
    const title = 'NullPass';

    return VisibilityDetector(
      key: _scaffoldKey,
      onVisibilityChanged: visibilityHasChanged,
      child: MaterialApp(
        title: title,
        home: Scaffold(
          appBar: AppBar(
            title: const Text(title),
            actions: <Widget>[
              IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SecretSearch()),
                    );
                    await reloadSecretList('true');
                  }),
            ],
          ),
          drawer: AppDrawer(
              currentPage: NullPassRoute.ViewSecretsList,
              reloadSecretList: reloadSecretList),
          body: bodyWidget,
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      // builder: (context) => SecretEdit(edit: SecretEditType.Create, // SecretNew(
                      builder: (context) => SecretEdit(
                          edit: SecretEditType.Create, // SecretNew(
                          secret: Secret(
                            nickname: '',
                            website: '',
                            username: '',
                            message: '',
                          ))));
              await reloadSecretList(result);
            },
            tooltip: 'Increment',
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}

class SecretListWidget extends StatelessWidget {
  final List<Secret> items;
  final Function reloadSecretList;

  const SecretListWidget(
      {super.key, required this.items, required this.reloadSecretList});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: Thumbnail(items[index].thumbnailURI),
          title: Text(items[index].nickname),
          subtitle: Text(items[index].username),
          trailing: const Icon(Icons.arrow_forward_ios),
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
                  builder: (context) => SecretView(secret: items[index])),
            );
            await reloadSecretList('true');
          },
        );
      },
    );
  }
}

class _SecretEmptyListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[CircularProgressIndicator()],
      ),
    );
  }
}

class Thumbnail extends StatelessWidget {
  final String _imageUrl;

  const Thumbnail(this._imageUrl, {super.key});

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
        placeholder: (context, url) => const DefaultThumbnnail(),
        errorWidget: (context, url, error) => const DefaultThumbnnail(),
        fadeInDuration: const Duration(),
        fadeOutDuration: const Duration(),
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
