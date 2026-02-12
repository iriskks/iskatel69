import 'package:flutter/material.dart';
import '../../services/routing_service.dart';
import '../../ui/theme/app_themes.dart';

class RouteResultCard extends StatelessWidget {
  final RouteInfo route;
  final VoidCallback onSelected;

  const RouteResultCard({super.key, required this.route, required this.onSelected});

  String _getTransportName() {
    switch (route.profile) {
      case 'car':
        return 'Автомобиль';
      case 'foot':
        return 'Пешком';
      case 'bike':
        return 'Велосипед';
      default:
        return route.profile;
    }
  }

  IconData _getTransportIcon() {
    switch (route.profile) {
      case 'car':
        return Icons.directions_car;
      case 'foot':
        return Icons.directions_walk;
      case 'bike':
        return Icons.directions_bike;
      default:
        return Icons.directions;
    }
  }

  Color _getAccentColor() {
    return AppThemes.accentFor(AppThemeVariant.vibrant);
  }

  @override
  Widget build(BuildContext context) {
    final hours = (route.duration / 60).floor();
    final minutes = (route.duration % 60).floor();
    final timeStr = hours > 0 ? '$hours ч $minutes м' : '$minutes м';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getAccentColor().withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_getTransportIcon(), color: _getAccentColor()),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTransportName(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('${route.distance.toStringAsFixed(1)} км', style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 16),
                        Text(timeStr, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: _getAccentColor()),
            ],
          ),
        ),
      ),
    );
  }
}
