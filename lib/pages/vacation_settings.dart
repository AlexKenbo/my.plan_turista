import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:scoped_model/scoped_model.dart';

import '../widgets/helpers/ensure-visible.dart';
import '../widgets/ui_elements/adaptive_progress_indicated.dart';

import '../models/vacation_day.dart';

import '../scoped-models/main.dart';

enum DismissDialogAction {
  cancel,
  discard,
  save,
}

class DateTimeItem extends StatelessWidget {
  DateTimeItem({Key key, DateTime dateTime, @required this.onChanged})
      : assert(onChanged != null),
        date = DateTime(dateTime.year, dateTime.month, dateTime.day),
        time = TimeOfDay(hour: 0, minute: 0),
        super(key: key);

  final DateTime date;
  final TimeOfDay time;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return DefaultTextStyle(
      style: theme.textTheme.subhead,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              decoration: BoxDecoration(
                  border:
                      Border(bottom: BorderSide(color: theme.dividerColor))),
              child: InkWell(
                onTap: () {
                  showDatePicker(
                    //locale: const Locale('ru', null),
                    context: context,
                    initialDate: date,
                    firstDate: date.subtract(const Duration(days: 30)),
                    lastDate: date.add(const Duration(days: 30)),
                    builder: (BuildContext context, Widget child) {
                      return Theme(
                        data: ThemeData.light(),
                        child: child,
                      );
                    },
                  ).then<void>((DateTime value) {
                    if (value != null)
                      onChanged(DateTime(value.year, value.month, value.day, 
                          time.hour, time.minute));
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(DateFormat('d MMMM yyyy, EEEE', 'ru_RU').format(date), style: Theme.of(context).textTheme.title),
                    const Icon(Icons.arrow_drop_down, color: Colors.black54),
                  ],
                ),
              ),
            ),
          ),
          /*Container(
            margin: const EdgeInsets.only(left: 8.0),
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: theme.dividerColor))),
            child: InkWell(
              onTap: () {
                showTimePicker(
                  context: context,
                  initialTime: time,
                ).then<void>((TimeOfDay value) {
                  if (value != null)
                    onChanged(DateTime(date.year, date.month, date.day,
                        value.hour, value.minute));
                });
              },
              child: Row(
                children: <Widget>[
                  Text('${time.format(context)}'),
                  const Icon(Icons.arrow_drop_down, color: Colors.black54),
                ],
              ),
            ),
          ),*/
        ],
      ),
    );
  }
}

class VacationSettingsPage extends StatefulWidget {
  final List<VacationDay> listDays;

  VacationSettingsPage(this.listDays);

  @override
  VacationSettingsPageState createState() => VacationSettingsPageState();
}

class VacationSettingsPageState extends State<VacationSettingsPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final Map<String, dynamic> _formData = {
    'id': null,
    'from': null,
    'to': null,
  };

  @override
  void initState() { 
    DateTime now = DateTime.now();
    DateTime nowNullTime = DateTime(now.year, now.month, now.day, 0, 0, 0, 0, 0);
    _formData['from'] = widget.listDays == null ? nowNullTime : widget.listDays.first.date;
    _formData['to'] =  widget.listDays == null ? nowNullTime : widget.listDays.last.date;
    print('Период отпуска: ${_formData['from']} - ${_formData['to']}');    
    super.initState();
  }

  bool _saveNeeded = false;

  Future<bool> _onWillPop() async {
    if (!_saveNeeded) return true;

    final ThemeData theme = Theme.of(context);
    final TextStyle dialogTextStyle =
        theme.textTheme.subhead.copyWith(color: theme.textTheme.caption.color);

    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Text(
                'Discard new event?',
                style: dialogTextStyle,
              ),
              actions: <Widget>[
                FlatButton(
                  child: const Text('CANCEL'),
                  onPressed: () {
                    Navigator.of(context).pop(
                        false); // Pops the confirmation dialog but not the page.
                  },
                ),
                FlatButton(
                  child: const Text('DISCARD'),
                  onPressed: () {
                    Navigator.of(context).pop(
                        true); // Returning true to _onWillPop will pop again.
                  },
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _submitForm(Function addVacation, Function updateVacation, List<VacationDay> listDay) {
    if (!_formKey.currentState.validate()) {
      return;
    }
    _formKey.currentState.save();

    if (listDay == null) {
      print('Будет создана новый период отпуска');
      addVacation(
        _formData['from'],
        _formData['to'])
          .then((bool success) {
            if (success) {
            Navigator.pushReplacementNamed(context, '/vacation', result: true);
              //.then((_) => setSelectedEvent(null));
            } else {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Something went wrong'),
                  content: Text('Please try again!'),
                  actions: <Widget>[
                    FlatButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('Okay!'),
                    )
                  ],
                );
              });
        }
      });
    } else {
      updateVacation(
        _formData['from'],
        _formData['to'])
        .then((_) => Navigator.pushReplacementNamed(context, '/vacation', result: true)
            //.then((_) => setSelectedEvent(null))
        );
    } 
  }
  
  Widget _buildSubmitButton() {
    final ThemeData theme = Theme.of(context);
    return ScopedModelDescendant<MainModel>(
        builder: (BuildContext context, Widget child, MainModel model) {
      return model.isLoading
          ? Center(
              child: AdaptiveProgressIndicator(),
            )
          : RaisedButton(
              textColor: Colors.white,
              child: Text('СОХРАНИТЬ',
                style: theme.textTheme.body1.copyWith(color: Colors.white)),
              onPressed: () => _submitForm(model.addVacation, model.updateVacation,
                  widget.listDays),
            );
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Настройки календаря'),
        actions: <Widget>[
          _buildSubmitButton(),
        ],
      ),
      body: Form(
        key: _formKey,
        onWillPop: _onWillPop,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Начало отпуска', style: theme.textTheme.subhead),
                DateTimeItem(
                  dateTime: _formData['from'],
                  onChanged: (DateTime value) {
                    setState(() {
                      _formData['from'] = value;
                      _saveNeeded = true;
                    });
                  },
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Окончание отпуска', style: theme.textTheme.subhead),
                DateTimeItem(
                  dateTime: _formData['to'],
                  onChanged: (DateTime value) {
                    setState(() {
                      _formData['to'] = value;
                      _saveNeeded = true;
                    });
                  },
                ),
              ],
            ),
          ].map<Widget>((Widget child) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              height: 96.0,
              child: child,
            );
          }).toList(),
        ),
      ),
    );
  }
}
