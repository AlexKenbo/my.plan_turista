import 'package:flutter/material.dart';
import 'dart:async';

//import 'package:map_view/map_view.dart';
import './single_map_page.dart';

import '../widgets/ui_elements/title_default.dart';
import '../widgets/events/event_fab.dart';
import '../models/event.dart';

class EventPage extends StatelessWidget {
  final Event event;

  EventPage(this.event);

  Future _showMap(context) async {
    
    await Navigator.of(context).push(MaterialPageRoute<bool>(
            builder: (BuildContext context) {
              return SingleMapPage(event.location.latitude, event.location.longitude, event.title);
            },
            fullscreenDialog: true));
  }

  Widget _buildAddressPriceRow(BuildContext context, String address, double price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        GestureDetector(
            onTap: () async { await _showMap(context);},
            child: Text(address,
                style: TextStyle(fontFamily: 'Oswald', color: Colors.grey))),
        Container(
            margin: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              '|',
              style: TextStyle(color: Colors.grey),
            )),
        Text(
          '\$' + price.toString(),
          style: TextStyle(fontFamily: 'Oswald', color: Colors.grey),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () {
          print('Back button pressed');
          Navigator.pop(context, false);
          return Future.value(false);
        },
        child: Scaffold(
            //appBar: AppBar(
            //  title: Text(event.title),
            //),
            body: CustomScrollView(slivers: <Widget>[
              SliverAppBar(
                expandedHeight: 256.0,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(event.title),
                  background: Hero(
                    tag: event.id,
                    child: FadeInImage(
                      image: NetworkImage(event.image),
                      height: 300.0,
                      fit: BoxFit.cover,
                      placeholder: AssetImage('assets/background.jpg'),
                    )
                  ),
                ),
              ),
              SliverList(delegate: SliverChildListDelegate([
                Container(
                  padding: EdgeInsets.all(10.0),
                  alignment: Alignment.center,
                  child:TitleDefault(event.title),
                ),
                _buildAddressPriceRow( context,
                  event.location.address, event.price),
                Container(
                  padding: EdgeInsets.all(10.0),
                  child: Text(
                    event.description,
                    textAlign: TextAlign.left,
                  )
                ),
              ]),)
            ],),
        floatingActionButton: EventFAB(event),
      )
    );
  }
}
