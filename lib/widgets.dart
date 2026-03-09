/*
 * Created by Ilan Rasekh on 2019/10/30
 * Copyright (c) 2019 Pseudorand Development. All rights reserved.
 */
import 'package:flutter/material.dart';

class DefaultThumbnnail extends StatelessWidget {
  const DefaultThumbnnail({super.key});

  @override
  Widget build(BuildContext context) {
    return const CircleAvatar(
      backgroundColor: Colors.transparent,
      backgroundImage:
          AssetImage('assets/images/null_iosScaledDown_1500_Transparent.png'),
    );
  }
}

class FormDivider extends StatelessWidget {
  const FormDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 0.5,
      thickness: 1,
      indent: 16,
      endIndent: 16,
    );
  }
}

class CenterLoader extends StatelessWidget {
  const CenterLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

class CenterText extends StatelessWidget {
  final String _text;

  const CenterText(this._text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(_text),
        ],
      ),
    );
  }
}

class NullPassFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Function(bool) onSelected;

  const NullPassFilterChip(
      {super.key, required this.label,
      required this.isSelected,
      required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(color: isSelected ? Colors.white : Colors.black),
      ),
      onSelected: onSelected,
      selected: isSelected,
      backgroundColor: Colors.white,
      checkmarkColor: Colors.white,
      shape: StadiumBorder(
          side: isSelected
              ? const BorderSide(color: Colors.white)
              : const BorderSide(color: Colors.blue)),
      selectedColor: Colors.blue,
    );
  }
}
