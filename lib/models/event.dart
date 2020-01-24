import 'package:flutter/material.dart';

import './location_data.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final double price;
  final String image;
  final String imagePath;
  final bool isFavorite;
  final String userEmail;
  final String userId;
  final LocationData location;
  final String type;


  Event({
    @required this.id,
    @required this.title, 
    @required this.description, 
    @required this.price,
    @required this.image,
    @required this.imagePath,
    @required this.userEmail,
    @required this.userId,
    this.isFavorite = false,
    @required this.location,
    @required this.type,
  });

  Event.fromMap(Map<String, dynamic> data, String id, [String currentUserId = ''])
  : this(
    id: id,
    title: data['title'],
    description: data['description'],
    price: data['price'] as double,
    image: data['imageUrl'],
    imagePath: data['imagePath'],
    isFavorite: data['wishlistUsers'] == null
              ? false
              : (data['wishlistUsers'] as Map<String, dynamic>).containsKey(currentUserId),    
    userEmail: data['userEmail'],
    userId: data['userId'],        
    location: LocationData(address: data['loc_address'], latitude: data['loc_lat'], longitude: data['loc_lng']),
    type: data['type']
  );
}