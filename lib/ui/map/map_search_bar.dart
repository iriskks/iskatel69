import 'package:flutter/material.dart';

class MapSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const MapSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              blurRadius: 16,
              color: Color.fromRGBO(0, 0, 0, 0.15), // ← черный цвет с прозрачностью 15%
            )
          ],
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Поиск мест...',
            border: InputBorder.none,
            icon: Icon(Icons.search, color: Colors.blue),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close, color: Colors.grey),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  )
                : null,
          ),
        ),
      ),
    );
  }
}