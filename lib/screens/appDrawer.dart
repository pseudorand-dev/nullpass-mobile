/*
 * Created by Ilan Rasekh on 2019/10/2
 * Copyright (c) 2019 Pseudorand Development. All rights reserved.
 */

import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:nullpass/models/secret.dart';
import 'package:nullpass/screens/app.dart';
import 'package:nullpass/screens/audit/auditLog.dart';
import 'package:nullpass/screens/devices/manageDevices.dart';
import 'package:nullpass/screens/devices/syncDevices.dart';
import 'package:nullpass/screens/secrets/secretEdit.dart';
import 'package:nullpass/screens/secrets/secretGenerate.dart';
import 'package:nullpass/screens/secrets/secretSearch.dart';
import 'package:nullpass/screens/settings.dart';
import 'package:nullpass/screens/vaults/manageVaults.dart';
import 'package:nullpass/widgets.dart';

enum NullPassRoute {
  ViewSecretsList,
  FindSecret,
  NewSecret,
  GenerateSecret,
  ManageVault,
  QrCode,
  QrScanner,
  ManageDevices,
  Settings,
  AuditLog,
  HelpAndFeedback
}

class AppDrawer extends StatelessWidget {
  final NullPassRoute currentPage;
  final Function reloadSecretList;

  const AppDrawer(
      {super.key, required this.currentPage, required this.reloadSecretList});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  colorScheme.secondary,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/null_iosScaledDown_1500_Transparent.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'NullPass',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Secure Password Manager',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          _DrawerItem(
            icon: Icons.auto_awesome_outlined,
            selectedIcon: Icons.auto_awesome,
            title: 'Generate Password',
            selected: currentPage == NullPassRoute.GenerateSecret,
            onTap: () async {
              Navigator.pop(context);
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (BuildContext context) {
                  return DraggableScrollableSheet(
                    initialChildSize: 0.7,
                    minChildSize: 0.5,
                    maxChildSize: 0.95,
                    builder: (_, controller) {
                      return Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 12),
                              width: 32,
                              height: 4,
                              decoration: BoxDecoration(
                                color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const Expanded(
                              child: SecretGenerate(inEditor: false),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
          _DrawerItem(
            icon: Icons.qr_code_outlined,
            selectedIcon: Icons.qr_code,
            title: 'Sync To This Device',
            selected: currentPage == NullPassRoute.QrCode,
            onTap: () {
              Navigator.pop(context);
              if (currentPage != NullPassRoute.QrCode) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SyncDevices(syncState: SyncState.qrcode),
                  ),
                );
              }
            },
          ),
          _DrawerItem(
            icon: Icons.qr_code_scanner_outlined,
            selectedIcon: Icons.qr_code_scanner,
            title: 'Sync To New Device',
            selected: currentPage == NullPassRoute.QrScanner,
            onTap: () {
              Navigator.pop(context);
              if (currentPage != NullPassRoute.QrScanner) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SyncDevices(syncState: SyncState.scan),
                  ),
                );
              }
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _DrawerItem(
            icon: Icons.history_outlined,
            selectedIcon: Icons.history,
            title: 'Audit Log',
            selected: currentPage == NullPassRoute.AuditLog,
            onTap: () {
              Navigator.pop(context);
              if (currentPage != NullPassRoute.AuditLog) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AuditLog()),
                );
              }
            },
          ),
          _DrawerItem(
            icon: Icons.help_outline,
            selectedIcon: Icons.help,
            title: 'Help & Feedback',
            selected: currentPage == NullPassRoute.HelpAndFeedback,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          _DrawerItem(
            icon: Icons.info_outline,
            selectedIcon: Icons.info,
            title: 'About',
            selected: false,
            onTap: () {
              Navigator.pop(context);
              showAboutDialog(
                context: context,
                applicationName: 'NullPass',
                applicationVersion: '0.1.0',
                applicationLegalese: 'Pseudorand Development',
                applicationIcon: SizedBox(
                  height: 50.0,
                  width: 50.0,
                  child: Image.asset(
                    'assets/images/null_iosScaledDown_1500_Transparent.png',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.selectedIcon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          selected ? selectedIcon : icon,
          color: selected
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: selected ? colorScheme.primary : colorScheme.onSurface,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: selected,
      selectedTileColor: colorScheme.primaryContainer.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
    );
  }
}
