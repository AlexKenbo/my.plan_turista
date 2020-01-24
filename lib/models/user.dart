import 'package:flutter/material.dart';
import '../models/vacation.dart';

class User {
  final String id;
  final String email;
  final String token;
  final Vacation vacation;

  User({
    @required this.id, 
    @required this.email,
    @required this.token,
    @required this.vacation
    });
}
