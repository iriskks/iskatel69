import 'dart:convert';
import 'package:http/http.dart' as http;

/// Получаем список фото для места (в учебном проекте можно 3 одинаковых)
Future<List<String>> loadWikiImages(String wikiTag) async {
  if (wikiTag.isEmpty) return [];

  final title = wikiTag.split(':').last;
  final url = Uri.parse(
    'https://ru.wikipedia.org/api/rest_v1/page/summary/$title',
  );

  final response = await http.get(url);
  if (response.statusCode != 200) return [];

  final data = json.decode(response.body);
  String? imageUrl = data['originalimage']?['source'] ?? data['thumbnail']?['source'];

  if (imageUrl == null) return [];

  // На учебный проект: просто 3 одинаковых фото
  return [imageUrl, imageUrl, imageUrl];
}
