import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/routing_service.dart';
import '../ui/map/route_result_card.dart';
import '../ui/theme/themed_scaffold.dart';
import '../ui/theme/app_themes.dart';

class RouteResultsPage extends StatefulWidget {
  final LatLng start;
  final LatLng end;
  final Function(RouteInfo) onRouteSelected;

  const RouteResultsPage({
    super.key,
    required this.start,
    required this.end,
    required this.onRouteSelected,
  });

  @override
  State<RouteResultsPage> createState() => _RouteResultsPageState();
}

class _RouteResultsPageState extends State<RouteResultsPage> {
  late Future<List<RouteInfo>> _routesFuture;
  RouteInfo? _selectedRoute;

  @override
  void initState() {
    super.initState();
    _routesFuture = RoutingService.getRoutes(widget.start, widget.end);
  }

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      variant: AppThemeVariant.vibrant,
      appBar: AppBar(
        title: const Text('Маршруты'),
      ),
      body: FutureBuilder<List<RouteInfo>>(
        future: _routesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Ошибка при построении маршрута',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.directions_off, color: Colors.orange, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Маршруты не найдены',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Проверьте, что местоположения находятся внутри карты и имеют правильные координаты',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final routes = snapshot.data!;

          return Column(
            children: [
              Expanded(
                flex: 1,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(
                      (widget.start.latitude + widget.end.latitude) / 2,
                      (widget.start.longitude + widget.end.longitude) / 2,
                    ),
                    initialZoom: 12,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: widget.start,
                          child: const Icon(Icons.place, color: Colors.green, size: 40),
                        ),
                        Marker(
                          point: widget.end,
                          child: const Icon(Icons.place, color: Colors.red, size: 40),
                        ),
                      ],
                    ),
                    if (_selectedRoute != null)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _selectedRoute!.waypoints,
                            strokeWidth: 4,
                            color: AppThemes.accentFor(AppThemeVariant.vibrant),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: ListView.builder(
                  itemCount: routes.length,
                  itemBuilder: (context, index) {
                    return RouteResultCard(
                      route: routes[index],
                      onSelected: () {
                        setState(() => _selectedRoute = routes[index]);
                        widget.onRouteSelected(routes[index]);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
