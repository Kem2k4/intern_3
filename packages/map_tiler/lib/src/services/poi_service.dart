import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Service for fetching Points of Interest (POI) from OpenStreetMap using Overpass API
class PoiService {
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';

  /// Fetch restaurants and cafes near a location
  Future<List<Poi>> fetchNearbyPois(LatLng center, double radiusKm) async {
    final bbox = _calculateBoundingBox(center, radiusKm);
    final query = '''
[out:json][timeout:25];
(
  node["amenity"="restaurant"]$bbox;
  node["amenity"="cafe"]$bbox;
  node["amenity"="bar"]$bbox;
  node["amenity"="fast_food"]$bbox;
);
out body;
''';

    try {
      final response = await http.post(
        Uri.parse(_overpassUrl),
        body: query,
        headers: {'Content-Type': 'text/plain'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final pois = <Poi>[];

        for (final element in data['elements']) {
          if (element['type'] == 'node' && element.containsKey('lat') && element.containsKey('lon')) {
            final tags = element['tags'] ?? {};
            final name = tags['name'] ?? 'Unknown';
            final amenity = tags['amenity'] ?? 'poi';

            pois.add(Poi(
              id: element['id'].toString(),
              name: name,
              position: LatLng(element['lat'], element['lon']),
              type: amenity,
            ));
          }
        }

        return pois;
      } else {
        throw Exception('Failed to fetch POIs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching POIs: $e');
    }
  }

  /// Calculate bounding box for Overpass query
  String _calculateBoundingBox(LatLng center, double radiusKm) {
    const double earthRadius = 6371; // Earth's radius in km
    final latRadian = center.latitude * (3.141592653589793 / 180);
    final lonRadian = center.longitude * (3.141592653589793 / 180);

    final radiusRadian = radiusKm / earthRadius;

    final minLat = (latRadian - radiusRadian) * (180 / 3.141592653589793);
    final maxLat = (latRadian + radiusRadian) * (180 / 3.141592653589793);
    final minLon = (lonRadian - radiusRadian / cos(latRadian)) * (180 / 3.141592653589793);
    final maxLon = (lonRadian + radiusRadian / cos(latRadian)) * (180 / 3.141592653589793);

    return '($minLat,$minLon,$maxLat,$maxLon)';
  }
}

/// Point of Interest model
class Poi {
  final String id;
  final String name;
  final LatLng position;
  final String type;

  const Poi({
    required this.id,
    required this.name,
    required this.position,
    required this.type,
  });

  @override
  String toString() => 'Poi(id: $id, name: $name, type: $type)';
}