import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:plan_turista/models/event_type.dart';

import 'package:scoped_model/scoped_model.dart';

import '../widgets/helpers/ensure-visible.dart';
import '../widgets/form_inputs/location.dart';
import '../widgets/form_inputs/image.dart';
import '../widgets/ui_elements/adaptive_progress_indicated.dart';

import '../models/event.dart';
import '../scoped-models/main.dart';
import '../models/location_data.dart';

class EventEditPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _EventEditPageState();
  }
}

class _EventEditPageState extends State<EventEditPage> {
  final Map<String, dynamic> _formData = {
    'title': null,
    'description': null,
    'type': 'Active',
    'price': null,
    'image': null,
    'location': null
  };
  

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _titleFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();
  final _priceFocusNode = FocusNode();
  final _titleTextController = TextEditingController();
  final _descriptionTextController = TextEditingController();
  final _priceTextController = TextEditingController();

  Widget _buildTitleField(Event event) {
    if (event == null && _titleTextController.text.trim() == '') {
      _titleTextController.text = '';
    } else if (event != null && _titleTextController.text.trim() == '') {
      _titleTextController.text = event.title;
    } else if (event != null && _titleTextController.text.trim() != '') {
      _titleTextController.text = _titleTextController.text;
    } else if (event == null && _titleTextController.text.trim() != '') {
      _titleTextController.text = _titleTextController.text;
    } else {
      _titleTextController.text = '';
    }
    return EnsureVisibleWhenFocused(
        focusNode: _titleFocusNode,
        child: TextFormField(
          focusNode: _titleFocusNode,
          //initialValue: event == null ? '' : event.title,
          //autovalidate: true,
          validator: (String value) {
            //if (value.trim().length <= 0){
            if (value.isEmpty || value.length < 5) {
              return 'Название должно быть длиннее 5 символов';
            }
          },
          decoration: InputDecoration(labelText: 'Название мероприятия'),
          controller: _titleTextController,
          onSaved: (String value) {
            _formData['title'] = value;
          },
        ));
  }

  Widget _buildDescriptionField(Event event) {
    if (event == null && _descriptionTextController.text.trim() == '') {
      _descriptionTextController.text = '';
    } else if (event != null && _descriptionTextController.text.trim() == '') {
      _descriptionTextController.text = event.description;
    }
    return EnsureVisibleWhenFocused(
        focusNode: _descriptionFocusNode,
        child: TextFormField(
            focusNode: _descriptionFocusNode,
            //initialValue: event == null ? '' : event.description,
            controller: _descriptionTextController,
            validator: (String value) {
              //if (value.trim().length <= 0){
              if (value.isEmpty || value.length < 10) {
                return 'Описание должно быть длинее 10 символов';
              }
            },
            maxLines: 5,
            decoration: InputDecoration(labelText: 'Описание мероприятия'),
            onSaved: (String value) {
              _formData['description'] = value;
            }));
  }

  String _eventTypeValue;
  Widget _buildSelectTypeField(Event event) { 

    if (event != null && _eventTypeValue == null) {
      _eventTypeValue = event.type;
    } else if(event == null && _eventTypeValue == null) {
      _eventTypeValue = 'Active';      
    } 
    _formData['type'] = _eventTypeValue; 
    //print('Обновлен тип 2ой раз - ${_formData['type']}');

    return EnsureVisibleWhenFocused(
      focusNode: _descriptionFocusNode,
      child: DropdownButtonFormField<String>(  
          value: _eventTypeValue,
          onChanged: (String newValue) {
            setState(() {
              _eventTypeValue = newValue;
              _formData['type'] = _eventTypeValue;
              //print('Обновлен тип 1ый раз - ${_formData['type']}');
            });
          },
          items: <Map<String,dynamic>>[
            {'name': 'Активный отдых', 'value': 'Active'}, 
            {'name': 'Экскурсии','value': 'Tour'}, 
            {'name':'SPA туризм','value': 'Spa'},  
            {'name':'Отдых с детьми','value':'Child'}]
              .map<DropdownMenuItem<String>>((Map<String,dynamic> value) {
            return DropdownMenuItem<String>(
              value: value['value'],
              child: Text(value['name']),
            );
          }).toList(),
      ),
    );
  }

  Widget _buildPriceField(Event event) {
    if (event == null && _priceTextController.text.trim() == '') {
      _priceTextController.text = '';
    } else if (event != null && _priceTextController.text.trim() == '') {
      _priceTextController.text = event.price.toString();
    }
    return EnsureVisibleWhenFocused(
        focusNode: _priceFocusNode,
        child: TextFormField(
          focusNode: _priceFocusNode,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          //initialValue: event == null ? '' : event.price.toString(),
          controller: _priceTextController,
          validator: (String value) {
            //if (value.trim().length <= 0){
            if (value.isEmpty ||
                !RegExp(r'[0-9]*([\.,][0-9]+)?').hasMatch(value)) {
              return 'Цена должна содержать число';
            }
          },
          decoration: InputDecoration(labelText: 'Цена мероприятия'),
    ));
  }

  void _setLocation(LocationData locData) {
    _formData['location'] = locData;
  }

  void _setImage(File image) {
    _formData['image'] = image;
  }

  void _submitForm(Function addEvent, Function updateEvent, Function setSelectedEvent, [int selectedEventIndex]) {
    if (!_formKey.currentState.validate() ||
        (_formData['image'] == null && selectedEventIndex == -1)) {
      return;
    }
    _formKey.currentState.save();
    if (selectedEventIndex == -1) {
      print('_submitForm() - будет отправлен ${_formData['type']}');
      addEvent(
              _titleTextController.text,
              _descriptionTextController.text,
              _formData['image'],
              _formData['type'],
              double.parse(
                  _priceTextController.text.replaceFirst(RegExp(r','), '.')),
              _formData['location'])
          .then((bool success) {
        if (success) {
          Navigator.pushReplacementNamed(context, '/')
              .then((_) => setSelectedEvent(null));
        } else {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Что-то пошло не так..'),
                  content: Text('Попробуйте сново'),
                  actions: <Widget>[
                    FlatButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Закрыть'),
                    )
                  ],
                );
              });
        }
      });
    } else {
      updateEvent(
              _titleTextController.text,
              _descriptionTextController.text,
              _formData['image'],
              _formData['type'],
              double.parse(
                  _priceTextController.text.replaceFirst(RegExp(r','), '.')),
              _formData['location'])
          .then((_) => Navigator.pushReplacementNamed(context, '/events')
              .then((_) => setSelectedEvent(null)));
    }
  }

  Widget _buildSubmitButton() {
    return ScopedModelDescendant<MainModel>(
        builder: (BuildContext context, Widget child, MainModel model) {
      return model.isLoading
          ? Center(
              child: AdaptiveProgressIndicator(),
            )
          : RaisedButton(
              textColor: Colors.white,
              child: Text('Сохранить'),
              onPressed: () => _submitForm(model.addEvent, model.updateEvent,
                  model.selectEvent, model.selectedEventIndex),
            );
    });
  }

  Widget _buildPageContent(BuildContext context, Event event) {
    final double deviceWidth = MediaQuery.of(context).size.width;
    final double targetWidth = deviceWidth > 550.0 ? 500.0 : deviceWidth * 0.95;
    final double targetPadding = deviceWidth - targetWidth;
    return GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Container(
            margin: EdgeInsets.all(10.0),
            child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: targetPadding / 2),
                  children: <Widget>[
                    _buildTitleField(event),
                    _buildDescriptionField(event),
                    _buildSelectTypeField(event),
                    _buildPriceField(event),
                    SizedBox(
                      height: 10.0,
                    ),
                    LocationInput(_setLocation, event),
                    SizedBox(
                      height: 10.0,
                    ),
                    ImageInput(_setImage, event),
                    SizedBox(
                      height: 10.0,
                    ),
                    _buildSubmitButton(),
                  ],
                ))));
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<MainModel>(
        builder: (BuildContext context, Widget child, MainModel model) {
      
      final Widget pageContent =
          _buildPageContent(context, model.selectedEvent);
      return model.selectedEventIndex == -1
          ? pageContent
          : Scaffold(
              appBar: AppBar(
                title: Text('Редактирование мероприятия'),
                elevation: Theme.of(context).platform == TargetPlatform.iOS
                    ? 0.0
                    : 0.4,
              ),
              body: pageContent,
            );
    });
  }
}
