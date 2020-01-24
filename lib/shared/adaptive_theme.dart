import 'package:flutter/material.dart';

final ThemeData _androidTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: Color(0xFFF4511E),
  accentColor: Colors.deepPurple,
  fontFamily: 'Helvetica',
  buttonColor: Colors.red,
);

final ThemeData _iOSTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: Color(0xFFF4511E),
  accentColor: Colors.blue,
  fontFamily: 'Helvetica',
  buttonColor: Colors.blue,

);

ThemeData getAdaptiveThemeData(context) {
  return Theme.of(context).platform == TargetPlatform.android ? _androidTheme : _iOSTheme;
}