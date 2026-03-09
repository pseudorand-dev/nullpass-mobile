/*
 * Created by Ilan Rasekh on 2019/10/2
 * Copyright (c) 2019 Pseudorand Development. All rights reserved.
 */

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:nullpass/common.dart';
import 'package:nullpass/models/auditRecord.dart';
import 'package:nullpass/models/secret.dart';
import 'package:nullpass/models/vault.dart';
import 'package:nullpass/screens/secrets/secretGenerate.dart';
import 'package:nullpass/services/datastore.dart';
import 'package:nullpass/services/logging.dart';
import 'package:nullpass/services/sync.dart';
import 'package:nullpass/widgets.dart';
import 'package:uuid/uuid.dart';
import 'package:validators/validators.dart';

enum SecretEditType { Create, Update }

class SecretEdit extends StatefulWidget {
  final Secret secret;
  final SecretEditType edit;

  const SecretEdit({super.key, required this.secret, required this.edit});

  @override
  _CreateSecretState createState() => _CreateSecretState();
}

class _CreateSecretState extends State<SecretEdit> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late Secret _secret;
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = true;
  late Map<String, Vault> vaults;
  late Map<String, bool> selectedVaults;
  String? defaultVault;
  String? newVaultName;

  // Submit sends the new password data to the db to be saved then pop's up one level
  void submit(BuildContext context) async {
    // First validate form.
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save(); // Save our form now.

      // SAVE
      if (!isUUID(_secret.uuid.trim(), '4')) {
        _secret.uuid = (const Uuid()).v4();
      }
      _secret.vaults = [];
      selectedVaults.forEach((f, val) {
        if (val) _secret.vaults.add(f);
      });

      NullPassDB helper = NullPassDB.instance;
      bool success = false;
      if (widget.edit == SecretEditType.Create) {
        var now = DateTime.now().toUtc();
        _secret.created = now;
        _secret.lastModified = now;
        success = await helper.insertSecret(_secret);
        Log.debug('inserted row(s) - $success');
        // await showSnackBar(context, 'Created!');

        if (success) {
          await NullPassDB.instance.addAuditRecord(AuditRecord(
            type: AuditType.SecretCreated,
            message: 'The "${_secret.nickname}" secret was created.',
            secretsReferenceId: <String>{_secret.uuid},
            vaultsReferenceId: _secret.vaults.toSet(),
            date: _secret.created,
          ));

          // Sync changes to appropriate parties
          Sync.instance.sendSecretAdded(_secret);
        }
      } else if (widget.edit == SecretEditType.Update) {
        _secret.lastModified = DateTime.now().toUtc();
        success = await helper.updateSecret(_secret);
        Log.debug('updated row(s) - $success');
        // await showSnackBar(context, 'Updated!');

        if (success) {
          await NullPassDB.instance.addAuditRecord(AuditRecord(
            type: AuditType.SecretUpdated,
            message: 'The "${_secret.nickname}" secret was updated.',
            secretsReferenceId: <String>{_secret.uuid},
            vaultsReferenceId: _secret.vaults.toSet(),
            date: _secret.lastModified,
          ));

          // Sync changes to appropriate parties
          Sync.instance.sendSecretUpdated(_secret);
        }
      }

      Navigator.pop(context, 'true');
    }
  }

  @override
  void initState() {
    super.initState();
    _secret = widget.secret;

    vaults = <String, Vault>{};
    selectedVaults = <String, bool>{};

    // _secret.vaults.forEach((v) => )

    defaultVault = sharedPrefs.getString(DefaultVaultIDPrefKey) ?? "";

    NullPassDB.instance.getAllInternallyManagedVaults().then((vaultsList) {
      for (var v in vaultsList) {
        vaults[v.uid] = v;
        selectedVaults[v.uid] =
            (((_secret.vaults.isEmpty) &&
                    v.uid == defaultVault) ||
                _secret.vaults.contains(v.uid));
      }
      setState(() {
        _loading = false;
      });
    });
  }

  void setPassword(String value) {
    setState(() {
      _secret.message = value;
    });
    _passwordController.text = value;
  }

  List<Widget> _generateChips(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    var widgetList = <Widget>[];

    vaults.forEach((uid, vault) {
      final isSelected = selectedVaults[uid] ?? false;
      widgetList.add(FilterChip(
        label: Text(vault.nickname),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            selectedVaults[uid] = selected;
          });
        },
        selectedColor: colorScheme.secondaryContainer,
        checkmarkColor: colorScheme.onSecondaryContainer,
        labelStyle: TextStyle(
          color: isSelected
              ? colorScheme.onSecondaryContainer
              : colorScheme.onSurface,
        ),
      ));
    });

    widgetList.add(ActionChip(
      label: const Text('Add Vault'),
      avatar: Icon(
        Icons.add,
        size: 18,
        color: colorScheme.primary,
      ),
      onPressed: () async {
        showDialog<void>(
          context: context,
          // uncomment below to force user to tap button and not just tap outside the alert!
          // barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Add a new Vault'),
              content: TextFormField(
                initialValue: "",
                decoration: const InputDecoration(labelText: 'New Vault'),
                onChanged: (input) {
                  newVaultName = input;
                },
              ),
              actions: <Widget>[
                TextButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                      newVaultName = "";
                      Navigator.of(context).pop();
                    }),
                TextButton(
                    child: const Text('Add'),
                    onPressed: () async {
                      // NullPassDB npDB = NullPassDB.instance;
                      // await npDB.deleteAllSecrets();
                      var v = Vault(
                          nickname: newVaultName ?? '',
                          manager: VaultManager.Internal,
                          managerId: Vault.InternalSourceID,
                          isDefault: false);
                      var added = await NullPassDB.instance.insertVault(v);
                      newVaultName = "";
                      if (added) {
                        await NullPassDB.instance.addAuditRecord(AuditRecord(
                          type: AuditType.VaultCreated,
                          message: 'The "${v.nickname}" vault was added.',
                          vaultsReferenceId: <String>{v.uid},
                          date: DateTime.now().toUtc(),
                        ));
                        setState(() {
                          vaults[v.uid] = v;
                          selectedVaults[v.uid] = true;
                        });
                      }
                      Navigator.of(context).pop();
                    })
              ],
            );
          },
        );
      },
      side: BorderSide(color: colorScheme.primary),
    ));

    return widgetList;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.edit == SecretEditType.Create
                ? 'New Secret'
                : 'Update Secret',
          ),
        ),
        body: const CenterLoader(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.edit == SecretEditType.Create
              ? 'New Secret'
              : 'Update Secret',
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: <Widget>[
                  TextFormField(
                    onChanged: (value) {
                      setState(() {
                        _secret.nickname = value;
                      });
                      Log.debug('new nickname ${_secret.nickname}');
                    },
                    initialValue: _secret.nickname,
                    decoration: const InputDecoration(
                      labelText: 'Nickname',
                      hintText: 'Enter a memorable name',
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Nickname is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    onChanged: (value) {
                      setState(() {
                        _secret.website = value;
                      });
                      Log.debug('new website ${_secret.website}');
                    },
                    initialValue: _secret.website,
                    decoration: const InputDecoration(
                      labelText: 'Website',
                      hintText: 'example.com',
                      prefixIcon: Icon(Icons.language),
                    ),
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Website is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    onChanged: (value) {
                      setState(() {
                        _secret.username = value;
                      });
                      Log.debug('new username ${_secret.username}');
                    },
                    initialValue: _secret.username,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      hintText: 'user@example.com',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Username is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  PasswordInput(
                    onChange: (value) {
                      setState(() {
                        _secret.message = value;
                      });
                      Log.debug('new password ${_secret.message}');
                    },
                    controller: _passwordController,
                    initialValue: _secret.message ?? '',
                    setPassword: setPassword,
                    secret: _secret,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    onChanged: (value) {
                      setState(() {
                        _secret.otpCode = value.toUpperCase();
                      });
                      Log.debug('new otpCode ${_secret.otpCode}');
                    },
                    initialValue: _secret.otpCode?.toUpperCase(),
                    decoration: const InputDecoration(
                      labelText: 'One-Time Passcode',
                      hintText: 'otpauth://...',
                      prefixIcon: Icon(Icons.timer_outlined),
                      helperText: 'Optional: Scan or paste TOTP secret',
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if ((value?.trim().isNotEmpty ?? false) &&
                          _secret.getOnetimePasscode().trim() == '') {
                        return 'Invalid OTP code format';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    onChanged: (value) {
                      setState(() {
                        _secret.notes = value;
                      });
                      Log.debug('new notes ${_secret.notes}');
                    },
                    initialValue: _secret.notes,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Add additional notes...',
                      prefixIcon: Icon(Icons.notes),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                    textInputAction: TextInputAction.newline,
                  ),
                  const SizedBox(height: 24),
                  FormField(
                  builder: (fieldState) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vaults',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select which vaults will store this secret',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: _generateChips(context),
                      ),
                      if (fieldState.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            fieldState.errorText ?? '',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                  validator: (value) {
                    if (!selectedVaults.containsValue(true)) {
                      return 'Select at least one vault';
                    }
                    return null;
                  },
                ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                child: FilledButton(
                  onPressed: () => submit(context),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(
                    widget.edit == SecretEditType.Create
                        ? 'Create Secret'
                        : 'Save Changes',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PasswordInput extends StatefulWidget {
  final Function onChange;
  final String initialValue;
  final TextEditingController controller;
  final Function setPassword;
  final Secret secret;

  const PasswordInput({
    super.key,
    required this.onChange,
    required this.controller,
    required this.setPassword,
    required this.secret,
    this.initialValue = '',
  });

  @override
  _PasswordInputState createState() => _PasswordInputState();
}

class _PasswordInputState extends State<PasswordInput> {
  bool _visible = false;
  String? _initialValue;
  late TextEditingController _controller;
  late Function _setPassword;

  @override
  void initState() {
    super.initState();
    _initialValue ??= (widget.initialValue ?? '');
    _controller = widget.controller;
    _controller.text = _initialValue ?? '';
    _setPassword = widget.setPassword;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Calculate password strength
    String strengthText = 'Weak';
    double strengthValue = 0.33;
    Color strengthColor = colorScheme.error;
    
    if (_controller.text.isNotEmpty) {
      final strength = widget.secret.strength;
      if (strength >= 3) {
        strengthText = 'Strong';
        strengthValue = 1.0;
        strengthColor = Colors.green;
      } else if (strength >= 2) {
        strengthText = 'Fair';
        strengthValue = 0.66;
        strengthColor = Colors.orange;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _controller,
          onChanged: (value) {
            widget.onChange(value);
            setState(() {}); // Refresh to update strength indicator
          },
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'Enter or generate a password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    _visible
                        ? FontAwesomeIcons.solidEye
                        : FontAwesomeIcons.solidEyeSlash,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _visible = !_visible;
                    });
                  },
                  tooltip: _visible ? 'Hide password' : 'Show password',
                ),
                IconButton(
                  icon: const Icon(Icons.auto_awesome, size: 20),
                  onPressed: () async {
                    final result = await showModalBottomSheet(
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
                                      color: colorScheme.onSurfaceVariant
                                          .withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  Expanded(
                                    child: const SecretGenerate(inEditor: true),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                    if (result != null && result.toString().trim() != '') {
                      _setPassword(result.toString());
                      setState(() {
                        _initialValue = result.toString();
                      });
                    }
                  },
                  tooltip: 'Generate password',
                ),
              ],
            ),
          ),
          obscureText: !_visible,
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Password is required';
            }
            return null;
          },
        ),
        if (_controller.text.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: strengthValue,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                strengthText,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: strengthColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
