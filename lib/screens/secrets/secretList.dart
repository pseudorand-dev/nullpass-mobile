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

  const SecretList({
    super.key,
    required this.items,
    required this.loading,
    required this.reloadSecretList,
  });

  @override
  Widget build(BuildContext context) {
    Widget bodyWidget;
    if (loading) {
      bodyWidget = _SecretLoading();
    } else if (items.isNotEmpty) {
      bodyWidget = SecretListWidget(
        items: items,
        reloadSecretList: reloadSecretList,
      );
    } else {
      bodyWidget = _SecretEmptyListView();
    }

    return _SecretListContainer(
      bodyWidget: bodyWidget,
      reloadSecretList: reloadSecretList,
    );
  }
}

class _SecretListContainer extends StatelessWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Widget bodyWidget;
  final Function reloadSecretList;
  static Size? screenSize;
  static Rect? screenRect;

  _SecretListContainer({
    required this.bodyWidget,
    required this.reloadSecretList,
  });

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
    return VisibilityDetector(
      key: _scaffoldKey,
      onVisibilityChanged: visibilityHasChanged,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Secrets'),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Search secrets',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SecretSearch()),
                );
                await reloadSecretList('true');
              },
            ),
          ],
        ),
        drawer: AppDrawer(
          currentPage: NullPassRoute.ViewSecretsList,
          reloadSecretList: reloadSecretList,
        ),
        body: bodyWidget,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SecretEdit(
                  edit: SecretEditType.Create,
                  secret: Secret(
                    nickname: '',
                    website: '',
                    username: '',
                    message: '',
                  ),
                ),
              ),
            );
            await reloadSecretList(result);
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Secret'),
        ),
      ),
    );
  }
}

class SecretListWidget extends StatelessWidget {
  final List<Secret> items;
  final Function reloadSecretList;

  const SecretListWidget({
    super.key,
    required this.items,
    required this.reloadSecretList,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final secret = items[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              await NullPassDB.instance.addAuditRecord(AuditRecord(
                type: AuditType.SecretViewed,
                message: 'The "${secret.nickname}" secret was viewed.',
                secretsReferenceId: <String>{secret.uuid},
                vaultsReferenceId: secret.vaults.toSet(),
                date: DateTime.now().toUtc(),
              ));
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SecretView(secret: secret),
                ),
              );
              await reloadSecretList('true');
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Hero(
                    tag: 'secret-avatar-${secret.uuid}',
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                      ),
                      child: ClipOval(
                        child: Thumbnail(secret.thumbnailURI),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          secret.nickname,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          secret.username.isEmpty ? secret.website ?? '' : secret.username,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SecretEmptyListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.lock_outline,
              size: 80,
              color: colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Secrets Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first secret to securely store your passwords and sensitive information',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                // This will be handled by the FAB
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Secret'),
            ),
          ],
        ),
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
    return CachedNetworkImage(
      fit: BoxFit.cover,
      width: 48,
      height: 48,
      imageUrl: _imageUrl,
      placeholder: (context, url) => const DefaultThumbnnail(),
      errorWidget: (context, url, error) => const DefaultThumbnnail(),
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 100),
    );
  }
}
