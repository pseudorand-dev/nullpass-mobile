/*
 * Created by Ilan Rasekh on 2019/10/30
 * Copyright (c) 2019 Pseudorand Development. All rights reserved.
 */
import 'package:flutter/material.dart';

class DefaultThumbnnail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Colors.transparent,
      backgroundImage:
          AssetImage('assets/images/null_iosScaledDown_1500_Transparent.png'),
    );
  }
}

class FormDivider extends StatelessWidget {
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

class CenterLoader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(),
    );
  }
}

class CenterText extends StatelessWidget {
  final String _text;

  CenterText(this._text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(this._text),
        ],
      ),
    );
  }
}

class NullPassFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Function(bool) onSelected;

  NullPassFilterChip(
      {@required this.label,
      @required this.isSelected,
      @required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(
        this.label,
        style: TextStyle(color: this.isSelected ? Colors.white : Colors.black),
      ),
      onSelected: this.onSelected,
      selected: this.isSelected,
      backgroundColor: Colors.white,
      checkmarkColor: Colors.white,
      shape: StadiumBorder(
          side: this.isSelected
              ? BorderSide(color: Colors.white)
              : BorderSide(color: Colors.blue)),
      selectedColor: Colors.blue,
    );
  }
}
