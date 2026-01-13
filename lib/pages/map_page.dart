import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Интерактивная карта')),
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(55.751244, 37.618423),
          initialZoom: 10,
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.geo_maps_app',
          ),
        ],
      ),
    );
  }
}
