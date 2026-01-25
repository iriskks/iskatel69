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

  // ==========================
  // 📍 ГРАНИЦЫ ВИДИМОЙ ОБЛАСТИ
  // ==========================
  LatLngBounds? _getCurrentBounds() {
    try {
      return _mapController.camera.visibleBounds;
    } catch (_) {
      return null;
    }
  }

  // ==========================
  // 🔍 ПОИСК ПО КАТЕГОРИЯМ
  // ==========================
  void searchPlaces(String query, {LatLngBounds? bounds}) {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (query.length < 2) {
        setState(() => searchResults = []);
        return;
      }

      final requestId = ++_lastRequestId;
      final mapBounds = bounds ?? _getCurrentBounds();

      String searchQuery = query;

      // Категории
      if (query == 'Магазины') searchQuery = 'магазин торговый центр тц трц mall market shop retail';
      if (query == 'Кафе') searchQuery = 'кафе ресторан кофейня бар fast food столовая';
      if (query == 'Аптеки') searchQuery = 'аптека pharmacy';
      if (query == 'Заправки') searchQuery = 'азс заправка fuel';

      String url;
      if (mapBounds != null) {
        url =
            'https://nominatim.openstreetmap.org/search'
            '?q=$searchQuery'
            '&format=json'
            '&viewbox=${mapBounds.west},${mapBounds.south},${mapBounds.east},${mapBounds.north}'
            '&bounded=1'
            '&limit=30'
            '&accept-language=ru';
      } else {
        url =
            'https://nominatim.openstreetmap.org/search'
            '?q=$searchQuery'
            '&format=json'
            '&limit=30'
            '&accept-language=ru';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'flutter-map-app'},
      );

      if (!mounted || requestId != _lastRequestId) return;

      if (response.statusCode == 200) {
        final rawResults = json.decode(response.body);

        setState(() {
          searchResults = filterPlaces(query, rawResults);
        });
      }
    });
  }

  // ==========================
  // 🔍 ГЛОБАЛЬНЫЙ ПОИСК (страны, города, поселки)
  // ==========================
  Future<void> globalSearch(String query) async {
    if (query.length < 2) {
      setState(() => searchResults = []);
      return;
    }

    final url =
        'https://nominatim.openstreetmap.org/search'
        '?q=$query'
        '&format=json'
        '&limit=10'
        '&accept-language=ru'
        '&addressdetails=1'
        '&extratags=1';

    final response = await http.get(
      Uri.parse(url),
      headers: {'User-Agent': 'flutter-map-app'},
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      setState(() {
        searchResults = json.decode(response.body);
      });
    }
  }

  // ==========================
  // 🎯 ФИЛЬТРАЦИЯ ПО КАТЕГОРИЯМ
  // ==========================
  List<dynamic> filterPlaces(String category, List<dynamic> results) {
    final q = category.toLowerCase();

    return results.where((place) {
      final type = place['type']?.toString().toLowerCase() ?? '';
      final categoryOSM = place['category']?.toString().toLowerCase() ?? '';
      final name = place['display_name']?.toString().toLowerCase() ?? '';

      if (q.contains('магаз')) {
        return categoryOSM.contains('shop') ||
            type.contains('shop') ||
            type.contains('mall') ||
            name.contains('тц') ||
            name.contains('трц') ||
            name.contains('market') ||
            name.contains('mall') ||
            name.contains('магаз');
      }

      if (q.contains('кафе')) {
        return (categoryOSM.contains('amenity') &&
                (type.contains('cafe') ||
                    type.contains('restaurant') ||
                    type.contains('bar') ||
                    type.contains('fast_food'))) ||
            name.contains('кафе') ||
            name.contains('ресторан') ||
            name.contains('coffee') ||
            name.contains('bar');
      }

      if (q.contains('аптек')) return type.contains('pharmacy') || name.contains('аптек');
      if (q.contains('азс') || q.contains('заправ')) return type.contains('fuel') || name.contains('азс');

      return true;
    }).toList();
  }

  // ==========================
  // 🎯 ВЫБОР КАТЕГОРИИ
  // ==========================
  void _handleCategorySelect(String category) {
    searchPlaces(category, bounds: _getCurrentBounds());
  }

  // ==========================
  // 📍 ПЕРЕХОД К МЕСТУ
  // ==========================
  void moveToPlace(dynamic json) {
    final place = Place.fromJson(json);

    setState(() {
      selectedPlace = place;
      searchResults = [];
      _searchController.text = place.name;
    });

    double zoom = 16;
    if (place.type == 'country') zoom = 5;
    if (place.type == 'city' || place.type == 'town') zoom = 12;

    _mapController.move(
      LatLng(place.lat, place.lon),
      zoom,
    );
  }

  // ==========================
  // 🎯 ИКОНКИ
  // ==========================
  IconData getIcon(dynamic place) {
    final type = place['type']?.toString().toLowerCase() ?? '';
    final name = place['display_name']?.toString().toLowerCase() ?? '';

    if (type.contains('shop') || name.contains('магаз')) return Icons.store;
    if (type.contains('pharmacy') || name.contains('аптек')) return Icons.local_pharmacy;
    if (type.contains('fuel') || name.contains('азс')) return Icons.local_gas_station;
    if (type.contains('cafe') || type.contains('restaurant')) return Icons.local_cafe;
    if (type == 'country') return Icons.public;
    if (type == 'city' || type == 'town') return Icons.location_city;
    if (type == 'village') return Icons.home;
    return Icons.place;
  }

  // ==========================
  // 📦 BOTTOM SHEET
  // ==========================
  void _showPlaceSheet(BuildContext context) {
    if (selectedPlace == null) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              selectedPlace!.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Тип: ${selectedPlace!.type}'),
            Text('Широта: ${selectedPlace!.lat}'),
            Text('Долгота: ${selectedPlace!.lon}'),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ==========================
  // 🧱 UI
  // ==========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Интерактивная карта'),
        actions: [
          IconButton(
            icon: Icon(isSatellite ? Icons.map : Icons.satellite),
            onPressed: () => setState(() => isSatellite = !isSatellite),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(62.0272, 129.7322),
              initialZoom: 6,
            ),
            children: [
              TileLayer(
                urlTemplate: isSatellite
                    ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              if (selectedPlace != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(selectedPlace!.lat, selectedPlace!.lon),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => _showPlaceSheet(context),
                        child: const Icon(
                          Icons.location_on,
                          size: 40,
                          color: Colors.red,
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
            onChanged: (q) {
              final lower = q.toLowerCase();
              final isCategory = ['магазины', 'кафе', 'аптеки', 'азс', 'заправка']
                  .any(lower.contains);

              if (isCategory) {
                searchPlaces(q);
              } else {
                globalSearch(q);
              }
            },
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
              _handleCategorySelect(category);
            },
          ),
        ],
      ),
    );
  }
}
