import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../ui/notifications/notification_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

import '../models/place_model.dart';
import '../ui/map/map_search_bar.dart';
import '../ui/map/map_categories_bar.dart';
import '../ui/map/map_result_list.dart';
import '../ui/map/animated_marker.dart';
import '../ui/map/route_input_dialog.dart';
import 'login_page.dart';
import '../services/auth_service.dart';
import '../services/routing_service.dart';
import '../ui/theme/themed_scaffold.dart';
import '../ui/theme/app_themes.dart';
import 'route_results_page.dart';

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
  
  // Состояние маршрутов - показываем прямо на карте
  List<RouteInfo>? _availableRoutes;
  RouteInfo? _selectedRoute;
  LatLng? _routeStart;
  LatLng? _routeEnd;
  bool _loadingRoute = false;

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
  // 🔍 МАСШТАБИРОВАНИЕ
  // ==========================
  void _zoomIn() {
    final zoom = _mapController.camera.zoom + 1;
    _mapController.move(_mapController.camera.center, zoom);
  }

  void _zoomOut() {
    final zoom = (_mapController.camera.zoom - 1).clamp(1.0, 18.0);
    _mapController.move(_mapController.camera.center, zoom);
  }

  // ==========================
  // 📍 ГЕОЛОКАЦИЯ
  // ==========================
  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final newPermission = await Geolocator.requestPermission();
        if (newPermission != LocationPermission.whileInUse && newPermission != LocationPermission.always) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Разрешение на геолокацию не дано')));
          return;
        }
      }
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (!mounted) return;
      _mapController.move(LatLng(position.latitude, position.longitude), 16);
      NotificationService.instance.show(context, title: 'Местоположение', subtitle: 'Найдено: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}', duration: const Duration(seconds: 2));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  // ==========================
  // 🛣️ МАРШРУТЫ
  // ==========================
  void _openRouteDialog() {
    showDialog(
      context: context,
      builder: (_) => RouteInputDialog(
        currentCenter: _mapController.camera.center,
        onRouteSubmit: (start, end) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RouteResultsPage(
                start: start,
                end: end,
                onRouteSelected: (route) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Маршрут выбран: ${route.distance.toStringAsFixed(1)} км'),
                  ));
                },
              ),
            ),
          );
        },
      ),
    );
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
    final name = place.name;
    _searchController.value = TextEditingValue(
      text: name,
      selection: TextSelection.collapsed(offset: name.length),
    );

    setState(() {
      selectedPlace = place;
      searchResults = [];
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
            const SizedBox(height: 6),
            Text('Координаты: ${selectedPlace!.lat.toStringAsFixed(6)}, ${selectedPlace!.lon.toStringAsFixed(6)}'),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: '${selectedPlace!.lat},${selectedPlace!.lon}'));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Координаты скопированы')));
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Копировать координаты'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    _mapController.move(LatLng(selectedPlace!.lat, selectedPlace!.lon), 16);
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.center_focus_strong),
                  label: const Text('Центрировать'),
                ),
              ],
            ),
            if (selectedPlace!.wikipedia != null) ...[
              const SizedBox(height: 12),
              Text('Wikipedia: ${selectedPlace!.wikipedia}'),
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: selectedPlace!.wikipedia!));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ссылка Wikipedia скопирована')));
                },
                child: const Text('Копировать ссылку Wikipedia'),
              )
            ]
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
    return ThemedScaffold(
      variant: AppThemeVariant.vibrant,
      appBar: AppBar(
        title: const Text('Интерактивная карта'),
        actions: [
          IconButton(
            icon: Icon(isSatellite ? Icons.map : Icons.satellite),
            onPressed: () => setState(() => isSatellite = !isSatellite),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
            onPressed: () async {
              await AuthService().logout();
              if (!context.mounted) return;
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
            },
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
                      child: SizedBox(
                          width: 40,
                          height: 40,
                          child: AnimatedMarker(
                            child: const Icon(
                              Icons.location_on,
                              size: 40,
                              color: Colors.red,
                            ),
                            onTap: () => _showPlaceSheet(context),
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
              // show a quick in-app notification (non-intrusive)
              NotificationService.instance.show(context, title: 'Поиск', subtitle: 'Ищем: ${_readableCategory(category)}', duration: const Duration(seconds: 2));
              _handleCategorySelect(category);
            },
          ),

          // 🔍 ZOOM И ГЕОЛОКАЦИЯ
          Positioned(
            right: 16,
            bottom: 200,
            child: Column(
              children: [
                FloatingActionButton(
                  mini: true,
                  onPressed: _zoomIn,
                  tooltip: 'Увеличить',
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: _zoomOut,
                  tooltip: 'Уменьшить',
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: _getCurrentLocation,
                  tooltip: 'Мое местоположение',
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: _openRouteDialog,
                  tooltip: 'Маршрут',
                  child: const Icon(Icons.directions),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _readableCategory(String q) {
  switch (q) {
    case 'магазин':
      return 'Магазины';
    case 'кафе':
      return 'Кафе';
    case 'аптека':
      return 'Аптеки';
    case 'заправка':
      return 'АЗС';
    default:
      return q;
  }
}
