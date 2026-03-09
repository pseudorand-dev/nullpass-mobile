/*
 * Created by Ilan Rasekh on 2019/9/27
 * Copyright (c) 2019 Pseudorand Development. All rights reserved.
 */

import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:nullpass/common.dart';
import 'package:nullpass/models/secret.dart';
import 'package:nullpass/screens/secrets/secretList.dart';
import 'package:nullpass/screens/settings.dart';
import 'package:nullpass/screens/devices/manageDevices.dart';
import 'package:nullpass/screens/vaults/manageVaults.dart';
import 'package:nullpass/services/datastore.dart';
import 'package:nullpass/services/logging.dart';
import 'package:nullpass/setup.dart';

class NullPassApp extends StatefulWidget {
  final Function(ThemeMode)? onThemeChanged;
  
  const NullPassApp({super.key, this.onThemeChanged});

  @override
  _NullPassAppState createState() => _NullPassAppState();
}

class _NullPassAppState extends State<NullPassApp> {
  List<Secret> _secrets = <Secret>[];
  bool _loading = true;
  static bool _completeSecretsPull = false;
  static bool _completeEncryptionKeyGeneration = false;
  int _selectedIndex = 0;

  Future<void> encryptionKeyCallback() async {
    _completeEncryptionKeyGeneration =
        sharedPrefs.getBool(EncryptionKeyPairSetupPrefKey) ?? false;
    if (_completeEncryptionKeyGeneration && _completeSecretsPull) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> secretsPullCallback(List<Secret>? result) async {
    _secrets = result ?? <Secret>[];
    _completeSecretsPull = true;
    if (_completeEncryptionKeyGeneration && _completeSecretsPull) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    if (isDebug) {
      Log.debug('debug on');
    }

    setupNotifications().then((_) {
      Log.debug('OneSignal Setup');
    });

    encryptionKeyCallback();
  
    NullPassDB helper = NullPassDB.instance;

    helper.getAllSecrets().then(secretsPullCallback);
  }

  void _reloadSecretList(result) async {
    if (isTrue(result)) {
      NullPassDB npDB = NullPassDB.instance;
      List<Secret>? sList = await npDB.getAllSecrets();
      setState(() {
        _secrets = sList ?? <Secret>[];
      });
    }
  }

  void _onNavigationItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildPage() {
    switch (_selectedIndex) {
      case 0:
        return SecretList(
          loading: _loading,
          items: _secrets,
          reloadSecretList: _reloadSecretList,
        );
      case 1:
        return const ManageVault();
      case 2:
        return const ManageDevices();
      case 3:
        return Settings(onThemeChanged: widget.onThemeChanged);
      default:
        return SecretList(
          loading: _loading,
          items: _secrets,
          reloadSecretList: _reloadSecretList,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth >= 600;
        
        return Scaffold(
          body: Row(
            children: [
              if (isLargeScreen)
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onNavigationItemTapped,
                  labelType: NavigationRailLabelType.selected,
                  destinations: [
                    NavigationRailDestination(
                      icon: const Icon(Icons.lock_outline),
                      selectedIcon: const Icon(Icons.lock),
                      label: const Text('Secrets'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(MdiIcons.safeSquareOutline),
                      selectedIcon: Icon(MdiIcons.safeSquare),
                      label: const Text('Vaults'),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.devices_outlined),
                      selectedIcon: const Icon(Icons.devices),
                      label: const Text('Devices'),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.settings_outlined),
                      selectedIcon: const Icon(Icons.settings),
                      label: const Text('Settings'),
                    ),
                  ],
                ),
              Expanded(
                child: _buildPage(),
              ),
            ],
          ),
          bottomNavigationBar: isLargeScreen ? null : NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onNavigationItemTapped,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.lock_outline),
                selectedIcon: const Icon(Icons.lock),
                label: 'Secrets',
              ),
              NavigationDestination(
                icon: Icon(MdiIcons.safeSquareOutline),
                selectedIcon: Icon(MdiIcons.safeSquare),
                label: 'Vaults',
              ),
              NavigationDestination(
                icon: const Icon(Icons.devices_outlined),
                selectedIcon: const Icon(Icons.devices),
                label: 'Devices',
              ),
              NavigationDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }
}
