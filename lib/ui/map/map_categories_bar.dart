import 'package:flutter/material.dart';

class MapCategoriesBar extends StatelessWidget {
  final Function(String) onSelect;

  const MapCategoriesBar({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              blurRadius: 16,
              color: Colors.black.withValues(alpha: 0.15),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _item(Icons.home, 'Дом'),
            _item(Icons.local_cafe, 'Кафе'),
            _item(Icons.store, 'Магазины'),
            _item(Icons.directions_bus, 'Транспорт'),
          ],
        ),
      ),
    );
  }

  Widget _item(IconData icon, String title) {
    return GestureDetector(
      onTap: () => onSelect(title),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
