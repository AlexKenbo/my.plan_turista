import 'package:flutter/material.dart';

import './event_edit.dart';
import './event_list.dart';
import '../scoped-models/main.dart';

import '../widgets/ui_elements/logout_list_tile.dart';

class EventsAdminPage extends StatelessWidget {
  final MainModel model;

  EventsAdminPage(this.model);

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
            title: Text('Добавить мероприятие', style: TextStyle(color: Color.fromARGB(125, 160, 160, 160),),),
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
              title: Text('Календарь моего отпуска'),
              ),
          Divider(),
          LogoutListTile(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
          drawer: _buildSideDrawer(context),
          appBar: AppBar(
            title: Text('Управление мероприятиями'),
            elevation: Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 0.4,
            bottom: TabBar(
              tabs: <Widget>[
                Tab(
                  icon: Icon(Icons.create),
                  text: 'Создать мероприятие',
                ),
                Tab(
                  icon: Icon(Icons.list),
                  text: 'Мои мероприятия',
                  ),
              ],
            ),
          ),
          body: Center(
            child: TabBarView(
              children: <Widget>[
                EventEditPage(),
                EventListPage(model),
              ],
            ),
          ),
        ));
  }
}
