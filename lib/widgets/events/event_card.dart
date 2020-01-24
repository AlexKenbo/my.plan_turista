import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plan_turista/models/vacation_day.dart';

import 'package:scoped_model/scoped_model.dart';

import './price_tag.dart';
import '../ui_elements/title_default.dart';
import './address_tag.dart';

import '../../models/event.dart';
import '../../scoped-models/main.dart';

import '../../pages/vacation_settings.dart';


class EventCard extends StatefulWidget {
  final Event event;
  final GlobalKey<ScaffoldState> scaffoldKey;

  EventCard(this.event, this.scaffoldKey);

  _EventCardState createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {

  Future<Null> _selectDate(BuildContext context, MainModel model) async {
    if(model.daysVacation.length > 0) {
      print('selectedVacationDay: ${model.selectedVacationDay?.date}');
      print('First daysVacation: ${model.daysVacation.elementAt(0).date}');
      print('Last daysVacation: ${model.daysVacation.last.date}');
      DateTime _date = model.selectedVacationDay?.date;    
      final DateTime picked = await showDatePicker(
          context: context,
          initialDate: _date ?? model.daysVacation.elementAt(0).date,
          firstDate: model.daysVacation.elementAt(0).date,
          lastDate: model.daysVacation.last.date,
          builder: (BuildContext context, Widget child) {
            return Theme(
              data: ThemeData.light(),
              child: child,
            );
          }
      );

      if (picked != null) {
        print('Date picked: ${picked.toString()}');
        model.setEventForDay(widget.event.id, picked);

        final snackBar = SnackBar(
          content: Text('Запланированно на ${DateFormat.yMd().format(picked)}'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.blue,
        );
        widget.scaffoldKey.currentState.showSnackBar(snackBar);
      }
    } else {
      final snackBar = SnackBar(
        content: Text('У вас не выбраны даты отпуска'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 8),
        action: SnackBarAction(
          label: 'Выбрать',
          textColor: Color(0xBB183451),
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute<bool>(
                builder: (BuildContext context) {
                  return VacationSettingsPage(null);
                },
                fullscreenDialog: true)
            );
          },
        )
      );
      widget.scaffoldKey.currentState.showSnackBar(snackBar);
    }
  }

  Widget _buildTitlePriceRow() {
    return Container(
        //margin: EdgeInsets.only(top: 20.0),
        //margin: EdgeInsets.symmetric(vertical: 15.0),
        padding: EdgeInsets.only(top: 20.0),
        //color: Colors.red,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Flexible(child: TitleDefault(widget.event.title)),
            Flexible(
              child: SizedBox(
              width: 8.0,
            )),
            Flexible(
              child: PriceTag(widget.event.price.toString())
            ),
          ],
        ));
  }


  Widget _buildActionButtons(BuildContext context) {
    return ScopedModelDescendant<MainModel>(
        builder: (BuildContext context, Widget child, MainModel model) {
      return ButtonBar(alignment: MainAxisAlignment.center, children: <Widget>[

        /* OFF Favorite
        IconButton(
          icon: Icon(widget.event.isFavorite
              ? Icons.favorite
              : Icons.favorite_border),
          color: Colors.red,
          onPressed: () {
            //model.selectEvent(event.id);
            model.toggleEventFavoriteStatus(widget.event);
          }
        ),*/
        RaisedButton(
          onPressed: () {
            model.selectEvent(widget.event.id);
            Navigator.pushNamed<bool>(
              context,
              '/event/${widget.event.id}').then((_) => model.selectEvent(null) 
            );
          }, 
          //icon: Icon(Icons.info),
          color: Colors.green, // если выбран делать зеленным, если не выбран серым
          textColor: Colors.white,
          child: Text('Подробнее')
        ),
        OutlineButton.icon(
          onPressed: () {
            _selectDate(context, model);
          }, 
          icon: Icon(Icons.event_available),
          //color: Theme.of(context).accentColor, // если выбран делать зеленным, если не выбран серым
          //textColor: Theme.of(context).accentColor,
          shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(2.0)),
          label: Text('В календарь')
        ),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: <Widget>[
          Hero(
            tag: widget.event.id,
            child: FadeInImage(
              image: NetworkImage(widget.event.image),
              height: 300.0,
              fit: BoxFit.cover,
              placeholder: AssetImage('assets/background.jpg'),
            )
          ),
          //SizedBox(height: 10.0),
          _buildTitlePriceRow(),
          SizedBox(height: 10.0,),
          AddressTag(widget.event.location.address), //когда будет локация у эвента
          //AddressTag('Анапа, Крымская, 126'),
          //Text(widget.event.type),
          _buildActionButtons(context),
        ],
      ),
    );
  }
}
