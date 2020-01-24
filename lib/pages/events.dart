import 'package:flutter/material.dart';
import '../widgets/events/events.dart';

import 'package:scoped_model/scoped_model.dart';
import '../scoped-models/main.dart';

import '../widgets/ui_elements/adaptive_progress_indicated.dart';

import '../widgets/ui_elements/logout_list_tile.dart';

class EventsPage extends StatefulWidget {
  final MainModel model;

  EventsPage(this.model);
  _EventsPageState createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final List<Map<String, dynamic>> _widgetOptions = [
    {'index': 0, 'typeEvent':'Active', 'name': 'Активный отдых'},
    {'index': 1, 'typeEvent':'Tour', 'name': 'Экскурсии'},
    {'index': 2, 'typeEvent':'Spa', 'name': 'SPA туризм'},
    {'index': 3, 'typeEvent':'Child', 'name': 'Отдых с детьми'},
  ];
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> scaffoldKey =  GlobalKey<ScaffoldState>();


  @required
  void initState() {
    widget.model.fetchEvents();
    widget.model.fetchDays();
    //print('Init() - выбран день: ${widget.model.selectedVacationDay?.id}');

    _widgetOptions.forEach(
      (Map<String, dynamic> type) {
        if (type.containsValue(widget.model.showEventType)){
          _selectedIndex = type['index'];
        }
      }
    );
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
          
          ListTile(
              leading: Icon(Icons.list),
              title: Text('Мероприятия в Анапе', style: TextStyle(color: Color.fromARGB(125, 160, 160, 160),),),
          ),
          
          ListTile(
            leading: Icon(Icons.today),
            title: Text('Календарь моего отпуска'),
            onTap: () => Navigator.pushReplacementNamed(context, '/vacation'),
          ),
          Divider(),
          LogoutListTile(),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    return ScopedModelDescendant(
        builder: (BuildContext context, Widget child, MainModel model) {
      Widget content = Center(child: Text('Event not found'));

      if (model.displayedFavoriteAndTypeEvents.length > 0 && !model.isLoading) {
        content = Events(scaffoldKey);
        //print('Выведенно для типа:${model.showEventType} ${model.displayedFavoriteAndTypeEvents.length} событий');
      } else if (model.isLoading) {
        content = Center(child: AdaptiveProgressIndicator());
      }
      return RefreshIndicator(onRefresh: model.fetchEvents, child: content);
    });
  }

  void _onItemTapped(int index, MainModel model) {  
    setState(() {
      _selectedIndex = index;
    });
    model.toggleDisplayEventTypeMode(_widgetOptions.elementAt(index)['typeEvent']);
    widget.model.fetchEvents();
  }

  @override
  Widget build(BuildContext context) {
    print('Build() - выбран день: ${widget.model.selectedVacationDay?.id}');
    // TODO: implement build
    return Scaffold(
      key: scaffoldKey,
      drawer: _buildSideDrawer(context),
      appBar: AppBar(
        title: Text(_widgetOptions.elementAt(_selectedIndex)['name']),
        elevation: Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 0.4,
        
        /* OFF Favorites
        actions: <Widget>[
          ScopedModelDescendant<MainModel>(
            builder: (BuildContext context, Widget child, MainModel model) {
              return IconButton(
                  icon: Icon(model.displayFavoritesOnly
                      ? Icons.favorite
                      : Icons.favorite_border),
                  onPressed: () {
                    model.toggleDisplayFavoriteMode();
                  });
            },
          ),
        ],*/
      ),
      body: _buildEventsList(),
      bottomNavigationBar: ScopedModelDescendant<MainModel>(
          builder: (BuildContext context, Widget child, MainModel model) {
        return BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
                icon: Icon(Icons.terrain),
                title: Text('Активный'),
                backgroundColor: Colors.grey),
            BottomNavigationBarItem(
                icon: Icon(Icons.local_see),
                title: Text('Экскурсии'),
                backgroundColor: Colors.grey),
            BottomNavigationBarItem(
                icon: Icon(Icons.spa),
                title: Text('SPA туризм'),
                backgroundColor: Colors.grey),
            BottomNavigationBarItem(
                icon: Icon(Icons.child_care),
                title: Text('Для детей'),
                backgroundColor: Colors.grey),
          ],
          currentIndex: _selectedIndex, 
          fixedColor: Colors.red,
          onTap: (index) => _onItemTapped(index, model),
          type: BottomNavigationBarType.fixed,
        );
      }),
    );
  }
}
