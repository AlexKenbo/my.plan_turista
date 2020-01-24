import 'package:flutter/material.dart';
import './event_edit.dart';

import 'package:scoped_model/scoped_model.dart';

import '../scoped-models/main.dart';

class EventListPage extends StatefulWidget {
  final MainModel model;

  EventListPage(this.model);

  State<StatefulWidget> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  @override
  void initState() { 
    widget.model.fetchEvents(onlyForUser: true, clearExisting: true);
    super.initState();
  }
  Widget _buildEditButton(BuildContext context, int index, MainModel model) {
    return IconButton(
        icon: Icon(Icons.edit),
        onPressed: () {
          model.selectEvent(model.allEvents[index].id);
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (BuildContext context) {
            return EventEditPage();
          })).then((_)=> model.selectEvent(null));
        },
      );
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<MainModel>(
      builder: (BuildContext context, Widget child, MainModel model) {
      
      return ListView.builder(
        itemBuilder: (BuildContext context, int index) {
          return Dismissible(
              key: Key(model.allEvents[index].title),
              onDismissed: (DismissDirection direction) {
                if (direction == DismissDirection.endToStart) {
                  model.selectEvent(model.allEvents[index].id);
                  model.deleteEvent();
                } else if (direction == DismissDirection.startToEnd) {
                  print('Swiped start to end');
                } else {
                  print('Other Swiping');
                }
              },
              background: Container(color: Colors.red[200]),
              child: Column(
                children: <Widget>[
                  ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(model.allEvents[index].image),
                    ),
                    title: Text(model.allEvents[index].title),
                    subtitle: Text('\$${model.allEvents[index].price}'),
                    trailing: _buildEditButton(context, index, model),
                  ),
                  Divider()
                ],
              ));
        },
        itemCount: model.allEvents.length,
      );
    });
  }
}
