import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class AdaptiveProgressIndicator extends StatelessWidget {
  final Widget child;

  AdaptiveProgressIndicator({Key key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Theme.of(context).platform == TargetPlatform.iOS  ? CupertinoActivityIndicator() : CircularProgressIndicator();
  }
}