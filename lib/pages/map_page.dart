import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

import '../models/place_model.dart';
import '../ui/map/map_search_bar.dart';
import '../ui/map/map_categories_bar.dart';
import '../ui/map/map_result_list.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  Timer? _debounce;
  int _lastRequestId = 0;

  bool isSatellite = false;
  List<dynamic> searchResults = [];
  Place? selectedPlace;

  // 🔍 ПОИСК
  void searchPlaces(String query) {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (query.length < 2) {
        setState(() => searchResults = []);
        return;
      }

      final requestId = ++_lastRequestId;

      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=$query'
        '&format=json'
        '&addressdetails=1'
        '&limit=8'
        '&accept-language=ru',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'flutter_map_app'},
      );

      if (requestId != _lastRequestId) return;

      if (response.statusCode == 200 && mounted) {
        setState(() {
          searchResults = json.decode(response.body);
        });
      }
    });
  }

  // 📍 ПЕРЕХОД К МЕСТУ
  void moveToPlace(dynamic json) {
    final place = Place.fromJson(json);

    setState(() {
      selectedPlace = place;
      searchResults = [];
      _searchController.text = place.name;
    });

    _mapController.move(
      LatLng(place.lat, place.lon),
      15,
    );
  }

  // 🎯 ИКОНКИ
  IconData getIcon(dynamic place) {
    switch (place['type']) {
      case 'city':
      case 'town':
        return Icons.location_city;
      case 'pharmacy':
        return Icons.local_pharmacy;
      case 'shop':
      case 'supermarket':
        return Icons.store;
      case 'house':
        return Icons.home;
      default:
        return Icons.place;
    }
  }

  // 📦 BOTTOM SHEET
  void _showPlaceSheet(BuildContext context) {
    if (selectedPlace == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.35,
          maxChildSize: 0.8,
          expand: false,
          builder: (_, controller) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                controller: controller,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedPlace!.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Тип: ${selectedPlace!.type}'),
                    Text('Широта: ${selectedPlace!.lat}'),
                    Text('Долгота: ${selectedPlace!.lon}'),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Интерактивная карта'),
        actions: [
          IconButton(
            icon: Icon(isSatellite ? Icons.map : Icons.satellite),
            onPressed: () {
              setState(() => isSatellite = !isSatellite);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 🗺 КАРТА
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(55.751244, 37.618423),
              initialZoom: 5,
            ),
            children: [
              TileLayer(
                urlTemplate: isSatellite
                    ? 'https://server.arcgisonline.com/ArcGIS/rest/services/'
                        'World_Imagery/MapServer/tile/{z}/{y}/{x}'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),

              if (selectedPlace != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(
                        selectedPlace!.lat,
                        selectedPlace!.lon,
                      ),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => _showPlaceSheet(context),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // 🔍 ПОИСК
          MapSearchBar(
            controller: _searchController,
            onChanged: searchPlaces,
          ),

          // 📜 РЕЗУЛЬТАТЫ
          if (searchResults.isNotEmpty)
            Positioned(
              top: 90,
              left: 0,
              right: 0,
              child: MapResultList(
                results: searchResults,
                iconBuilder: getIcon,
                onTap: moveToPlace,
              ),
            ),

          // 🎯 КАТЕГОРИИ
          MapCategoriesBar(
            onSelect: (category) {
              searchPlaces(category);
            },
          ),
        ],
      ),
    );
  }
}
