/*
 * Created by Ilan Rasekh on 2019/10/2
 * Copyright (c) 2019 Pseudorand Development. All rights reserved.
 */

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nullpass/models/secret.dart';
import 'package:nullpass/screens/secrets/secretView.dart';
import 'package:nullpass/services/datastore.dart';
import 'package:nullpass/services/logging.dart';
import 'package:nullpass/widgets.dart';

class SecretSearch extends StatefulWidget {
  const SecretSearch({super.key});

  @override
  _SecretSearchState createState() => _SecretSearchState();
}

class _SecretSearchState extends State<SecretSearch> {
  TextEditingController? _tec;
  String _searchText = '';
  List<Secret> _secrets = [];

  @override
  void initState() {
    super.initState();
    _searchText = '';
    // _tec = new TextEditingController(text: _searchText);
    _tec = TextEditingController();
    _secrets = <Secret>[];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _SearchField(_tec!, (value) async {
          setState(() {
            _searchText = value;
          });
          List<Secret> tempSecrets = <Secret>[];
          if ((value as String).trim().isNotEmpty) {
            NullPassDB npDB = NullPassDB.instance;
            tempSecrets = await npDB.findSecret(value) ?? <Secret>[];
          }
          setState(() {
            _secrets = tempSecrets;
          });
        }),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'Clear search',
            onPressed: () {
              Log.debug("clear");
              setState(() {
                _tec?.clear();
                _searchText = '';
                _secrets = [];
              });
            },
          ),
        ],
      ),
      body: _SecretListWidget(
          items: _secrets,
          reloadSecretList: (str) async {
            List<Secret> tempSecrets = <Secret>[];
            if ((_searchText).trim().isNotEmpty) {
              NullPassDB npDB = NullPassDB.instance;
              tempSecrets = await npDB.findSecret(_searchText) ?? <Secret>[];
            }
            setState(() {
              _secrets = tempSecrets;
              // _tec.text = value;
            });
          }),
    );
  }
}

class _SearchField extends StatelessWidget {
  final void Function(String) _onChanged;
  final TextEditingController _tec;

  const _SearchField(this._tec, this._onChanged);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return TextFormField(
      controller: _tec,
      onChanged: _onChanged,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Search secrets...',
        hintStyle: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        border: InputBorder.none,
        filled: false,
      ),
      cursorColor: colorScheme.primary,
      style: TextStyle(
        fontSize: 18,
        color: colorScheme.onSurface,
      ),
    );
  }
}

class _SecretListWidget extends StatelessWidget {
  final List<Secret> items;
  final void Function(String)? reloadSecretList;

  const _SecretListWidget({
    required this.items,
    required this.reloadSecretList,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No secrets found',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
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
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SecretView(secret: secret),
                ),
              );
              if (reloadSecretList != null) {
                reloadSecretList!('true');
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
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
