import 'dart:async';
import 'dart:convert';
import '../models/place_model.dart';

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
  Place? selectedPlace;


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
      String extraParams = '';

      // Bounded/local search removed to avoid MapController API mismatch
      // (could re-add using proper MapController bounds API if needed)

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
  void moveToPlace(dynamic placeJson) {
    final place = Place.fromJson(placeJson);

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

  Future<List<String>> loadWikiImages(String wiki) async {
    try {
      final parts = wiki.split(':');
      String lang = parts.length > 1 ? parts.first : 'en';
      String title = parts.length > 1 ? parts.sublist(1).join(':') : wiki;

      final uri = Uri.https('$lang.wikipedia.org', '/w/api.php', {
        'action': 'query',
        'format': 'json',
        'prop': 'pageimages',
        'piprop': 'original|thumbnail',
        'pithumbsize': '800',
        'titles': title,
      });

      final res = await http.get(uri);
      if (res.statusCode != 200) return [];

      final data = json.decode(res.body) as Map<String, dynamic>;
      final pages = (data['query']?['pages'] ?? {}) as Map<String, dynamic>;

      final List<String> urls = [];
      for (final page in pages.values) {
        if (page is Map<String, dynamic>) {
          if (page['original'] != null && page['original']['source'] != null) {
            urls.add(page['original']['source'] as String);
          } else if (page['thumbnail'] != null && page['thumbnail']['source'] != null) {
            urls.add(page['thumbnail']['source'] as String);
          }
        }
      }

      return urls;
    } catch (_) {
      return [];
    }
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
                // userAgentPackageName removed for compatibility with flutter_map v7
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
                      onTap: () {
                        if (selectedPlace == null) return;

                        // ⚡ Создаем Future заранее
                        final imagesFuture = selectedPlace!.wikipedia != null
                            ? loadWikiImages(selectedPlace!.wikipedia!)
                            : Future<List<String>>.value([]);

                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          builder: (context) {
                            return DraggableScrollableSheet(
                              initialChildSize: 0.35,
                              minChildSize: 0.2,
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

                                        // 🔹 Горизонтальный скролл фото
                                        FutureBuilder<List<String>>(
                                          future: imagesFuture,
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState == ConnectionState.waiting) {
                                              return const SizedBox(
                                                height: 120,
                                                child: Center(child: CircularProgressIndicator()),
                                              );
                                            }

                                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                              return const SizedBox(height: 120);
                                            }

                                            return SizedBox(
                                              height: 120, // фиксируем высоту контейнера
                                              child: ListView.separated(
                                                scrollDirection: Axis.horizontal,
                                                itemCount: snapshot.data!.length,
                                                separatorBuilder: (_, __) => const SizedBox(width: 8),
                                                itemBuilder: (context, index) {
                                                  final imageUrl = snapshot.data![index];

                                                  // ⚡ проверяем URL
                                                  print('Загружаю картинку: $imageUrl');

                                                  return ClipRRect(
                                                    borderRadius: BorderRadius.circular(12),
                                                    child: Image.network(
                                                      imageUrl,
                                                      width: 160,
                                                      height: 120,
                                                      fit: BoxFit.cover,
                                                      loadingBuilder: (context, child, progress) {
                                                        if (progress == null) return child;
                                                        return const Center(child: CircularProgressIndicator());
                                                      },
                                                      errorBuilder: (_, __, ___) {
                                                        return Container(
                                                          width: 160,
                                                          height: 120,
                                                          color: Colors.grey[300],
                                                          child: const Icon(Icons.broken_image, size: 40),
                                                        );
                                                      },
                                                    ),
                                                  );
                                                },
                                              ),
                                            );
                                          },
                                        ),


                                        const SizedBox(height: 16),
                                        Text('Тип объекта: ${selectedPlace!.type}'),
                                        Text('Широта: ${selectedPlace!.lat}'),
                                        Text('Долгота: ${selectedPlace!.lon}'),

                                        const SizedBox(height: 16),

                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            icon: const Icon(Icons.map),
                                            label: const Text('Показать на карте'),
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _mapController.move(
                                                LatLng(selectedPlace!.lat, selectedPlace!.lon),
                                                15,
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },

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
