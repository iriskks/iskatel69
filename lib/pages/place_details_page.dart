import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/place_model.dart';
import '../services/wiki_service.dart';

class PlaceDetailsPage extends StatelessWidget {
  final Place place;

  const PlaceDetailsPage({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Информация о месте'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              place.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // 🖼 ФОТО ИЗ WIKIPEDIA
           FutureBuilder<List<String>>(
            future: place.wikipedia != null ? loadWikiImages(place.wikipedia!) : Future.value([]),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox();

              return SizedBox(
                height: 120, // высота маленьких карточек
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: snapshot.data!.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        snapshot.data![index],
                        width: 160, // ширина маленькой карточки
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
            Text('Тип объекта: ${place.type}'),
            Text('Широта: ${place.lat}'),
            Text('Долгота: ${place.lon}'),

            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.map),
                label: const Text('Показать на карте'),
                onPressed: () {
                  Navigator.pop(context, LatLng(place.lat, place.lon));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
  