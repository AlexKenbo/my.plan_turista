import 'package:flutter/material.dart';

import './vacation_day.dart';

class Vacation {
  final String id;
  final String userId;
  final DateTime from;
  final DateTime to;
  final List<VacationDay> days;
  
  const Vacation({
    @required this.id, 
    @required this.userId,
    @required this.from,
    @required this.to,
    @required this.days
  });
  
  Vacation.fromMap(Map<String, dynamic> data, String id)
    : this(
      id: id,
      userId: data['userId'],
      from: data['from'],
      to: data['from'],   
      days: List<VacationDay>.from(data['days']),
    );
}