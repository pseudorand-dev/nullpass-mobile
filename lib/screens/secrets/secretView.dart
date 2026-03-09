/*
 * Created by Ilan Rasekh on 2019/10/2
 * Copyright (c) 2019 Pseudorand Development. All rights reserved.
 */

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nullpass/common.dart';
import 'package:nullpass/models/auditRecord.dart';
import 'package:nullpass/models/secret.dart';
import 'package:nullpass/models/vault.dart';
import 'package:nullpass/screens/secrets/secretEdit.dart';
import 'package:nullpass/services/datastore.dart';
import 'package:nullpass/services/logging.dart';
import 'package:nullpass/services/sync.dart';
import 'package:nullpass/widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';

class SecretView extends StatefulWidget {
  final Secret secret;

  const SecretView({super.key, required this.secret});

  @override
  _SecretViewState createState() => _SecretViewState();
}

class _SecretViewState extends State<SecretView> {
  // TODO: evaluate replacing this expensive scaffold key with a better more efficient method - examples https://medium.com/@ksheremet/flutter-showing-snackbar-within-the-widget-that-builds-a-scaffold-3a817635aeb2
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late Secret secret;
  bool _loading = true;
  late Map<String, Vault> selectedVaults;
  bool _editable = false;

  @override
  void initState() {
    super.initState();
    secret = widget.secret ??
        Secret(nickname: '', website: '', username: '', message: '');

    selectedVaults = <String, Vault>{};
    _getSecretsVault().then((vaultsList) {
      setState(() {
        _loading = false;
      });
    });
  }

  Future<void> _getSecretsVault() async {
    for (var vid in secret.vaults) {
      var v = await NullPassDB.instance.getVaultByID(vid);
      if (v != null) {
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
  }

  List<Widget> _generateChips(BuildContext context) {
    var widgetList = <Widget>[];
    final colorScheme = Theme.of(context).colorScheme;

    for (var vid in secret.vaults) {
      var vault = selectedVaults[vid];
      if (vault != null) {
        widgetList.add(Chip(
          label: Text(vault.nickname),
          backgroundColor: colorScheme.secondaryContainer,
          labelStyle: TextStyle(
            color: colorScheme.onSecondaryContainer,
            fontWeight: FontWeight.w500,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide.none,
          ),
        ));
      }
    }
    return widgetList;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    if (_loading) {
      return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(secret.nickname),
        ),
        body: const CenterLoader(),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(secret.nickname),
        actions: <Widget>[
          if (_editable)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SecretEdit(
                      edit: SecretEditType.Update,
                      secret: Secret(
                        nickname: secret.nickname,
                        website: secret.website,
                        username: secret.username,
                        message: secret.message,
                        otpCode: secret.otpCode,
                        notes: secret.notes,
                        thumbnailURI: secret.thumbnailURI,
                        vaults: secret.vaults,
                        tags: secret.tags,
                        uuid: secret.uuid,
                      ),
                    ),
                  ),
                );
                if (isTrue(result)) {
                  setState(() {
                    _loading = true;
                  });
                  Secret? s = await NullPassDB.instance.getSecretByID(secret.uuid);
                  if (s != null) {
                    setState(() {
                      secret = s;
                    });
                  }
                  await _getSecretsVault();
                  setState(() {
                    _loading = false;
                  });
                }
              },
            ),
          if (_editable)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                var deleted = await showDialog<bool>(
                      context: context,
                      // uncomment below to force user to tap button and not just tap outside the alert!
                      // barrierDismissible: false,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Delete Secret'),
                          content: Text(
                            'Are you sure you want to delete "${secret.nickname}"?\nPlease be sure before proceeding as you will not be able to undo this.',
                          ),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('Cancel'),
                              onPressed: () {
                                Navigator.of(context).pop(false);
                              },
                            ),
                            TextButton(
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                              onPressed: () async {
                                NullPassDB npDB = NullPassDB.instance;
                                bool success =
                                    await npDB.deleteSecret(secret.uuid);
                                await NullPassDB.instance
                                    .addAuditRecord(AuditRecord(
                                  type: AuditType.SecretDeleted,
                                  message:
                                      'The "${secret.nickname}" secret was deleted.',
                                  secretsReferenceId: <String>{secret.uuid},
                                  vaultsReferenceId: secret.vaults.toSet(),
                                  date: DateTime.now().toUtc(),
                                ));
                                if (success) {
                                  Sync.instance.sendSecretDeleted(secret);
                                }
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
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Hero(
            tag: 'secret-avatar-${secret.uuid}',
            child: Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                ),
                child: ClipOval(
                  child: CachedNetworkImage(
                    fit: BoxFit.cover,
                    imageUrl: secret.thumbnailURI ?? '',
                    placeholder: (context, url) => const DefaultThumbnnail(),
                    errorWidget: (context, url, error) => const DefaultThumbnnail(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SecretField(
                    label: 'Website',
                    value: secret.website ?? '',
                    icon: Icons.language,
                    onCopy: () async {
                      await Clipboard.setData(ClipboardData(text: secret.website ?? ''));
                      await NullPassDB.instance.addAuditRecord(AuditRecord(
                        type: AuditType.SecretUrlCopied,
                        message: 'The "${secret.nickname}" secret\'s website url was copied.',
                        secretsReferenceId: <String>{secret.uuid},
                        vaultsReferenceId: secret.vaults.toSet(),
                        date: DateTime.now().toUtc(),
                      ));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: const Text('Website copied')),
                        );
                      }
                    },
                    onAction: () async {
                      await NullPassDB.instance.addAuditRecord(AuditRecord(
                        type: AuditType.SecretUrlOpened,
                        message: 'The "${secret.nickname}" secret\'s website was launched.',
                        secretsReferenceId: <String>{secret.uuid},
                        vaultsReferenceId: secret.vaults.toSet(),
                        date: DateTime.now().toUtc(),
                      ));

                      bool openWebpagesInApp = sharedPrefs.getBool(InAppWebpagesPrefKey) ?? false;
                      var webpage = secret.website ?? '';
                      if (!webpage.startsWith('http') && !webpage.contains('://')) {
                        webpage = 'https://$webpage';
                      }
                      if (await canLaunch(webpage)) {
                        await Clipboard.setData(ClipboardData(text: secret.message ?? ''));
                        await launch(
                          webpage,
                          forceSafariVC: openWebpagesInApp,
                          forceWebView: openWebpagesInApp,
                          enableJavaScript: true,
                          enableDomStorage: true,
                        );
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Can\'t launch this website')),
                          );
                        }
                      }
                    },
                    actionIcon: Icons.launch,
                  ),
                  const Divider(height: 24),
                  _SecretField(
                    label: 'Username',
                    value: secret.username ?? '',
                    icon: Icons.person_outline,
                    onCopy: () async {
                      await Clipboard.setData(ClipboardData(text: secret.username ?? ''));
                      await NullPassDB.instance.addAuditRecord(AuditRecord(
                        type: AuditType.SecretUsernameCopied,
                        message: 'The "${secret.nickname}" secret\'s username was copied.',
                        secretsReferenceId: <String>{secret.uuid},
                        vaultsReferenceId: secret.vaults.toSet(),
                        date: DateTime.now().toUtc(),
                      ));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Username copied')),
                        );
                      }
                    },
                  ),
                  const Divider(height: 24),
                  _PasswordField(
                    secret: secret,
                    scaffoldKey: _scaffoldKey,
                  ),
                  const Divider(height: 24),
                  _PasswordStrengthField(secret: secret),
                  if (secret.getOnetimePasscode().isNotEmpty) ...[
                    const Divider(height: 24),
                    _OTPField(
                      otpCode: secret.otpCode ?? '',
                      nickname: secret.nickname,
                      uuid: secret.uuid,
                      vaults: secret.vaults,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (secret.notes?.isNotEmpty ?? false) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _SecretField(
                  label: 'Notes',
                  value: secret.notes ?? '',
                  icon: Icons.notes,
                  maxLines: null,
                  onCopy: () async {
                    await Clipboard.setData(ClipboardData(text: secret.notes ?? ''));
                    await NullPassDB.instance.addAuditRecord(AuditRecord(
                      type: AuditType.SecretNotesCopied,
                      message: 'The "${secret.nickname}" secret\'s notes was copied.',
                      secretsReferenceId: <String>{secret.uuid},
                      vaultsReferenceId: secret.vaults.toSet(),
                      date: DateTime.now().toUtc(),
                    ));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notes copied')),
                      );
                    }
                  },
                ),
              ),
            ),
          ],
          if (secret.vaults.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Vaults',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: _generateChips(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (isDebug) ...[
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.bug_report,
                    size: 20,
                    color: colorScheme.onTertiaryContainer,
                  ),
                ),
                title: const Text('Thumbnail URI'),
                subtitle: Text(secret.thumbnailURI ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () async {
                    await Clipboard.setData(
                        ClipboardData(text: secret.thumbnailURI ?? ''));
                    await NullPassDB.instance.addAuditRecord(AuditRecord(
                      type: AuditType.SecretUrlCopied,
                      message:
                          'The "${secret.nickname}" secret\'s thumbnail url was copied.',
                      secretsReferenceId: <String>{secret.uuid},
                      vaultsReferenceId: secret.vaults.toSet(),
                      date: DateTime.now().toUtc(),
                    ));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Thumbnail URL copied')));
                    }
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SecretPreview extends StatelessWidget {
  final String _secretText;
  Runes get _secretRunes => (_secretText.runes);
  List<TextSpan> _buildSecretSpans(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    List<TextSpan> sList = <TextSpan>[];
    
    for (var rune in _secretRunes) {
      var character = String.fromCharCode(rune);
      Color textColor;
      
      if (65 <= rune && rune <= 90) {
        // uppercase alpha - blue
        textColor = Colors.blue;
      } else if (97 <= rune && rune <= 122) {
        // lowercase alpha - green
        textColor = Colors.green;
      } else if (48 <= rune && rune <= 57) {
        // numbers - white/light gray in dark mode, black in light mode
        textColor = isDark ? Colors.grey.shade300 : Colors.black;
      } else {
        // symbols - orange
        textColor = Colors.orange;
      }

      sList.add(TextSpan(
        text: character,
        style: GoogleFonts.robotoMono(
          fontWeight: FontWeight.bold,
          color: textColor,
          fontSize: (sharedPrefs.getInt(PasswordPreviewSizePrefKey) ?? 14).toDouble(),
        ),
      ));
    }
    return sList;
  }

  const SecretPreview(
    this._secretText, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SelectableText.rich(
      TextSpan(
        children: _buildSecretSpans(context),
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _SecretField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onCopy;
  final VoidCallback? onAction;
  final IconData? actionIcon;
  final int? maxLines;

  const _SecretField({
    required this.label,
    required this.value,
    required this.icon,
    this.onCopy,
    this.onAction,
    this.actionIcon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                value.isEmpty ? 'Not set' : value,
                style: theme.textTheme.bodyLarge,
                maxLines: maxLines,
                overflow: maxLines == null ? null : TextOverflow.ellipsis,
              ),
            ),
            if (onCopy != null)
              IconButton(
                icon: const Icon(Icons.copy_outlined),
                onPressed: onCopy,
                tooltip: 'Copy',
              ),
            if (onAction != null)
              IconButton(
                icon: Icon(actionIcon ?? Icons.launch),
                onPressed: onAction,
                tooltip: 'Open',
              ),
          ],
        ),
      ],
    );
  }
}

class _PasswordField extends StatelessWidget {
  final Secret secret;
  final GlobalKey<ScaffoldState> scaffoldKey;

  const _PasswordField({
    required this.secret,
    required this.scaffoldKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lock_outline, size: 20, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              'Password',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onLongPress: () async {
                  await NullPassDB.instance.addAuditRecord(AuditRecord(
                    type: AuditType.SecretPasswordViewed,
                    message: 'The "${secret.nickname}" secret\'s password was viewed.',
                    secretsReferenceId: <String>{secret.uuid},
                    vaultsReferenceId: secret.vaults.toSet(),
                    date: DateTime.now().toUtc(),
                  ));
                  await Vibration.vibrate(duration: 50);
                  if (context.mounted) {
                    await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          content: SecretPreview(secret.message ?? ''),
                          contentPadding: const EdgeInsets.all(24),
                        );
                      },
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Long press to view',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.primary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy_outlined),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: secret.message ?? ''));
                await NullPassDB.instance.addAuditRecord(AuditRecord(
                  type: AuditType.SecretPasswordCopied,
                  message: 'The "${secret.nickname}" secret\'s password was copied.',
                  secretsReferenceId: <String>{secret.uuid},
                  vaultsReferenceId: secret.vaults.toSet(),
                  date: DateTime.now().toUtc(),
                ));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password copied')),
                  );
                }
              },
              tooltip: 'Copy password',
            ),
          ],
        ),
      ],
    );
  }
}

class _PasswordStrengthField extends StatelessWidget {
  final Secret secret;

  const _PasswordStrengthField({required this.secret});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final strength = secret.strength;
    final strengthColor = secret.strengthColor();

    String strengthText = 'Weak';
    double strengthValue = 0.33;
    Color barColor = Colors.red;
    
    if (strength >= 3) {
      strengthText = 'Strong';
      strengthValue = 1.0;
      barColor = Colors.green;
    } else if (strength >= 2) {
      strengthText = 'Fair';
      strengthValue = 0.66;
      barColor = Colors.orange;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.security, size: 20, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              'Password Strength',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: strengthValue,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                strengthText,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: barColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _OTPField extends StatefulWidget {
  final String otpCode;
  final String nickname;
  final String uuid;
  final List<String> vaults;

  const _OTPField({
    required this.otpCode,
    required this.nickname,
    required this.uuid,
    required this.vaults,
  });

  @override
  _OTPFieldState createState() => _OTPFieldState();
}

class _OTPFieldState extends State<_OTPField> {
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(
      const Duration(milliseconds: 500),
      (Timer t) {
        setState(() {});
      },
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final code = Secret.generateOnetimePasscode(widget.otpCode).trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.timer_outlined, size: 20, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              'One-Time Passcode',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                code,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy_outlined),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: code));
                await NullPassDB.instance.addAuditRecord(AuditRecord(
                  type: AuditType.SecretOTPCodeCopied,
                  message: 'The "${widget.nickname}" secret\'s one-time passcode was copied.',
                  secretsReferenceId: <String>{widget.uuid},
                  vaultsReferenceId: widget.vaults.toSet(),
                  date: DateTime.now().toUtc(),
                ));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('OTP copied')),
                  );
                }
              },
              tooltip: 'Copy',
            ),
          ],
        ),
      ],
    );
  }
}
