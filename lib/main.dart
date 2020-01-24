import 'dart:async';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:flutter/material.dart';

//import 'package:flutter/rendering.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:map_view/map_view.dart';

import './pages/auth.dart';
import './pages/events_admin.dart';
import './pages/events.dart';
import './pages/event.dart';
import './pages/vacation.dart';

import './models/event.dart';
import './scoped-models/main.dart';

import './widgets/helpers/custom_route.dart';
import './shared/global_config.dart';
import './shared/adaptive_theme.dart';

void main() {
  //debugPaintSizeEnabled = true;
  //debugPaintBaselinesEnabled = true;
  //debugPaintPointersEnabled = true;
  MapView.setApiKey(apiKey);
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MyAppState();
  }
}

class _MyAppState extends State<MyApp> {
  final MainModel _model = MainModel();
  bool _isAuthenticated = false;


  void initState() {
    _model.autoAuthenticate();
    _model.userSubject.listen((bool isAuthenticated){
      setState(() {
        _isAuthenticated = isAuthenticated;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print('building main page');
    return ScopedModel<MainModel>(
        model: _model,
        child: MaterialApp(
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate, // if it's a RTL language
          ],
          supportedLocales: [
            const Locale('ru', 'RU'), // include country code too
          ],
          title: 'Tourist Calendar',
          routes: {
            '/': (BuildContext context) => !_isAuthenticated
                ? AuthPage()
                : EventsPage(_model), // Слеш зарезирвирован под home:
            '/admin': (BuildContext context) {
              print('_model.user.id = ${_model.user.id}'); 
              if(!_isAuthenticated) return AuthPage();
              else if (_model.user.id != 'mZUZlwnlwWSgQ6LiwYJQxCA6ZUH3') {
                return Scaffold(
                  appBar: AppBar(
                    leading: Builder(
                      builder: (BuildContext context) {
                        return IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () { Navigator.pushReplacementNamed(context, '/'); },
                        );
                      },
                    ),
                    title: Text('Управление мероприятиями'),
                    elevation: Theme.of(context).platform == TargetPlatform.iOS
                        ? 0.0
                        : 0.4,
                  ),
                  body: Center(
                    child: Container(
                      padding: EdgeInsets.all(32.0),
                      child: Text('Раздел доступен только организаторам. Связитесь с нами, чтобы стать организатором. Тел. +79184773543, Александр.'),),
                    ),
                );
              } 
              else return EventsAdminPage(_model);
              },
            '/vacation': (BuildContext context) => !_isAuthenticated
                ? AuthPage()
                : VacationPage(_model),
          },
          onGenerateRoute: (RouteSettings settings) {
            if (!_isAuthenticated){
              return MaterialPageRoute<bool>(
                builder: (BuildContext context) => AuthPage()
              );
            }
            final List<String> pathElements = settings.name.split('/');
            if (pathElements[0] != '') {
              return null;
            }

            if (pathElements[1] == 'event') {
              final String eventId = pathElements[2];
              final Event event =
                  _model.allEvents.firstWhere((Event event) {
                return event.id == eventId;
              });
              return CustomRoute<bool>(
                  builder: (BuildContext context) => !_isAuthenticated
                ? AuthPage()
                : EventPage(event));
            }

            return null;
          },
          onUnknownRoute: (RouteSettings settings) {
            return MaterialPageRoute(
              builder: (BuildContext context) => !_isAuthenticated
                ? AuthPage()
                : EventsPage(_model),
            );
          },
          //debugShowMaterialGrid: true,
          theme: getAdaptiveThemeData(context),
          //home: AuthPage(), - убрал, так как использую '/'
        ));
  }
}
