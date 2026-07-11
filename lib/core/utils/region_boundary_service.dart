import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'kml_utils.dart';

/// Fetches the real geographic boundary polygon for a named region/country
/// from Nominatim (OpenStreetMap, free API, no key required) and converts
/// it to a KML document ready to send to the Liquid Galaxy master screen.
///
/// Usage:
/// ```dart
/// final kml = await RegionBoundaryService.fetchBoundaryKml(
///   regionName: 'Spain',
///   displayName: 'Spain',
///   minLat: 36.0, minLon: -9.4, maxLat: 43.8, maxLon: 3.3,
/// );
/// await lgService.sendKmlToMaster(kml);
/// ```
class RegionBoundaryService {
  RegionBoundaryService._();

  static final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        // Nominatim requires a descriptive User-Agent per their usage policy.
        'User-Agent': 'EcoGridIntelligence/1.0 (liquidgalaxy@ecogrid.app)',
      },
    ),
  );

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns a KML document whose polygons trace the actual geographic boundary
  /// of [regionName] (e.g. "Spain", "China", "India").
  ///
  /// Pass [countries] (from [Region.countries]) when available — a specific
  /// country name like "Spain" returns a precise border from Nominatim, while
  /// a continent name like "Africa" does not.
  ///
  /// On any network or parse failure, returns a plain filled bounding-box
  /// rectangle so the UI always has something to show.
  static Future<String> fetchBoundaryKml({
    required String regionName,
    required double minLat,
    required double minLon,
    required double maxLat,
    required double maxLon,
    String displayName = '',
    List<String>? countries,
  }) async {
    final label = displayName.isNotEmpty ? displayName : regionName;

    // Prefer the first specific country name over a generic region/continent
    // name. Nominatim returns accurate polygons for countries but not for
    // multi-country regions like "Africa" or "Europe".
    final queryName = (countries != null && countries.isNotEmpty)
        ? countries.first
        : regionName;

    try {
      final kml = await _fetchFromNominatim(queryName, label);
      if (kml != null) return kml;
    } catch (e) {
      debugPrint('[RegionBoundary] Nominatim fetch failed for "$queryName": $e');
    }
    debugPrint('[RegionBoundary] Using bounding-box fallback for "$label"');
    return _boundingBoxKml(
      name: label,
      minLat: minLat, minLon: minLon,
      maxLat: maxLat, maxLon: maxLon,
    );
  }

  // ── Nominatim ──────────────────────────────────────────────────────────────

  static Future<String?> _fetchFromNominatim(
      String query, String label) async {
    // polygon_threshold=0.01 — simplified but still accurate at country level.
    // Higher than 0.005 to halve response size and prevent timeouts for large
    // regions like China or the USA.
    final url = 'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&polygon_geojson=1'
        '&format=json'
        '&limit=1'
        '&polygon_threshold=0.01';

    final response = await _dio.get<String>(url);
    if (response.statusCode != 200 || response.data == null) return null;

    final List<dynamic> results = jsonDecode(response.data!);
    if (results.isEmpty) return null;

    final geojson = results.first['geojson'] as Map<String, dynamic>?;
    if (geojson == null) return null;

    final type = geojson['type'] as String?;
    final coordinates = geojson['coordinates'];
    if (type == null || coordinates == null) return null;

    final buf = StringBuffer();

    if (type == 'Polygon') {
      final kml = _polygonToKml(
          coordinates as List<dynamic>, label);
      if (kml != null) buf.write(kml);
    } else if (type == 'MultiPolygon') {
      // Render all sub-polygons, largest first (by coordinate count).
      final polys = (coordinates as List<dynamic>)
          .cast<List<dynamic>>()
          .toList()
        ..sort((a, b) => _ringCoordCount(b).compareTo(_ringCoordCount(a)));
      for (final poly in polys) {
        final kml = _polygonToKml(poly, '');
        if (kml != null) buf.writeln(kml);
      }
    } else {
      return null; // Point / LineString — not useful for area fill.
    }

    if (buf.isEmpty) return null;
    return KmlUtils.wrapInKmlDocument(buf.toString(), name: label);
  }

  // ── GeoJSON → KML ─────────────────────────────────────────────────────────

  /// Converts one GeoJSON Polygon ([list of rings]) to a KML `<Placemark>`.
  /// The first ring is the outer boundary; all subsequent rings are holes.
  static String? _polygonToKml(List<dynamic> rings, String name) {
    if (rings.isEmpty) return null;

    final outerCoords =
        _ringToKmlCoords(rings[0] as List<dynamic>);
    if (outerCoords == null) return null;

    final holeParts = <String>[];
    for (int i = 1; i < rings.length; i++) {
      final hc = _ringToKmlCoords(rings[i] as List<dynamic>);
      if (hc != null) {
        holeParts.add(
          '<innerBoundaryIs>'
          '<LinearRing><coordinates>$hc</coordinates></LinearRing>'
          '</innerBoundaryIs>',
        );
      }
    }

    // EcoGrid cyan #38BDF8 → KML bbggrr = f8bd38; 80 % opacity fill = cc
    const fillColor    = 'ccf8bd38';
    const outlineColor = 'fff8bd38';

    return '''
    <Placemark>
      <name>${_escXml(name)}</name>
      <Style>
        <PolyStyle>
          <color>$fillColor</color>
          <fill>1</fill>
          <outline>1</outline>
        </PolyStyle>
        <LineStyle>
          <color>$outlineColor</color>
          <width>3</width>
        </LineStyle>
        <LabelStyle><scale>0</scale></LabelStyle>
        <IconStyle><scale>0</scale></IconStyle>
      </Style>
      <Polygon>
        <altitudeMode>clampToGround</altitudeMode>
        <outerBoundaryIs>
          <LinearRing><coordinates>$outerCoords</coordinates></LinearRing>
        </outerBoundaryIs>
        ${holeParts.join('\n        ')}
      </Polygon>
    </Placemark>''';
  }

  /// Converts a GeoJSON ring (array of [lon, lat] pairs) to a KML coordinate
  /// string ("lon,lat,0 lon,lat,0 …").
  static String? _ringToKmlCoords(List<dynamic> ring) {
    if (ring.isEmpty) return null;
    return ring.map((pt) {
      final pair = pt as List<dynamic>;
      final lon = (pair[0] as num).toDouble();
      final lat = (pair[1] as num).toDouble();
      return '$lon,$lat,0';
    }).join(' ');
  }

  /// Total coordinate points across all rings of a GeoJSON Polygon — used to
  /// sort MultiPolygon sub-polygons from largest to smallest.
  static int _ringCoordCount(List<dynamic> rings) =>
      rings.fold<int>(0,
          (sum, ring) => sum + (ring as List<dynamic>).length);

  // ── Bounding-box fallback ──────────────────────────────────────────────────

  static String _boundingBoxKml({
    required String name,
    required double minLat,
    required double minLon,
    required double maxLat,
    required double maxLon,
  }) {
    final coordStr =
        '$minLon,$minLat,0 $maxLon,$minLat,0 '
        '$maxLon,$maxLat,0 $minLon,$maxLat,0 $minLon,$minLat,0';
    final content = '''
    <Placemark>
      <name>${_escXml(name)}</name>
      <Style>
        <PolyStyle><color>00000000</color><fill>0</fill><outline>1</outline></PolyStyle>
        <LineStyle><color>fff8bd38</color><width>3</width></LineStyle>
        <LabelStyle><scale>0</scale></LabelStyle>
        <IconStyle><scale>0</scale></IconStyle>
      </Style>
      <Polygon>
        <altitudeMode>clampToGround</altitudeMode>
        <outerBoundaryIs>
          <LinearRing><coordinates>$coordStr</coordinates></LinearRing>
        </outerBoundaryIs>
      </Polygon>
    </Placemark>''';
    return KmlUtils.wrapInKmlDocument(content, name: name);
  }

  // ── XML helpers ────────────────────────────────────────────────────────────

  static String _escXml(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}
