import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

class SingleMapPage extends StatelessWidget {
  final double _lat;
  final double _lng;
  final String _title;

  SingleMapPage(this._lat, this._lng, this._title);

  @override
  Widget build(BuildContext context) {
    var markers = <Marker>[
      Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(_lat, _lng),
        builder: (ctx) => Container(
              child: Image.asset('assets/pin.png'),
            ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text('Карта')),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text(_title),
            ),
            Flexible(
              child: FlutterMap(
                options: MapOptions(
                  center: LatLng(_lat, _lng),
                  zoom: 15.0,
                ),
                layers: [
                  TileLayerOptions(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: ['a', 'b', 'c']),
                  MarkerLayerOptions(markers: markers)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
