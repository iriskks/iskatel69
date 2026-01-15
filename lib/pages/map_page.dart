import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  // 🔧 Оптимизация
  Timer? _debounce;
  int _lastRequestId = 0;

  bool isSatellite = false;
  List<dynamic> searchResults = [];
  LatLng? selectedPoint;

  /// 🧠 Глобальный или локальный поиск
  bool isGlobalQuery(String query) {
    final lower = query.toLowerCase();

    const localKeywords = [
      'аптека',
      'магазин',
      'кафе',
      'ресторан',
      'улиц',
      'проспект',
      'дом',
      'банк',
      'школ',
      'больниц',
      'пятероч',
      'магнит',
    ];

    return !localKeywords.any((k) => lower.contains(k));
  }

  // 🔍 ПОИСК С DEBOUNCE
  void searchPlaces(String query) {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (query.length < 2) {
        if (mounted) {
          setState(() => searchResults = []);
        }
        return;
      }

      final int requestId = ++_lastRequestId;
      final bool isGlobal = isGlobalQuery(query);
      String extraParams = '';

      if (!isGlobal) {
        final bounds = _mapController.camera.visibleBounds;
        final viewBox =
            '${bounds.west},${bounds.north},${bounds.east},${bounds.south}';
        extraParams = '&bounded=1&viewbox=$viewBox';
      }

      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=$query'
        '&format=json'
        '&addressdetails=1'
        '&extratags=1'
        '&limit=8'
        '&accept-language=ru'
        '$extraParams',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'flutter_map_app'},
      );

      // ❌ устаревший ответ
      if (requestId != _lastRequestId) return;

      if (response.statusCode == 200 && mounted) {
        setState(() {
          searchResults = json.decode(response.body);
        });
      }
    });
  }

  // 📍 ПЕРЕХОД + МАРКЕР
  void moveToPlace(dynamic place) {
    final lat = double.parse(place['lat']);
    final lon = double.parse(place['lon']);

    setState(() {
      selectedPoint = LatLng(lat, lon);
      searchResults = [];
      _searchController.text = place['display_name'];
    });

    _mapController.move(selectedPoint!, 15);
  }

  // 🎯 ИКОНКИ
  IconData getIcon(dynamic place) {
    final type = place['type'];

    if (type == 'country') return Icons.flag;
    if (type == 'city' || type == 'town') return Icons.location_city;
    if (type == 'pharmacy') return Icons.local_pharmacy;
    if (type == 'supermarket' || type == 'shop') return Icons.store;
    if (type == 'house') return Icons.home;

    return Icons.place;
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
            options: const MapOptions(
              initialCenter: LatLng(55.751244, 37.618423),
              initialZoom: 5,
            ),
            children: [
              TileLayer(
                urlTemplate: isSatellite
                    ? 'https://server.arcgisonline.com/ArcGIS/rest/services/'
                        'World_Imagery/MapServer/tile/{z}/{y}/{x}'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.geo_maps_app',
              ),

              if (selectedPoint != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: selectedPoint!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // 🔍 ПОИСК
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Column(
              children: [
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: searchPlaces,
                    decoration: const InputDecoration(
                      hintText: 'Город, страна, аптека, адрес...',
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(14),
                    ),
                  ),
                ),

                if (searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final place = searchResults[index];
                        return ListTile(
                          leading: Icon(getIcon(place)),
                          title: Text(
                            place['display_name'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => moveToPlace(place),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
