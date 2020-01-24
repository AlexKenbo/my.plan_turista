import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';

import 'package:map_view/map_view.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart' as geoloc;

import '../helpers/ensure-visible.dart';
import '../../models/location_data.dart';
import '../../models/event.dart';

import '../../shared/global_config.dart';

class LocationInput extends StatefulWidget {
  final Function setLocation;
  final Event event;

  LocationInput(this.setLocation, this.event);

  _LocationInputState createState() => _LocationInputState();
}

class _LocationInputState extends State<LocationInput> {
  Uri _staticMapUri;
  LocationData _locationData;
  final FocusNode _addressInputFocusNode = FocusNode();
  final TextEditingController _addressInputController = TextEditingController();

  @override
  void initState() {
    _addressInputFocusNode.addListener(_updateLocation);
    if (widget.event != null) {
      _getStaticMap(widget.event.location.address, geocode: false);
    }
    super.initState();
  }

  @override
  void dispose() {
    _addressInputFocusNode.removeListener(_updateLocation);
    super.dispose();
  }

  void _getStaticMap(String address,
      {bool geocode = true, double lat, double lng}) async {
    if (address.isEmpty) {
      setState(() {
        _staticMapUri = null;
      });
      widget.setLocation(null);
      return;
    }

    if (geocode) {
      final Uri uri = Uri.https(
          'maps.googleapis.com', 'maps/api/geocode/json', {
        'address': address,
        'key': apiKey
      });
      final http.Response response = await http.get(uri);
      final decodeResponse = json.decode(response.body);
      final formattedAddress =
          decodeResponse['results'][0]['formatted_address'];
      final coords = decodeResponse['results'][0]['geometry']['location'];
      _locationData = LocationData(
          address: formattedAddress,
          latitude: coords['lat'],
          longitude: coords['lng']);
    } else if (lat == null && lng == null) {
      _locationData = widget.event.location;
    } else {
      _locationData =
          LocationData(address: address, latitude: lat, longitude: lng);
    }
    if (mounted) {
      final StaticMapProvider staticMapViewProvider =
          StaticMapProvider(apiKey);
      final Uri staticMapUri = staticMapViewProvider.getStaticUriWithMarkers([
        Marker('position', 'Позиция', _locationData.latitude,
            _locationData.longitude),
      ],
          center: Location(_locationData.latitude, _locationData.longitude),
          width: 500,
          height: 300,
          maptype: StaticMapViewType.roadmap);
      widget.setLocation(_locationData);

      setState(() {
        _addressInputController.text = _locationData.address;
        _staticMapUri = staticMapUri;
      });
    }
  }

  Future<String> _getAddress(double lat, double lng) async {
    final uri = Uri.https('maps.googleapis.com', 'maps/api/geocode/json', {
      'latlng': '${lat.toString()},${lng.toString()}',
      'key': apiKey
    });
    final http.Response response = await http.get(uri);
    final decodedResponse = json.decode(response.body);
    final formattedAddress = decodedResponse['results'][0]['formatted_address'];
    return formattedAddress;
  }

  void _getUserLocation() async {
    final location = geoloc.Location();
    
    try {
      final currentLocation = await location.getLocation();
      final address =
        await _getAddress(currentLocation.latitude, currentLocation.longitude);
      _getStaticMap(address,
        geocode: false,
        lat: currentLocation.latitude,
        lng: currentLocation.longitude);
    } catch (error) {
      showDialog(context: context, builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Не можем получить ваше местоположение'),
          content: Text('Пожалуйста введите адрес'),
          actions: <Widget>[
            FlatButton(
              child: Text('Закрыть'), 
              onPressed: () => Navigator.pop(context)
            )
          ],
        );
      });
    }
  }

  void _updateLocation() {
    if (!_addressInputFocusNode.hasFocus) {
      _getStaticMap(_addressInputController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        EnsureVisibleWhenFocused(
          focusNode: _addressInputFocusNode,
          child: TextFormField(
            focusNode: _addressInputFocusNode,
            controller: _addressInputController,
            validator: (String value) {
              if (_locationData == null || value.isEmpty) {
                return 'Адрес введен не верно.';
              }
            },
            decoration: InputDecoration(labelText: 'Адрес'),
          ),
        ),
        SizedBox(
          height: 10.0,
        ),
        FlatButton(
          child: Text('Определить мое местоположение'),
          onPressed: _getUserLocation,
        ),
        SizedBox(
          height: 10.0,
        ),
        _staticMapUri == null
            ? Container()
            : Image.network(_staticMapUri.toString())
      ],
    );
  }
}
