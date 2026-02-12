class Place {
  final String name;
  final double lat;
  final double lon;
  final String type;
  final String? wikipedia;

  Place({
    required this.name,
    required this.lat,
    required this.lon,
    required this.type,
    this.wikipedia,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      name: json['display_name'] ?? 'Без названия',
      lat: double.parse(json['lat']),
      lon: double.parse(json['lon']),
      type: json['type'] ?? 'unknown',
      wikipedia: json['extratags']?['wikipedia'],
    );
  }
}
