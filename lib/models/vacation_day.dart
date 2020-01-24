import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VacationDay {
  final String id;
  final DateTime date;
  final String userId;
  final bool visible;

  VacationDay({
  @required this.id,
  @required this.date,
  @required this.userId,
  @required this.visible,
  });

  VacationDay.fromMap(Map<String, dynamic> data, String id)
  : this(
    id: id,
    date: data['date'] is Timestamp ? (data['date'] as Timestamp).toDate() : data['date'],
    userId: data['userId'],
    visible: data['visible']
  );
}