import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

import './event_card.dart';
import '../../models/event.dart';
import '../../scoped-models/main.dart';

class Events extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  Events(this.scaffoldKey);

  Widget _buildEventList(List<Event> events) {
    Widget eventCards;
    if (events.length > 0) {
      eventCards = ListView.builder(
        //Подгружает постепенно элементы списка
        //Хорош на big-списках
        itemBuilder: (BuildContext context, int index) => EventCard(events[index],scaffoldKey),
        itemCount: events.length,
      );
    } else {
      eventCards = Container();
    }
    return eventCards;
  }

  @override
  Widget build(BuildContext context) {
    print('[Events Widget] build()');
    return ScopedModelDescendant<MainModel>(
      builder: (BuildContext context, Widget child, MainModel model){
      return _buildEventList(model.displayedFavoriteAndTypeEvents);
    }); 
  }
}
