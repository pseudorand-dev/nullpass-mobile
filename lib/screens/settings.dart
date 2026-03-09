/*
 * Created by Ilan Rasekh on 2019/10/2
 * Copyright (c) 2019 Pseudorand Development. All rights reserved.
 */

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_app_lock/flutter_app_lock.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:nullpass/common.dart';
import 'package:nullpass/models/auditRecord.dart';
import 'package:nullpass/models/secret.dart';
import 'package:nullpass/models/vault.dart';
import 'package:nullpass/screens/appDrawer.dart';
import 'package:nullpass/services/datastore.dart';
import 'package:nullpass/setup.dart';

class Settings extends StatefulWidget {
  final Function(ThemeMode)? onThemeChanged;
  
  const Settings({super.key, this.onThemeChanged});

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final _title = 'Settings';
  int _secretLength = 512;
  int _passwordPreviewFontSize = 20;
  double _authTimeoutSeconds = 300;
  bool _authOnLoad = false;
  bool _alphaCharacters = true;
  bool _numericCharacters = true;
  bool _symbolCharacters = true;
  bool _inAppWebpages = true;
  bool _syncAccessNotifications = true;

  String _importText = '';

  @override
  void initState() {
    super.initState();

    bool spSet = sharedPrefs.getBool(SharedPrefSetupKey) ?? false;
    if (!spSet) setupSharedPreferences(encryptionKeyCallback: () {});

    _secretLength = sharedPrefs.getInt(SecretLengthPrefKey) ?? 512;
    _alphaCharacters = sharedPrefs.getBool(AlphaCharactersPrefKey) ?? true;
    _numericCharacters = sharedPrefs.getBool(NumericCharactersPrefKey) ?? true;
    _symbolCharacters = sharedPrefs.getBool(SymbolCharactersPrefKey) ?? true;
    _inAppWebpages = sharedPrefs.getBool(InAppWebpagesPrefKey) ?? true;
    _syncAccessNotifications =
        sharedPrefs.getBool(SyncdDataNotificationsPrefKey) ?? true;
    _passwordPreviewFontSize =
        sharedPrefs.getInt(PasswordPreviewSizePrefKey) ?? 20;

    // Auth Options
    _authOnLoad = ((sharedPrefs.containsKey(AuthOnLoadPrefKey))
            ? sharedPrefs.getBool(AuthOnLoadPrefKey)
            : false) ??
        false;
    _authTimeoutSeconds = ((sharedPrefs.containsKey(AuthTimeoutSecondsPrefKey))
            ? sharedPrefs.getDouble(AuthTimeoutSecondsPrefKey)
            : 300) ??
        300;
  }

  String doubleToString(double input) {
    var str = _authTimeoutSeconds.toString();

    if (str.endsWith(".0")) str = str.substring(0, str.indexOf(".0"));

    return str;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
      ),
      drawer: AppDrawer(
        currentPage: NullPassRoute.Settings,
        reloadSecretList: () {},
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _SectionHeader(
            title: 'Theme',
            icon: Icons.palette_outlined,
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.brightness_6,
                          size: 20,
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Theme Mode',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Choose your preferred theme',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Light'),
                          icon: Icon(Icons.light_mode, size: 18),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Dark'),
                          icon: Icon(Icons.dark_mode, size: 18),
                        ),
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('Auto'),
                          icon: Icon(Icons.brightness_auto, size: 18),
                        ),
                      ],
                      selected: {
                        ThemeMode.values.firstWhere(
                          (mode) =>
                              mode.toString() ==
                              'ThemeMode.${sharedPrefs.getString(ThemeModePrefKey) ?? 'system'}',
                          orElse: () => ThemeMode.system,
                        )
                      },
                      onSelectionChanged: (Set<ThemeMode> selected) {
                        final mode = selected.first;
                        sharedPrefs.setString(
                          ThemeModePrefKey,
                          mode.toString().split('.').last,
                        );
                        if (widget.onThemeChanged != null) {
                          widget.onThemeChanged!(mode);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'Default Password Generation',
            icon: Icons.password,
          ),
          Card(
            child: Column(
              children: [
                _SettingsTile(
                  title: 'Password Length',
                  subtitle: 'Default length: $_secretLength characters',
                  icon: Icons.straighten,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          if (_secretLength > 8) {
                            setState(() {
                              _secretLength--;
                              sharedPrefs.setInt(SecretLengthPrefKey, _secretLength);
                            });
                          }
                        },
                      ),
                      SizedBox(
                        width: 50,
                        child: Text(
                          _secretLength.toString(),
                          style: theme.textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () {
                          if (_secretLength < 128) {
                            setState(() {
                              _secretLength++;
                              sharedPrefs.setInt(SecretLengthPrefKey, _secretLength);
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: 72),
                SwitchListTile(
                  title: const Text('Include Letters'),
                  subtitle: const Text('A-Z, a-z'),
                  secondary: const Icon(Icons.abc),
                  value: _alphaCharacters,
                  onChanged: (value) async {
                    sharedPrefs.setBool(AlphaCharactersPrefKey, value);
                    setState(() {
                      _alphaCharacters = value;
                    });
                  },
                ),
                const Divider(height: 1, indent: 72),
                SwitchListTile(
                  title: const Text('Include Numbers'),
                  subtitle: const Text('0-9'),
                  secondary: const Icon(Icons.pin),
                  value: _numericCharacters,
                  onChanged: (value) async {
                    sharedPrefs.setBool(NumericCharactersPrefKey, value);
                    setState(() {
                      _numericCharacters = value;
                    });
                  },
                ),
                const Divider(height: 1, indent: 72),
                SwitchListTile(
                  title: const Text('Include Symbols'),
                  subtitle: const Text('!@#\$%^&*'),
                  secondary: const Icon(Icons.alternate_email),
                  value: _symbolCharacters,
                  onChanged: (value) async {
                    sharedPrefs.setBool(SymbolCharactersPrefKey, value);
                    setState(() {
                      _symbolCharacters = value;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'App Security',
            icon: Icons.security,
          ),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Lock Screen'),
                  subtitle: Text(
                    canCheckBiometrics
                        ? 'Require authentication on app launch'
                        : 'Biometric authentication not available',
                  ),
                  secondary: Icon(
                    canCheckBiometrics
                        ? Icons.fingerprint
                        : Icons.fingerprint_outlined,
                  ),
                  value: canCheckBiometrics && _authOnLoad,
                  onChanged: !canCheckBiometrics
                      ? null
                      : (value) {
                          sharedPrefs.setBool(AuthOnLoadPrefKey, value).then((worked) {
                            setState(() {
                              _authOnLoad = value;
                            });
                          });
                        },
                ),
                if (canCheckBiometrics) ...[
                  const Divider(height: 1, indent: 72),
                  _SettingsTile(
                    title: 'Background Timeout',
                    subtitle: 'Lock after ${_authTimeoutSeconds.toInt()} seconds',
                    icon: Icons.timer_outlined,
                    enabled: canCheckBiometrics,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: !canCheckBiometrics || _authTimeoutSeconds <= 30
                              ? null
                              : () {
                                  setState(() {
                                    _authTimeoutSeconds -= 30;
                                    sharedPrefs.setDouble(
                                      AuthTimeoutSecondsPrefKey,
                                      _authTimeoutSeconds,
                                    );
                                  });
                                },
                        ),
                        SizedBox(
                          width: 50,
                          child: Text(
                            canCheckBiometrics
                                ? '${_authTimeoutSeconds.toInt()}s'
                                : '--',
                            style: theme.textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: !canCheckBiometrics || _authTimeoutSeconds >= 3600
                              ? null
                              : () {
                                  setState(() {
                                    _authTimeoutSeconds += 30;
                                    sharedPrefs.setDouble(
                                      AuthTimeoutSecondsPrefKey,
                                      _authTimeoutSeconds,
                                    );
                                  });
                                },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'App Preferences',
            icon: Icons.tune,
          ),
          Card(
            child: Column(
              children: [
                _SettingsTile(
                  title: 'Password Preview Size',
                  subtitle: 'Font size: $_passwordPreviewFontSize',
                  icon: Icons.format_size,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: _passwordPreviewFontSize <= 12
                            ? null
                            : () {
                                setState(() {
                                  _passwordPreviewFontSize--;
                                  sharedPrefs.setInt(
                                    PasswordPreviewSizePrefKey,
                                    _passwordPreviewFontSize,
                                  );
                                });
                              },
                      ),
                      SizedBox(
                        width: 50,
                        child: Text(
                          _passwordPreviewFontSize.toString(),
                          style: theme.textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: _passwordPreviewFontSize >= 32
                            ? null
                            : () {
                                setState(() {
                                  _passwordPreviewFontSize++;
                                  sharedPrefs.setInt(
                                    PasswordPreviewSizePrefKey,
                                    _passwordPreviewFontSize,
                                  );
                                });
                              },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: 72),
                SwitchListTile(
                  title: const Text('Open Websites In-App'),
                  subtitle: const Text('Use in-app browser for websites'),
                  secondary: const Icon(Icons.web),
                  value: _inAppWebpages,
                  onChanged: (value) {
                    sharedPrefs.setBool(InAppWebpagesPrefKey, value).then((worked) {
                      setState(() {
                        _inAppWebpages = value;
                      });
                    });
                  },
                ),
                const Divider(height: 1, indent: 72),
                SwitchListTile(
                  title: const Text('Sync Notifications'),
                  subtitle: const Text('Get notified when synced secrets are accessed'),
                  secondary: const Icon(Icons.notifications_outlined),
                  value: _syncAccessNotifications,
                  onChanged: (value) {
                    sharedPrefs.setBool(SyncdDataNotificationsPrefKey, value).then((worked) {
                      setState(() {
                        _syncAccessNotifications = value;
                      });
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'Data Management',
            icon: Icons.storage,
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      FontAwesomeIcons.fileImport,
                      size: 20,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: const Text('Import Data'),
                  subtitle: const Text('Import secrets from JSON backup'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    showDialog<void>(
                      context: context,
                      // uncomment below to force user to tap button and not just tap outside the alert!
                      // barrierDismissible: false,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Import Data'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Text(
                                  'Paste a JSON blob containing a list of NullPass Secrets.'),
                              TextFormField(
                                maxLines: 10,
                                minLines: 1,
                                autofocus: true,
                                onChanged: (value) {
                                  setState(() {
                                    _importText = value;
                                  });
                                },
                              ),
                            ],
                          ),
                          actions: <Widget>[
                            TextButton(
                                child: const Text('Cancel'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                }),
                            TextButton(
                                child: const Text('Import'),
                                onPressed: () async {
                                  await importSecretsAndVaults(_importText);
                                  var v = await NullPassDB.instance
                                      .getDefaultVault();
                                  if (v != null) {
                                    sharedPrefs.setString(
                                        DefaultVaultIDPrefKey, v.uid);
                                  }
                                  Navigator.of(context).pop();
                                })
                          ],
                        );
                      },
                    );
                  },
                ),
                const Divider(height: 1, indent: 72),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      FontAwesomeIcons.fileExport,
                      size: 20,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: const Text('Export Data'),
                  subtitle: const Text('Backup all secrets to clipboard'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    showDialog<void>(
                      context: context,
                      // uncomment below to force user to tap button and not just tap outside the alert!
                      // barrierDismissible: false,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Export Data'),
                          content: const Text(
                              'This will export all of your password data. Be sure before proceeding as this will decrypt all data and copy it to your clipboard which can be available to many applications and services.'),
                          actions: <Widget>[
                            TextButton(
                                child: const Text('Cancel'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                }),
                            TextButton(
                                child: const Text('Export'),
                                onPressed: () async {
                                  await exportSecretsAndVaults();
                                  Navigator.of(context).pop();
                                })
                          ],
                        );
                      },
                    );
                  },
                ),
                const Divider(height: 1, indent: 72),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.add_circle_outline,
                      size: 24,
                      color: colorScheme.onTertiaryContainer,
                    ),
                  ),
                  title: const Text('Create Default Vault'),
                  subtitle: const Text('Initialize vault structure'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    var v = await NullPassDB.instance.createDefaultVault();
                    if (v != null) {
                      sharedPrefs.setString(DefaultVaultIDPrefKey, v.uid);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Default vault created')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            color: colorScheme.errorContainer,
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.error,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.delete_forever,
                  size: 24,
                  color: colorScheme.onError,
                ),
              ),
              title: Text(
                'Delete All Data',
                style: TextStyle(
                  color: colorScheme.onErrorContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Permanently delete all secrets and vaults',
                style: TextStyle(color: colorScheme.onErrorContainer),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: colorScheme.onErrorContainer,
              ),
              onTap: () async {
                    showDialog<void>(
                      context: context,
                      // uncomment below to force user to tap button and not just tap outside the alert!
                      // barrierDismissible: false,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Delete All Data'),
                          content: const Text(
                              'This will delete all password data. Be sure before proceeding as this is not undoable or recoverable.'),
                          actions: <Widget>[
                            TextButton(
                                child: const Text('Cancel'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                }),
                            TextButton(
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                                onPressed: () async {
                                  NullPassDB npDB = NullPassDB.instance;
                                  await npDB.deleteAllDevices();
                                  await npDB.deleteAllSyncs();
                                  await npDB.deleteAllSecrets();
                                  await npDB.deleteAllVaults();
                                  sharedPrefs.setString(
                                      DefaultVaultIDPrefKey, "");
                                  Navigator.of(context).pop();
                                })
                          ],
                        );
                      },
                    );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;
  final bool enabled;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      enabled: enabled,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: enabled
              ? colorScheme.secondaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled
              ? colorScheme.onSecondaryContainer
              : colorScheme.onSurfaceVariant.withOpacity(0.5),
        ),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing,
    );
  }
}

Future<void> exportSecretsAndVaults() async {
  // TODO: require re-authn (biometric validation) prior to allowing export of data
  NullPassDB npDB = NullPassDB.instance;
  List<Secret> secretsList = await npDB.getAllSecrets() ?? <Secret>[];
  List<Vault> vaultsList = await npDB.getAllVaults() ?? <Vault>[];

  Set<String> sids = <String>{};
  Set<String> vids = <String>{};

  List<Map<String, dynamic>> secretsJsonList = <Map<String, dynamic>>[];
  for (var s in secretsList) {
    secretsJsonList.add(s.toJson());
    sids.add(s.uuid);
  }

  List<Map<String, dynamic>> vaultsJsonList = <Map<String, dynamic>>[];
  for (var v in vaultsList) {
    vaultsJsonList.add(v.toJson());
    vids.add(v.uid);
  }

  await Clipboard.setData(ClipboardData(
    text: jsonEncode(<String, dynamic>{
      "secrets": secretsJsonList,
      "vaults": vaultsJsonList
    }),
  ));

  await NullPassDB.instance.addAuditRecord(AuditRecord(
    type: AuditType.AppDataExported,
    message: 'All Secret and Vault data was exported.',
    secretsReferenceId: sids,
    vaultsReferenceId: vids,
    date: DateTime.now().toUtc(),
  ));
}

Future<void> importSecretsAndVaults(String input) async {
  // TODO: require re-authn (biometric validation) prior to allowing import of data
  NullPassDB npDB = NullPassDB.instance;

  Map<String, dynamic> decodedInput = jsonDecode(input);
  // var secretsJsonList = decodedInput["secrets"];
  // var vaultsJsonList = decodedInput["vaults"];

  var secretsList = <Secret>[];
  var vaultsList = <Vault>[];

  Set<String> sids = <String>{};
  Set<String> vids = <String>{};

  for (var sMap in (decodedInput["secrets"] as List)) {
    var s = Secret.fromJson(sMap);
    secretsList.add(s);
    sids.add(s.uuid);
  }
  for (var vMap in (decodedInput["vaults"] as List)) {
    var v = Vault.fromMap(vMap);
    vaultsList.add(v);
    vids.add(v.uid);
  }

  // await npDB.bulkInsertSecrets(secretsListFromJsonString(input));
  await npDB.bulkInsertVaults(vaultsList);
  await npDB.bulkInsertSecrets(secretsList);
  await NullPassDB.instance.addAuditRecord(AuditRecord(
    type: AuditType.AppDataImported,
    message: 'Secret and Vault data was imported.',
    secretsReferenceId: sids,
    vaultsReferenceId: vids,
    date: DateTime.now().toUtc(),
  ));
}
