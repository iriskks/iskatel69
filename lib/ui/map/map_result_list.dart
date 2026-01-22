import 'package:flutter/material.dart';

class MapResultList extends StatelessWidget {
  final List<dynamic> results;
  final IconData Function(dynamic) iconBuilder;
  final Function(dynamic) onTap;

  const MapResultList({
    super.key,
    required this.results,
    required this.iconBuilder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: results.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final place = results[index];
          return ListTile(
            leading: Icon(iconBuilder(place)),
            title: Text(
              place['display_name'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => onTap(place),
          );
        },
      ),
    );
  }
}
