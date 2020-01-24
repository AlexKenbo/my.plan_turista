import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plan_turista/widgets/events/event_card.dart';

import 'package:scoped_model/scoped_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import './vacation_week.dart'; //вкладка с неделей
import './vacation_settings.dart';

import '../models/vacation.dart';
import '../models/vacation_day.dart';
import '../models/event.dart';

import '../scoped-models/main.dart';

import '../widgets/ui_elements/logout_list_tile.dart';


class VacationPage extends StatefulWidget {
  final MainModel model;

  VacationPage(this.model);

  State<StatefulWidget> createState() => _VacationPageState();
}

class _VacationPageState extends State<VacationPage> {
  String vacationId;
  String userId;
  DocumentReference dr;

  @override
  void initState() {
    //widget.model.fetchDays(); //вроде бы не нужно!
    userId = widget.model.user.id;
    print('userId=$userId');
    
                  /*
                  .collection('days')
                  .where('visible', isEqualTo: true)
                  .snapshots().forEach((doc){
                    doc.documents.forEach((d){
                      print(d.data['date']);
                    });
                  });
                  */
    //vacationId = widget.model.vacation == null
    //    ? widget.model.fetchVacationByUser()
    //    : widget.model.vacation.id;
    super.initState();
  }



  Widget _buildSideDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: <Widget>[
          AppBar(
            automaticallyImplyLeading:
                false, //выкл. автоматическое добавление др. элементов, - иконка бутерброд
            title: Text('Выбрать'),
            elevation:
                Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 0.4,
          ),
          ListTile(
            leading: Icon(Icons.supervisor_account),
            title: Text('Добавить мероприятие'),
            onTap: () => Navigator.pushReplacementNamed(context, '/admin'),
          ),
          Divider(),
          ListTile(
              leading: Icon(Icons.list),
              title: Text('Мероприятия в Анапе'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/');
              }),
          Divider(),
          ListTile(
              leading: Icon(Icons.today),
              title: Text('Календарь моего отпуска', style: TextStyle(color: Color.fromARGB(125, 160, 160, 160),),),
              ),
          Divider(),
          LogoutListTile(),
        ],
      ),
    );
  }

  Future _openVacationSettingsPage(List<VacationDay> listDays) async {
    bool submitVacation =
        await Navigator.of(context).push(MaterialPageRoute<bool>(
            builder: (BuildContext context) {
              return VacationSettingsPage(listDays);
            },
            fullscreenDialog: true));
    if (submitVacation == true) {
      //print('Vacation submit');
      //_buildTabs(vacation);
      //_addWeightSave(vacationNew);
    }
  }

  Widget _buildEventListTile(eventId) {
    Event ev = widget.model.selectEventById(eventId.toString().trim());

    return ListTile(
      title: Text(ev.title),
      leading: CircleAvatar(backgroundImage: NetworkImage(ev.image)),
      subtitle: Text(ev.description),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildSideDrawer(context),
      appBar: AppBar(
        title: Text('Календарь моего отпуска'),
        elevation: Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 0.4,
        actions: <Widget>[
          ScopedModelDescendant<MainModel>(
            builder: (BuildContext context, Widget child, MainModel model) {
              return IconButton(
                  icon: Icon(Icons.settings_applications),
                  onPressed: () {
                    _openVacationSettingsPage(model.daysVacation);
                  });
            },
          ),
        ],
      ),
      body: Center(
        child: Container(
            padding: const EdgeInsets.all(10.0),
            child: StreamBuilder<QuerySnapshot>(
              stream: Firestore.instance
                        .collection('days')
                          .where("userId", isEqualTo: userId)
                          .where('visible', isEqualTo: true)
                          .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) return Text('Ошибка: ${snapshot.error}');
                switch (snapshot.connectionState) {
                  case ConnectionState.waiting:
                    return Text('Загрузка...');
                  default:
                    return ListView(children: [
                      ...snapshot.data.documents
                          .map((DocumentSnapshot document) {
                        List<dynamic> eventIds = document['events'];    
                        int eventCount = eventIds != null ? eventIds.length : 0;
                        return Card(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              ListTile(
                                //leading: Icon(Icons.album), Для самого события можно использовать
                                title: Text(
                                  DateFormat('d MMMM yyyy, EEEE', 'ru_RU').format((document['date'] as Timestamp).toDate()), style: Theme.of(context).textTheme.title,
                                  ),
                                subtitle: Text(
                                    'Запланированно $eventCount события(й)'),
                              ),
                              if (eventCount != 0)
                                for (dynamic eventId in eventIds)
                                  _buildEventListTile(eventId),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: <Widget>[
                                  ScopedModelDescendant<MainModel>(
                                    builder:(BuildContext context, Widget child, MainModel model) {
                                      return FlatButton.icon(
                                        label: Text('Добавить событие'),
                                        icon: Icon(Icons.add_box),
                                        onPressed: () { 
                                          
                                          VacationDay vd = VacationDay(
                                              id: document.documentID,
                                              date: document.data['date'].toDate(), //c FireStore приходит Timestamp
                                              userId: userId,
                                              visible: document.data['visible']
                                            );
                                          model.selectVacationDay(vd);
                                          Navigator.pushReplacementNamed(context, '/');
                                          },
                                      );
                                  }),
                                ],
                              )
                            ],
                          ),
                        );
                      }).toList(),
                    ]);
                }
              },
            )),
      ),

//      StreamBuilder(
//        stream: Firestore.instance.collection('vacation_days').snapshots(),
//        builder: (context, snapshot) {
//          if (!snapshot.hasData) return const Text('Loading..');
//          return ListView.builder(
//            itemExtent: 80.0,
//            itemCount: snapshot.data.documents.length,
//            itemBuilder: (context, index) =>
//                _buildListItem(context, snapshot.data.documents[index])
//            );
//        }),
      /*Center(
            child: TabBarView(
              children: <Widget>[
                VacationWeekPage(widget.model),
              ],
            ),
          ),*/
      //),
    );
  }
}
