/*
 * Created by Ilan Rasekh on 2019/10/2
 * Copyright (c) 2019 Pseudorand Development. All rights reserved.
 */

import 'package:flutter/material.dart';
import 'package:nullpass/screens/secretGenerate.dart';
import 'package:nullpass/secret.dart';
import 'package:uuid/uuid.dart';
import 'package:validators/validators.dart';

enum SecretEditType { Create, Update }

class SecretEdit extends StatefulWidget {
  Secret secret =
      new Secret(nickname: '', website: '', username: '', message: '');
  SecretEditType edit;

  SecretEdit({Key key, this.secret, @required this.edit}) : super(key: key);

  @override
  _CreateSecretState createState() => _CreateSecretState();
}

class _CreateSecretState extends State<SecretEdit> {
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();

  void submit(BuildContext context) async {
    // First validate form.
    if (this._formKey.currentState.validate()) {
      _formKey.currentState.save(); // Save our form now.

      // SAVE
      if (widget.secret.uuid == null ||
          !isUUID(widget.secret.uuid.trim(), '4')) {
        widget.secret.uuid = (new Uuid()).v4();
      }
      Secret secretSave = Secret(
          uuid: widget.secret.uuid,
          nickname: widget.secret.nickname,
          website: widget.secret.website,
          username: widget.secret.username,
          message: widget
              .secret.message, // TODO: move password to secure storage - remove
          notes: widget.secret.notes);
      NullPassDB helper = NullPassDB.instance;
      bool success = false;
      if (widget.edit == SecretEditType.Create) {
        success = await helper.insert(secretSave);
        print('inserted row(s) - $success');
        // await showSnackBar(context, 'Created!');
      } else if (widget.edit == SecretEditType.Update) {
        success = await helper.update(secretSave);
        print('updated row(s) - $success');
        // await showSnackBar(context, 'Updated!');
      }

      Navigator.pop(context, 'true');
    }
  }

  @override
  Widget build(BuildContext context) {
    // final Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: (widget.edit == SecretEditType.Create)
            ? Text('New Secret')
            : ((widget.edit == SecretEditType.Update)
                ? Text('Update Secret')
                : Text('Secret Action')),
        actions: <Widget>[
          FlatButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ))
        ],
      ),
      body: new Container(
        padding: new EdgeInsets.all(20.0),
        child: new Form(
          key: this._formKey,
          child: new ListView(
            children: <Widget>[
              ListTile(
                title: TextFormField(
                  onChanged: (value) {
                    widget.secret.nickname = value;
                    print('new nickname ${widget.secret.nickname}');
                  },
                  initialValue: widget.secret.nickname,
                  decoration: InputDecoration(
                      labelText: 'Nickname', border: InputBorder.none),
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'The Nickname field cannot be empty';
                    }
                    return null;
                  },
                ),
              ),
              _FormDivider(),
              ListTile(
                title: TextFormField(
                  onChanged: (value) {
                    widget.secret.website = value;
                    print('new website ${widget.secret.website}');
                  },
                  initialValue: widget.secret.website,
                  decoration: InputDecoration(
                      labelText: 'Website', border: InputBorder.none),
                  keyboardType: TextInputType.url,
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'The Website field cannot be empty';
                    }
                    return null;
                  },
                ),
              ),
              _FormDivider(),
              ListTile(
                title: TextFormField(
                  onChanged: (value) {
                    widget.secret.username = value;
                    print('new username ${widget.secret.username}');
                  },
                  initialValue: widget.secret.username,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: InputBorder.none,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'The Username field cannot be empty';
                    }
                    return null;
                  },
                ),
              ),
              _FormDivider(),
              PasswordInput(
                  onChange: (value) {
                    widget.secret.message = value;
                    print('new password ${widget.secret.message}');
                  },
                  initialValue: widget.secret.message),
              _FormDivider(),
              ListTile(
                title: TextFormField(
                  onChanged: (value) {
                    widget.secret.notes = value;
                    print('new notes ${widget.secret.notes}');
                  },
                  initialValue: widget.secret.notes,
                  decoration: InputDecoration(
                      labelText: 'Notes', border: InputBorder.none),
                ),
              ),
              _FormDivider(),
              // Padding(padding: EdgeInsetsGeometry(2,2,2,2))
              ListTile(
                title: RaisedButton(
                  onPressed: () {
                    submit(context);
                  },
                  child: Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () async {
          final result = await showModalBottomSheet(
              context: context,
              builder: (BuildContext context) {
                return new SecretGenerate();
              });
          if (result != null && result.toString().trim() != '') {
            widget.secret.message = result.toString();
          }
        },
        tooltip: 'Generate',
        child: Icon(Icons.lock_outline),
      ),
    );
  }
}

class _FormDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 0.5,
      thickness: 1,
      indent: 16,
      endIndent: 16,
    );
  }
}

class PasswordInput extends StatefulWidget {
  final Function onChange;
  String initialValue = '';

  PasswordInput({Key key, @required this.onChange, this.initialValue})
      : super(key: key);

  @override
  _PasswordInputState createState() => _PasswordInputState();
}

class _PasswordInputState extends State<PasswordInput> {
  bool _visible = false;
  // String _initialValue = '';

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: TextFormField(
        onChanged: (value) {
          widget.onChange(value);
        },
        decoration: InputDecoration(
          labelText: 'Password',
          border: InputBorder.none,
        ),
        initialValue: widget.initialValue,
        obscureText: !_visible,
        validator: (value) {
          if (value.isEmpty) {
            return 'The Password field cannot be empty';
          }
          return null;
        },
      ),
      trailing: Container(
        width: 100,
        child: Row(
          children: <Widget>[
            IconButton(
              icon: Icon(_visible
                  // TODO: FIX ICON ISSUES FOR SHOW AND HIDE PASSWORD FIELD
                  ? /* el-eye-close */ IconData(0xf150, fontFamily: 'Elusive')
                  // : /* el-eye-open */ IconData(0xf151, fontFamily: 'Elusive'),
                  : Icons.remove_red_eye),
              onPressed: () {
                // _initialValue = this.widget.
                setState(() {
                  _visible = !_visible;
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.lock_outline),
              onPressed: () async {
                final result = await showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return new SecretGenerate();
                    });
                if (result != null && result.toString().trim() != '') {
                  widget.initialValue = result.toString();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
