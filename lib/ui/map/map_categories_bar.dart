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
          _item(Icons.store, 'Магазины', 'магазин'),
          _item(Icons.local_cafe, 'Кафе', 'кафе'),
          _item(Icons.local_pharmacy, 'Аптеки', 'аптека'),
          _item(Icons.local_gas_station, 'АЗС','заправка',),
          ],
        ),
      ),
    );
  }

Widget _item(IconData icon, String title, String query) {
  return GestureDetector(
    onTap: () => onSelect(query),
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