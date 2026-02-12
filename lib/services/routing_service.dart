import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteInfo {
  final double distance; // км
  final double duration; // минуты
  final String profile; // car, foot, bike
  final List<LatLng> waypoints;

  RouteInfo({
    required this.distance,
    required this.duration,
    required this.profile,
    required this.waypoints,
  });
}

class RoutingService {
  // OSRM публичный сервер - работает везде, включая РФ/СНГ
  // Не работает только если координаты слишком далеко друг от друга
  static const String _osrmBaseUrl = 'https://router.project-osrm.org/route/v1';

  // Получить маршруты для разных типов транспорта
  static Future<List<RouteInfo>> getRoutes(LatLng start, LatLng end) async {
    // Проверяем расстояние между точками (примерно)
    final distance = _approximateDistance(start, end);
    
    if (distance > 500) {
      // Если точки слишком далеко (более 500 км), это может быть ошибка
      throw Exception('Точки слишком далеко друг от друга (${distance.toStringAsFixed(0)} км). Попробуй выбрать точки ближе.');
    }

    final routes = <RouteInfo>[];

    try {
      // Car
      final carRoute = await _getRoute(start, end, 'car');
      if (carRoute != null) routes.add(carRoute);

      // Foot  
      final footRoute = await _getRoute(start, end, 'foot');
      if (footRoute != null) routes.add(footRoute);

      // Bike
      final bikeRoute = await _getRoute(start, end, 'bike');
      if (bikeRoute != null) routes.add(bikeRoute);
    } catch (e) {
      throw Exception('Не удалось получить маршруты: $e');
    }

    if (routes.isEmpty) {
      throw Exception('Маршруты между этими точками не найдены (возможно нет дороги между ними)');
    }

    return routes;
  }

  // Приблизительное расстояние между двумя точками в км (формула Хаверсина)
  static double _approximateDistance(LatLng start, LatLng end) {
    const earthRadiusKm = 6371.0;
    
    final dLat = _toRad(end.latitude - start.latitude);
    final dLon = _toRad(end.longitude - start.longitude);
    
    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_toRad(start.latitude)) *
            cos(_toRad(end.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2));
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadiusKm * c;
  }

  static double _toRad(double value) {
    return value * 3.14159265359 / 180.0;
  }

  static Future<RouteInfo?> _getRoute(LatLng start, LatLng end, String profile) async {
    try {
      final url = '$_osrmBaseUrl/$profile/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?geometries=geojson&overview=full';
      
      final response = await http
          .get(Uri.parse(url), headers: {'User-Agent': 'flutter-map-app'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        
        final code = json['code'] as String?;
        if (code != 'Ok') {
          return null; // Маршрут не найден для этого профиля
        }
        
        final routes = json['routes'] as List?;
        if (routes == null || routes.isEmpty) {
          return null;
        }

        final route = routes[0];
        final distance = (route['distance'] as num?)?.toDouble() ?? 0;
        final duration = (route['duration'] as num?)?.toDouble() ?? 0;
        
        final geometry = route['geometry'];
        final waypoints = _decodeGeometry(geometry);

        final routeInfo = RouteInfo(
          distance: distance / 1000, // convert to km
          duration: duration / 60, // convert to minutes
          profile: profile,
          waypoints: waypoints.isNotEmpty ? waypoints : [start, end], // fallback
        );
        
        // 🔍 Логирование для отладки
        print('✅ [$profile] Расстояние: ${routeInfo.distance.toStringAsFixed(1)} км, Время: ${routeInfo.duration.toStringAsFixed(0)} мин');
        
        return routeInfo;
      } else {
        return null; // Ошибка сервера - пропускаем этот профиль
      }
    } catch (e) {
      return null; // Ошибка для этого профиля - пропускаем
    }
  }

  // Decode GeoJSON coordinates to LatLng list
  static List<LatLng> _decodeGeometry(dynamic geometry) {
    if (geometry is! Map) return [];
    
    final coordinates = geometry['coordinates'] as List?;
    if (coordinates == null) return [];

    return [
      for (final coord in coordinates)
        if (coord is List && coord.length >= 2)
          LatLng((coord[1] as num).toDouble(), (coord[0] as num).toDouble())
    ];
  }
}
