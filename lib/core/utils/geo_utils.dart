import 'dart:math';

/// Geospatial utility functions.
class GeoUtils {
  GeoUtils._();

  static const double _earthRadiusKm = 6371.0;

  /// Haversine distance between two points in kilometers.
  static double haversineDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return _earthRadiusKm * c;
  }

  /// Check if a point is inside a bounding box.
  static bool isInBoundingBox(
    double lat, double lon,
    double minLat, double minLon,
    double maxLat, double maxLon,
  ) {
    return lat >= minLat && lat <= maxLat && lon >= minLon && lon <= maxLon;
  }

  /// Calculate bounding box for a center point and radius (km).
  static Map<String, double> boundingBox(
    double centerLat, double centerLon, double radiusKm,
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

  /// Generate orbit coordinates around a center point.
  /// Returns list of [lat, lon, heading] for each orbit step.
  static List<List<double>> generateOrbitPath(
    double centerLat,
    double centerLon, {
    double radiusKm = 5.0,
    int steps = 36,
  }) {
    final path = <List<double>>[];
    for (int i = 0; i < steps; i++) {
      final angle = (2 * pi * i) / steps;
      final latOffset = (radiusKm / 111.32) * cos(angle);
      final lonOffset =
          (radiusKm / (111.32 * cos(_toRadians(centerLat)))) * sin(angle);
      final heading = (360.0 * i / steps);
      path.add([centerLat + latOffset, centerLon + lonOffset, heading]);
    }
    return path;
  }

  static double _toRadians(double degrees) => degrees * pi / 180.0;
}
