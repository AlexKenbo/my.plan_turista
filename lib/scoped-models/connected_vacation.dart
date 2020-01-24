import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxdart/subjects.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:date_utils/date_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/event.dart';
import '../models/user.dart';
import '../models/auth.dart';
import '../models/location_data.dart';
import '../models/vacation.dart';
import '../models/vacation_day.dart';

mixin ConnectedEventsModel on Model {
  List<Event> _events = [];
  
  String _selEventId;
  User _authenticatedUser;
  bool _isLoading = false;
}

mixin VacationModel on ConnectedEventsModel {
  Vacation _vacation;
  VacationDay _selectedVacationDay;
  List<VacationDay> _daysVacation = [];
  

  Vacation get vacation {
    if (_vacation == null) {
      return null;
    }
    return _vacation;
  }

  VacationDay get selectedVacationDay {
    if (_selectedVacationDay == null) {
      return null;
    }
    return _selectedVacationDay;
  }

  List<VacationDay> get daysVacation {
    return List.from(_daysVacation);
  }


  void selectVacationDay(VacationDay day) {
    _selectedVacationDay = day;
    print(_selectedVacationDay.id);
  }

  Future<Null> setEventForDay(String eventId, DateTime pickedDate) async {
    print('setEventForDay($eventId, $pickedDate)');
    Map<String, dynamic> _data;
    List<String> eventsIds = [];

    var pickedDay = _daysVacation.firstWhere(
      (d) => d.date.toString() == pickedDate.toString()
    );

    DocumentReference vacationDayDocRef = Firestore.instance
      .collection('days')
      .document(pickedDay.id);

    await vacationDayDocRef.get().then((doc){
      print('DaysID ${doc.documentID}');
      
      eventsIds = doc.data['events'] != null ? List<String>.from(doc.data['events']) : [];
      if(!eventsIds.contains(eventId)) eventsIds.add(eventId);
      
      _data = doc.data;
      _data['events'] = eventsIds;    
    });

    vacationDayDocRef.updateData(_data);
  }

  
  Future<bool> addVacation(DateTime from, DateTime to) async {
    _isLoading = true;
    notifyListeners();
    List<VacationDay> _daysVacation = [];

    print('RUN model.addVacation()');
    try {

      List<DateTime> datesForVacation = Utils.daysInRange(from, to.add(Duration(days:1))).toList();
      
      //print(datesForVacation.toString());

      await Future.forEach(datesForVacation, (DateTime newDay) async {
          Map<String, dynamic> dayData = { 
                'date': newDay, 
                'userId': _authenticatedUser.id,
                'visible': true
            };
          DocumentReference vacationDayDocRef = await Firestore.instance
            .collection('days').add(dayData);
          
          print('Add new day: ${vacationDayDocRef.documentID} / ${newDay.toIso8601String()}');
          VacationDay vacDay = VacationDay.fromMap(dayData, vacationDayDocRef.documentID);
          //print(vacDay.date);  
          _daysVacation.add(vacDay); 
        });

      print('Start create object Vacation');

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (error) {
      print(error.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateVacation(DateTime from, DateTime to) async {
    _isLoading = true;
    notifyListeners();

    List<VacationDay> _daysVacationTemp = [];

    print('RUN model.updateVacation()');
    try {

      List<DateTime> newDays = Utils.daysInRange(from, to.add(Duration(days:1))).toList();
      //print(datesOfVacation.toString());

      QuerySnapshot daysSnapshot = await Firestore.instance
        .collection('days')
        .where('userId', isEqualTo: _authenticatedUser.id)
        .getDocuments();  
      
      await Future.forEach(daysSnapshot.documents, (DocumentSnapshot daySnap) async {

        Timestamp ds = daySnap.data['date'];
        DateTime _date = ds.toDate();

        bool visible = newDays.contains(_date) ? true : false; 
        if (visible) newDays.remove(_date);
        //print('dates list: ${newDays.toString()}');

        print('Set visible = $visible for $_date');
        await daySnap.reference.updateData({'visible':visible});

        DocumentSnapshot dayData = await daySnap.reference.get();
        print('Firebase: ${dayData.data.toString()}');

        VacationDay day = VacationDay.fromMap(dayData.data, dayData.documentID);
        print('Memory: ${day.date}');
        _daysVacationTemp.add(day); 
      });

      //Добавление новых дней
      await Future.forEach(newDays, (DateTime newDay) async {
        Map<String, dynamic> dayData = { 
                'date': newDay, 
                'userId': _authenticatedUser.id,
                'visible': true
          };
        Firestore.instance
          .collection('days')
          .add(dayData)
          .then((DocumentReference dr) async {
              print('Add new day: ${dr.documentID} / ${newDay.toIso8601String()}');
              VacationDay vacDay = VacationDay.fromMap(dayData, dr.documentID);
              _daysVacationTemp.add(vacDay); 
          }); 
      });
      _daysVacation = List.from(_daysVacationTemp);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (error) {
        _isLoading = false;
        notifyListeners();
        return false;
    }
  }


  Future<Null> fetchDays() async {
    _isLoading = true;
    notifyListeners();
    _daysVacation = [];
    final List<VacationDay> fetchDaysVacation = [];

    QuerySnapshot daysSnapshot = await Firestore.instance
        .collection('days')
        .where('userId', isEqualTo: _authenticatedUser.id)
        .where('visible', isEqualTo: true)
        .getDocuments(); 

    await Future.forEach(daysSnapshot.documents, (DocumentSnapshot daySnap) async {
      DocumentSnapshot dayData = await daySnap.reference.get();

      VacationDay day = VacationDay.fromMap(dayData.data, dayData.documentID);
      fetchDaysVacation.add(day); 
    });
    _isLoading = false;
    _daysVacation = fetchDaysVacation;
    _daysVacation.sort((a, b) => a.date.compareTo(b.date));
    print('Model First: ${_daysVacation.elementAt(0)?.date}');
    print('Model Last: ${_daysVacation.last?.date}');
    print('Fetch days:');
    _daysVacation.forEach((dv){
      print(dv.date);
    });  
  }

  Future<Null> fetchVacation() { // УДАЛИТЬ - нет такой сущности
    _isLoading = true;
    notifyListeners();

    return http
      .get(
          'https://plan-turista.firebaseio.com/vacations/${_authenticatedUser.vacation.id}.json?auth=${_authenticatedUser.token}')
      .then<Null>((http.Response response) {
        final Map<String, dynamic> vacationData = json.decode(response.body);
        //print(eventListData);
        if (vacationData == null) {
          _isLoading = false;
          notifyListeners();
          return;
        }
        _vacation = Vacation(
          id: _authenticatedUser.vacation.id,
          from: DateTime.parse(vacationData['from']),
          to: DateTime.parse(vacationData['to']),
          userId: vacationData['userId']
        );
        _isLoading = false;
        notifyListeners();
      }).catchError((error) {
    _isLoading = false;
    notifyListeners();
    return;
    });
  }


}

mixin EventsModel on ConnectedEventsModel {
  bool _showFavorites = false;
  String _showEventType = 'Active';

  List<Event> get allEvents {
    return List.from(_events);
  }

  String get showEventType {
    return _showEventType;
  }

  List<Event> get displayedFavoriteAndTypeEvents {
    //print('displayedFavoriteAndTypeEvents');
    List<Event> filtredEvents = List.from(_events); 
    //filtredEvents.forEach((e) => print(e.type)); 
    return filtredEvents.where((Event event) {
      //print('${event.type} == $_showEventType');
      if (_showFavorites) { 
        if (event.type == _showEventType && event.isFavorite) { return true;}
        else {return false;} 
      } else {
        if (event.type == _showEventType) { return true; }
        else { return false; }
      }
    }).toList();
  }

  int get selectedEventIndex {
    return _events.indexWhere((Event event) {
      return event.id == _selEventId;
    });
  }

  String get selectedEventId {
    return _selEventId;
  }

  Event get selectedEvent {
    if (selectedEventId == null) {
      return null;
    }
    return _events.firstWhere((Event event) {
      return event.id == _selEventId;
    });
  }

  Event selectEventById(String eventId) {
    //print('selectEventById($eventId)');
    return _events.firstWhere((Event event) {
      return event.id == eventId;
    });
  }

  bool get displayFavoritesOnly {
    return _showFavorites;
  }

  Future<Map<String, dynamic>> uploadImage(File image,
      {String imagePath}) async {
    final mimeTypeData = lookupMimeType(image.path).split('/');
    final imageUploadRequest = http.MultipartRequest(
        'POST',
        Uri.parse(
            'https://us-central1-plan-turista.cloudfunctions.net/storeImage')
    );
    final file = await http.MultipartFile.fromPath('image', image.path, contentType: MediaType(mimeTypeData[0], mimeTypeData[1]));
    imageUploadRequest.files.add(file);

    if (imagePath != null) {
      imageUploadRequest.fields['imagePath'] = Uri.encodeComponent(imagePath);
    }

    imageUploadRequest.headers['Authorization'] = 'Bearer ${_authenticatedUser.token}';

    try {
      final streamedResponse = await imageUploadRequest.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode != 200 && response.statusCode != 201) {
        print('Something went wrong');
        print(_authenticatedUser.token);
        print(json.decode(response.body));
        return null;
      }
      final responseData = json.decode(response.body);
      return responseData;
    } catch (error) {
      print(error);
      return null;
    }
  }

  Future<bool> addEvent(String title, String description, File image, String eventType, double price, LocationData locData) async {
    bool result;
    _isLoading = true;
    notifyListeners();
    final uploadData = await uploadImage(image);
    if (uploadData == null) {
      print('Upload failed');
      return false;
    }
    
    final Map<String, dynamic> eventData = {
      'title': title,
      'description': description,
      'image':
          'https://cdn.cpnscdn.com/static.coupons.com/ext/kitchme/images/recipes/600x400/old-fashioned-chocolate-fudge-recipe_17271.jpg',
      'type': eventType,    
      'price': price,
      'userEmail': _authenticatedUser.email,
      'userId': _authenticatedUser.id,
      'imagePath': uploadData['imagePath'],
      'imageUrl': uploadData['imageUrl'],
      'loc_lat': locData.latitude,
      'loc_lng': locData.longitude,
      'loc_address': locData.address
    };
    print(eventData);

    await Firestore.instance
      .collection('events')
      .add(eventData)
      .then((DocumentReference eventDoc){
        Event ev = Event.fromMap(eventData, eventDoc.documentID);
        _events.add(ev);
        _isLoading = false;
        notifyListeners();
        result = true;
      })
      .catchError((error) {
        print(error.toString());
        _isLoading = false;
        notifyListeners();
        result =  false;
      });
      return result;
  }

  Future<bool> updateEvent(String title, String description, File image, String eventType, double price, LocationData locData) async {
    bool result;
    _isLoading = true;
    notifyListeners();
    String imageUrl = selectedEvent.image;
    String imagePath = selectedEvent.image;
    if (image != null) {
      final uploadData = await uploadImage(image);
      if (uploadData == null) {
        print('Upload failed');
        return false;
      }
      imageUrl = uploadData['imageUrl'];
      imagePath = uploadData['imagePath'];
    }
    final Map<String, dynamic> eventData = {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'imagePath': imagePath,
      'type': eventType,
      'price': price,
      'loc_lat': locData.latitude,
      'loc_lng': locData.longitude,
      'loc_address': locData.address,
      'userEmail': selectedEvent.userEmail,
      'userId': selectedEvent.userId
    };
    // return ... тогда будет работать return внутри then/catchError
    await Firestore.instance
    .collection('events')
    .document(selectedEvent.id)
    .updateData(eventData)
      .then((_){
        Event ev = Event.fromMap(eventData, selectedEvent.id);
        _events[selectedEventIndex] = ev;
        _isLoading = false;
        notifyListeners();
        result = true;
      })
      .catchError((error) {
        print(error.toString());
        _isLoading = false;
        notifyListeners();
        result =  false;
      });
    return result;
  }

  Future<bool> deleteEvent() async {
    _isLoading = true;
    final deleteEventId = selectedEvent.id;
    _events.removeAt(selectedEventIndex);
    _selEventId = null;
    notifyListeners();

    return await Firestore.instance
    .collection('events')
    .document(deleteEventId)
    .delete()
      .then((_){
        _isLoading = false;
        notifyListeners();
        return true;
      })
      .catchError((error) {
        print(error.toString());
        _isLoading = false;
        notifyListeners();
        return false;
      });
  }

  Future<Null> fetchEvents({onlyForUser = false, clearExisting = false}) async {
  print('fetchEvents()');
  _isLoading = true;
  if (clearExisting) {
    _events = [];
  }    
  notifyListeners();

  final List<Event> fetchEventList = [];

  return await Firestore.instance
    .collection('events')
    .getDocuments()
      .then((QuerySnapshot snapshot) async {

        await Future.forEach(snapshot.documents, (DocumentSnapshot eventSnap) async {
          DocumentSnapshot eventData = await eventSnap.reference.get();
          //print(eventData.data.toString());
          Event event = Event.fromMap(eventData.data, eventData.documentID, _authenticatedUser.id);
          //print('${event.title}');
          fetchEventList.add(event);
        });

        _events = onlyForUser
        ? fetchEventList.where((Event event) {
            return event.userId == _authenticatedUser.id;
          }).toList()
        : fetchEventList;

        _isLoading = false;
        notifyListeners();
        _selEventId = null;
      })
      .catchError((error) {
        print(error.toString());
        _isLoading = false;
        notifyListeners();
        return false;
      });
  }

  void toggleEventFavoriteStatus(Event toggledEvent) async {
    final bool isCurrentlyFavorite = toggledEvent.isFavorite;
    final bool newFavoriteStatus = !isCurrentlyFavorite;
    List<String> wishlistUsersFinal;
    Map<String, dynamic> _date;
    final int toggledEventIndex = _events.indexWhere((Event event) {
      return event.id == toggledEvent.id;
    });
    final Event updatedEvent = Event(
        id: toggledEvent.id,
        title: toggledEvent.title,
        description: toggledEvent.description,
        type: toggledEvent.type,
        image: toggledEvent.image,
        imagePath: toggledEvent.imagePath,
        price: toggledEvent.price,
        location: toggledEvent.location,
        isFavorite: newFavoriteStatus,
        userEmail: toggledEvent.userEmail,
        userId: toggledEvent.userId);
    _events[toggledEventIndex] = updatedEvent;
    notifyListeners();

    return await Firestore.instance
    .collection('events')
    .document(toggledEvent.id)
    .get()
      .then((DocumentSnapshot eventSnap) async {

        var wishlistUsers = List.from(eventSnap.data['wishlistUsers']);
        _date = eventSnap.data;
        if(newFavoriteStatus == false) {
          wishlistUsersFinal = wishlistUsers.where((user) => user != _authenticatedUser.id);
        } else {
          wishlistUsers.add(_authenticatedUser.id);
          wishlistUsersFinal = wishlistUsers;
        }
        _date['wishlistUsers'] = wishlistUsersFinal;

        await eventSnap.reference.updateData(_date);

        _isLoading = false;
        notifyListeners();
        //return true;
      })
      .catchError((error) {
        print(error.toString());
        final Event updatedEvent = Event(
          id: toggledEvent.id,
          title: toggledEvent.title,
          description: toggledEvent.description,
          image: toggledEvent.image,
          type: toggledEvent.type,
          imagePath: toggledEvent.imagePath,
          price: toggledEvent.price,
          location: toggledEvent.location,
          isFavorite: !newFavoriteStatus,
          userEmail: toggledEvent.userEmail,
          userId: toggledEvent.userId);
      
        _events[toggledEventIndex] = updatedEvent;

        notifyListeners();
        //return false;
      });
  }

  void selectEvent(String eventId) {
    _selEventId = eventId;
    if (eventId != null) {
      notifyListeners();
    }
  }

  void toggleDisplayFavoriteMode() {
    _showFavorites = !_showFavorites;
    notifyListeners();
  }

  void toggleDisplayEventTypeMode(String newEventType) {
    _showEventType = newEventType;
    notifyListeners();
    //print(_showEventType);
  }  
}

mixin UserModel on ConnectedEventsModel {
  Timer _authTimer;
  PublishSubject<bool> _userSubject = PublishSubject();

  User get user {
    return _authenticatedUser;
  }

  PublishSubject<bool> get userSubject {
    return _userSubject;
  }

  Future<Map<String, dynamic>> authenticate(String email, String password,
      [AuthMode mode = AuthMode.Login]) async {
    _isLoading = true;
    notifyListeners();
    final Map<String, dynamic> authData = {
      'email': email,
      'password': password,
      'returnSecureToken': true,
    };
    http.Response response;
    if (mode == AuthMode.Login) {
      response = await http.post(
          'https://www.googleapis.com/identitytoolkit/v3/relyingparty/verifyPassword?key=AIzaSyBFdkEJlOvSz-add8naVkpHqToyw3N5_Oo',
          body: json.encode(authData),
          headers: {'Content-Type': 'application/json'});
    } else {
      response = await http.post(
        'https://www.googleapis.com/identitytoolkit/v3/relyingparty/signupNewUser?key=AIzaSyBFdkEJlOvSz-add8naVkpHqToyw3N5_Oo',
        body: json.encode(authData),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final Map<String, dynamic> responseData = json.decode(response.body);
    bool hasError = true;
    String message = 'Something went wrong.';
    print(responseData);
    if (responseData.containsKey('idToken')) {
      hasError = false;
      message = 'Authentification succeeded!';
      _authenticatedUser = User(
          id: responseData['localId'],
          email: email,
          token: responseData['idToken'],
          vacation: null
          );
      setAuthTimeout(int.parse(responseData['expiresIn']));
      _userSubject.add(true);
      final DateTime now = DateTime.now();
      final DateTime expiryTime =
          now.add(Duration(seconds: int.parse(responseData['expiresIn'])));
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('token', responseData['idToken']);
      prefs.setString('userEmail', email);
      prefs.setString('userId', responseData['localId']);
      prefs.setString('expiryTime', expiryTime.toIso8601String());
    } else if (responseData['error']['message'] == 'EMAIL_EXISTS') {
      message = 'This email already exists.';
    } else if (responseData['error']['message'] == 'EMAIL_NOT_FOUND') {
      message = 'This email was not found.';
    } else if (responseData['error']['message'] == 'INVALID_PASSWORD') {
      message = 'The password is invalid.';
    }
    _isLoading = false;
    notifyListeners();
    return {'success': !hasError, 'message': message};
  }

  void autoAuthenticate() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String token = prefs.get('token');
    final String expiryTimeString = prefs.get('expiryTime');
    if (token != null) {
      final DateTime now = DateTime.now();
      final parsedExpiryTime = DateTime.parse(expiryTimeString);
      if (parsedExpiryTime.isBefore(now)) {
        _authenticatedUser = null;
        notifyListeners();
        return;
      }
      final String userEmail = prefs.get('userEmail');
      final String userId = prefs.get('userId');
      final int tokenLifespan = parsedExpiryTime.difference(now).inSeconds;
      _authenticatedUser = User(id: userId, email: userEmail, token: token, vacation: null);
      _userSubject.add(true);
      setAuthTimeout(tokenLifespan);
      notifyListeners();
    }
  }

  void logout() async {
    print('Logout');
    _authenticatedUser = null;
    _authTimer.cancel();
    _userSubject.add(false);
    _selEventId = null;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('token');
    prefs.remove('userEmail');
    prefs.remove('userId');
  }

  void setAuthTimeout(int time) {
    _authTimer = Timer(Duration(seconds: time), logout);
  }
}

mixin UtilityModel on ConnectedEventsModel {
  bool get isLoading {
    return _isLoading;
  }
}
