import 'dart:math';

class GeoUtils {
  GeoUtils._();
  static const double _earthRadiusKm = 6371.0;
  static double haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return _earthRadiusKm * c;
  }

  static bool isInBoundingBox(
    double lat,
    double lon,
    double minLat,
    double minLon,
    double maxLat,
    double maxLon,
  ) {
    return lat >= minLat && lat <= maxLat && lon >= minLon && lon <= maxLon;
  }

  static Map<String, double> boundingBox(
    double centerLat,
    double centerLon,
    double radiusKm,
  ) {
    final latDelta = radiusKm / 111.32;
    final lonDelta = radiusKm / (111.32 * cos(_toRadians(centerLat)));
    return {
      'minLat': centerLat - latDelta,
      'maxLat': centerLat + latDelta,
      'minLon': centerLon - lonDelta,
      'maxLon': centerLon + lonDelta,
    };
  }

  static double _toRadians(double degrees) => degrees * pi / 180.0;

  /// Checks if a point (lat, lon) is inside a GeoJSON Polygon or MultiPolygon.
  /// The [geoJsonGeometry] should be the 'geometry' object from a GeoJSON feature,
  /// containing 'type' (Polygon or MultiPolygon) and 'coordinates'.
  static bool isPointInGeoJsonPolygon(
    double lat,
    double lon,
    Map<String, dynamic>? geoJsonGeometry,
  ) {
    if (geoJsonGeometry == null) return false;
    final type = geoJsonGeometry['type'];
    final coordinates = geoJsonGeometry['coordinates'];
    if (coordinates == null) return false;

    if (type == 'Polygon') {
      return _isPointInPolygon(lat, lon, coordinates);
    } else if (type == 'MultiPolygon') {
      for (var polygon in coordinates) {
        if (_isPointInPolygon(lat, lon, polygon)) {
          return true;
        }
      }
    }
    return false;
  }

  static bool _isPointInPolygon(double lat, double lon, List<dynamic> polygon) {
    if (polygon.isEmpty) return false;
    if (!_isPointInRing(lat, lon, polygon[0])) {
      return false;
    }
    for (int i = 1; i < polygon.length; i++) {
      if (_isPointInRing(lat, lon, polygon[i])) {
        return false;
      }
    }
    return true;
  }

  static bool _isPointInRing(double lat, double lon, List<dynamic> ring) {
    bool isInside = false;
    for (int i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      final double xi = (ring[i][0] as num).toDouble();
      final double yi = (ring[i][1] as num).toDouble();
      final double xj = (ring[j][0] as num).toDouble();
      final double yj = (ring[j][1] as num).toDouble();

      final intersect = ((yi > lat) != (yj > lat)) &&
          (lon < (xj - xi) * (lat - yi) / (yj - yi) + xi);
      if (intersect) isInside = !isInside;
    }
    return isInside;
  }
}
