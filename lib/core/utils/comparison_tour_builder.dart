import 'dart:math' as math;
import '../../domain/model/power_plant.dart';
import 'kml_utils.dart';

/// Builds a cinematic gx:Tour that flies between compared power plants.
///
/// Tour structure:
///  1. Opening shot — fly to bounding box to show connection lines
///  2. For each plant — smooth FlyTo + pause + gentle orbit
///  3. Closing shot — return to bounding box overview
class ComparisonTourBuilder {
  ComparisonTourBuilder._();

  /// Tour name used to trigger playback via `playtour=ComparisonTour`.
  static const tourName = 'ComparisonTour';

  /// Builds the complete KML tour document.
  static String build({
    required List<PowerPlant> plants,
  }) {
    if (plants.isEmpty) return '';

    final playlist = StringBuffer();

    // ── 1. Opening shot: show the entire grid ──────────────────────────
    final bbox = boundingBox(plants);
    playlist.writeln(KmlUtils.flyTo(
      lat: bbox.centerLat,
      lon: bbox.centerLon,
      altitude: 0,
      heading: 0,
      tilt: 40,
      range: bbox.range * 1.5, // zoom out sufficiently to see all plants
      duration: 3.5,
    ));
    playlist.writeln(_wait(2.0));

    // ── 2. Visit each plant ──────────────────────────────────────────────
    double currentHeading = 0.0;
    for (int i = 0; i < plants.length; i++) {
      final plant = plants[i];
      final plantRange = _plantRange(plant);

      if (i > 0) {
        // Fly directly to the next plant using bounce mode.
        playlist.writeln(KmlUtils.flyTo(
          lat: plant.latitude,
          lon: plant.longitude,
          altitude: 0,
          heading: 0.0,
          tilt: 60,
          range: plantRange,
          duration: 6.0,
          flyToMode: 'bounce',
        ));
      } else {
        // Fly to the first plant
        playlist.writeln(KmlUtils.flyTo(
          lat: plant.latitude,
          lon: plant.longitude,
          altitude: 0,
          heading: 0.0,
          tilt: 60,
          range: plantRange,
          duration: 5.0,
          flyToMode: 'bounce',
        ));
      }

      // Settle at plant to view crystal
      playlist.writeln(_wait(1.5));
      
      // Smooth half-rotation orbit (180 degrees)
      for (int step = 1; step <= 18; step++) {
        playlist.writeln(KmlUtils.flyTo(
          lat: plant.latitude,
          lon: plant.longitude,
          altitude: 0,
          heading: (step * 10).toDouble(),
          tilt: 60,
          range: plantRange,
          duration: 0.4, // 18 steps * 0.4s = 7.2 seconds for a half-rotation pan
          flyToMode: 'smooth'
        ));
      }
      
      playlist.writeln(_wait(2.0)); // Wait 2 seconds before flying to the next plant
    }

    // ── 3. Closing shot: return to overview ──────────────────────────────
    playlist.writeln(KmlUtils.flyTo(
      lat: bbox.centerLat,
      lon: bbox.centerLon,
      altitude: 0,
      heading: 0,
      tilt: 40,
      range: bbox.range,
      duration: 4.0,
    ));
    playlist.writeln(_wait(3.0));

    return '''
    <gx:Tour>
      <name>$tourName</name>
      <gx:Playlist>
${playlist.toString()}      </gx:Playlist>
    </gx:Tour>''';
  }

  /// gx:Wait element for pausing during a tour.
  static String _wait(double seconds) {
    return '''
    <gx:Wait>
      <gx:duration>$seconds</gx:duration>
    </gx:Wait>''';
  }

  /// Calculate optimal camera range for a single plant.
  static double _plantRange(PowerPlant plant) {
    // Zoom out slightly for a better overview of the 3D crystal
    double base = 1200;
    if (plant.capacityMw != null) {
      base += 30 * math.sqrt(plant.capacityMw!);
    }
    return base.clamp(1200.0, 10000.0);
  }

  /// Compute bounding box and a camera range that frames all plants.
  static BoundingBox boundingBox(List<PowerPlant> plants) {
    double minLat = 90, maxLat = -90, minLon = 180, maxLon = -180;
    for (final p in plants) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLon) minLon = p.longitude;
      if (p.longitude > maxLon) maxLon = p.longitude;
    }
    final centerLat = (minLat + maxLat) / 2;
    final centerLon = (minLon + maxLon) / 2;

    // Range based on the diagonal span of the bounding box
    final latSpan = maxLat - minLat;
    final lonSpan = maxLon - minLon;
    final spanDeg = math.sqrt(latSpan * latSpan + lonSpan * lonSpan);
    // ~111km per degree, camera range ~2x the span in meters
    final range = (spanDeg * 111000 * 2.0).clamp(10000.0, 12000000.0);

    return BoundingBox(
      centerLat: centerLat,
      centerLon: centerLon,
      range: range,
    );
  }

  /// Calculates the bearing from point 1 to point 2.
  static double _bearing(double lat1, double lon1, double lat2, double lon2) {
    final dLon = (lon2 - lon1) * math.pi / 180.0;
    final l1 = lat1 * math.pi / 180.0;
    final l2 = lat2 * math.pi / 180.0;
    final y = math.sin(dLon) * math.cos(l2);
    final x = math.cos(l1) * math.sin(l2) - math.sin(l1) * math.cos(l2) * math.cos(dLon);
    final brng = math.atan2(y, x) * 180.0 / math.pi;
    return (brng + 360) % 360;
  }

  /// Calculates the shortest angular path from current to target heading.
  static double _closestHeading(double current, double target) {
    double diff = (target - current) % 360.0;
    if (diff > 180.0) {
      diff -= 360.0;
    } else if (diff < -180.0) {
      diff += 360.0;
    }
    return current + diff;
  }
}

class BoundingBox {
  final double centerLat;
  final double centerLon;
  final double range;
  const BoundingBox({
    required this.centerLat,
    required this.centerLon,
    required this.range,
  });
}
