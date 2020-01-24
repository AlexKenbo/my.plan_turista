import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:scoped_model/scoped_model.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/event.dart';
import '../../scoped-models/main.dart';

class EventFAB extends StatefulWidget {
  final Event event;

  EventFAB(this.event);

  _EventFABState createState() => _EventFABState();
}

class _EventFABState extends State<EventFAB> with TickerProviderStateMixin {
  AnimationController _controller;

  @override
  void initState() {
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant(
        builder: (BuildContext context, Widget child, MainModel model) {
      return Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            height: 70.0,
            width: 56.0,
            alignment: FractionalOffset.topCenter,
            child: ScaleTransition(
                scale: CurvedAnimation(
                  parent: _controller,
                  curve: Interval(0.0, 1.0, curve: Curves.easeOut),
                ),
                child: FloatingActionButton(
                  backgroundColor: Theme.of(context).cardColor,
                  heroTag: 'contact',
                  mini: true,
                  onPressed: () async {
                    final url = 'mailto:${widget.event.userEmail}';
                    if (await canLaunch(url)) {
                      await launch(url);
                    } else {
                      throw 'Could not launch!';
                    }
                  },
                  child: Icon(
                    Icons.mail,
                    color: Theme.of(context).primaryColor,
                  ),
                ))),
        /* OFF Favorite
        Container(
            height: 70.0,
            width: 56.0,
            alignment: FractionalOffset.topCenter,
            child: ScaleTransition(
                scale: CurvedAnimation(
                  parent: _controller,
                  curve: Interval(0.0, 0.5, curve: Curves.easeOut),
                ),
                child: FloatingActionButton(
                  backgroundColor: Theme.of(context).cardColor,
                  heroTag: 'favorite',
                  mini: true,
                  onPressed: () {
                    model.toggleEventFavoriteStatus(model.selectedEvent);
                  },
                  child: Icon(
                    model.selectedEvent.isFavorite
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: Colors.red[300],
                  ),
                ))),
                */
        Container(
            height: 70.0,
            width: 56.0,
            child: FloatingActionButton(
              heroTag: 'options',
              mini: true,
              onPressed: () {
                if (_controller.isDismissed) {
                  _controller.forward();
                } else {
                  _controller.reverse();
                }
              },
              child: AnimatedBuilder(
                animation: _controller,
                builder: (BuildContext context, Widget child) {
                  return Transform(
                    alignment: FractionalOffset.center,
                    transform: Matrix4.rotationZ(_controller.value * 0.5 * math.pi),
                    child: Icon(_controller.isDismissed ? Icons.more_vert : Icons.close));
              }),
            )),
      ]);
    });
  }
}
