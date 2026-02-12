import 'package:flutter/material.dart';
import '../animated_buttons/animated_category_button.dart';

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
          AnimatedCategoryButton(icon: Icons.store, title: 'Магазины', onTap: () => onSelect('магазин')),
          AnimatedCategoryButton(icon: Icons.local_cafe, title: 'Кафе', onTap: () => onSelect('кафе')),
          AnimatedCategoryButton(icon: Icons.local_pharmacy, title: 'Аптеки', onTap: () => onSelect('аптека')),
          AnimatedCategoryButton(icon: Icons.local_gas_station, title: 'АЗС', onTap: () => onSelect('заправка')),
          ],
        ),
      ),
    );
  }
}