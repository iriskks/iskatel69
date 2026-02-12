import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RouteInputDialog extends StatefulWidget {
  final Function(LatLng start, LatLng end) onRouteSubmit;
  final LatLng currentCenter;

  const RouteInputDialog({super.key, required this.onRouteSubmit, required this.currentCenter});

  @override
  State<RouteInputDialog> createState() => _RouteInputDialogState();
}

class _RouteInputDialogState extends State<RouteInputDialog> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();

  LatLng? _fromLocation;
  LatLng? _toLocation;
  
  List<dynamic> _fromSuggestions = [];
  List<dynamic> _toSuggestions = [];
  bool _searchingFrom = false;
  bool _searchingTo = false;

  @override
  void initState() {
    super.initState();
    _fromLocation = widget.currentCenter;
    _fromController.text = 'Текущее место (${widget.currentCenter.latitude.toStringAsFixed(4)}, ${widget.currentCenter.longitude.toStringAsFixed(4)})';
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  Future<void> _searchPlaces(String query, bool isFrom) async {
    if (query.isEmpty) return;

    // Начинаем поиск
    if (isFrom) {
      setState(() => _searchingFrom = true);
    } else {
      setState(() => _searchingTo = true);
    }

    try {
      final url = 'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=10&accept-language=ru';
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'flutter-map-app'},
      );

      if (response.statusCode == 200) {
        final results = jsonDecode(response.body) as List;
        setState(() {
          if (isFrom) {
            _fromSuggestions = results;
            _searchingFrom = results.isNotEmpty; // Показываем suggestions только если они есть
          } else {
            _toSuggestions = results;
            _searchingTo = results.isNotEmpty; // Показываем suggestions только если они есть
          }
        });
      } else {
        // Ошибка при поиске
        setState(() {
          if (isFrom) {
            _fromSuggestions = [];
            _searchingFrom = false;
          } else {
            _toSuggestions = [];
            _searchingTo = false;
          }
        });
      }
    } catch (e) {
      // Ошибка при подключении
      setState(() {
        if (isFrom) {
          _fromSuggestions = [];
          _searchingFrom = false;
        } else {
          _toSuggestions = [];
          _searchingTo = false;
        }
      });
    }
  }

  void _selectPlace(dynamic place, bool isFrom) {
    try {
      // Безопасное преобразование координат (могут быть как string так и number)
      final lat = place['lat'] is String ? double.parse(place['lat']) : (place['lat'] as num).toDouble();
      final lon = place['lon'] is String ? double.parse(place['lon']) : (place['lon'] as num).toDouble();
      final name = place['display_name'] as String? ?? 'Неизвестное место';

      final newLocation = LatLng(lat, lon);

      if (isFrom) {
        _fromLocation = newLocation;
        _fromController.text = name;
        _fromSuggestions = [];
        _searchingFrom = false;
      } else {
        _toLocation = newLocation;
        _toController.text = name;
        _toSuggestions = [];
        _searchingTo = false;
      }
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при выборе места: ${e.toString()}')),
      );
    }
  }

  void _submit() {
    if (_fromLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите место отправления')),
      );
      return;
    }
    if (_toLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите место назначения')),
      );
      return;
    }
    Navigator.of(context).pop();
    widget.onRouteSubmit(_fromLocation!, _toLocation!);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Построить маршрут',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // От куда
              TextField(
                controller: _fromController,
                decoration: InputDecoration(
                  labelText: 'От куда',
                  hintText: 'Адрес или место',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.location_on),
                  suffixIcon: _searchingFrom ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2))) : null,
                ),
                onChanged: (val) {
                  if (val.length > 2) {
                    _searchPlaces(val, true);
                  } else {
                    setState(() {
                      _fromSuggestions = [];
                      _searchingFrom = false;
                    });
                  }
                },
              ),
              if (_searchingFrom && _fromSuggestions.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _fromSuggestions.length,
                    itemBuilder: (context, index) {
                      final place = _fromSuggestions[index];
                      return ListTile(
                        dense: true,
                        title: Text(place['display_name'], maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () => _selectPlace(place, true),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              // Куда
              TextField(
                controller: _toController,
                decoration: InputDecoration(
                  labelText: 'Куда',
                  hintText: 'Адрес или место',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  suffixIcon: _searchingTo ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2))) : null,
                ),
                onChanged: (val) {
                  if (val.length > 2) {
                    _searchPlaces(val, false);
                  } else {
                    setState(() {
                      _toSuggestions = [];
                      _searchingTo = false;
                    });
                  }
                },
              ),
              if (_searchingTo && _toSuggestions.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _toSuggestions.length,
                    itemBuilder: (context, index) {
                      final place = _toSuggestions[index];
                      return ListTile(
                        dense: true,
                        title: Text(place['display_name'], maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () => _selectPlace(place, false),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: Navigator.of(context).pop,
                    child: const Text('Отмена'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Построить маршрут'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
