import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../domain/model/region.dart';
import 'kml_utils.dart';

/// Fetches the real geographic boundary polygon for a named region/country
/// from Nominatim (OpenStreetMap, free API, no key required) and converts
/// it to a **3D extruded** KML document ready to send to the Liquid Galaxy
/// master screen.
///
/// The polygon rises from the terrain as a translucent glowing wall, making
/// it visually stunning on large Liquid Galaxy multi-screen setups.
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

  /// Extrusion height in metres — tall enough to be visually dramatic on
  /// Liquid Galaxy big screens at country-level zoom.
  static const double _extrusionHeight = 75000;

  static DateTime _lastNominatimRequest = DateTime.fromMillisecondsSinceEpoch(0);

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns a **3D extruded** KML document whose polygons trace the actual
  /// geographic boundary of [regionName] (e.g. "Spain", "China", "India").
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
    Map<String, dynamic>? preFetchedGeoJson,
  }) async {
    final label = displayName.isNotEmpty ? displayName : regionName;

    // Prefer the first specific country name over a generic region/continent
    // name. Nominatim returns accurate polygons for countries but not for
    // multi-country regions like "Africa" or "Europe".
    final queryName = (countries != null && countries.isNotEmpty)
        ? countries.first
        : regionName;

    try {
      if (preFetchedGeoJson != null) {
        final kml = _buildKmlFromGeoJson(
          preFetchedGeoJson,
          label,
          centerLat: (minLat + maxLat) / 2,
          centerLon: (minLon + maxLon) / 2,
          latSpan: maxLat - minLat,
          lonSpan: maxLon - minLon,
        );
        if (kml != null) return kml;
      }

      final kml = await _fetchFromNominatim(
        queryName,
        label,
        centerLat: (minLat + maxLat) / 2,
        centerLon: (minLon + maxLon) / 2,
        latSpan: maxLat - minLat,
        lonSpan: maxLon - minLon,
      );
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

  static CancelToken? _nominatimCancelToken;

  /// Searches Nominatim for regions matching the query and returns them as
  /// Region objects. Respects the 1 request/sec limit.
  static Future<List<Region>> searchGlobalRegions(String query) async {
    _nominatimCancelToken?.cancel('New search initiated');
    final currentToken = CancelToken();
    _nominatimCancelToken = currentToken;

    final now = DateTime.now();
    final diff = now.difference(_lastNominatimRequest);
    if (diff.inMilliseconds < 1000) {
      await Future.delayed(Duration(milliseconds: 1000 - diff.inMilliseconds));
      if (currentToken.isCancelled) return [];
    }
    _lastNominatimRequest = DateTime.now();

    final url = 'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json'
        '&polygon_geojson=1'
        '&limit=5'
        '&polygon_threshold=0.01';

    try {
      final response = await _dio.get(
        url,
        cancelToken: currentToken,
      );
      if (response.statusCode != 200 || response.data == null) return [];

      List<Region> parseNominatimResponse(List<dynamic> results) {
        final parsedRegions = <Region>[];
        for (final r in results) {
          final result = r as Map<String, dynamic>;
          final String displayName = result['display_name'] ?? result['name'] ?? '';
          final List<dynamic>? boundingBox = result['boundingbox'];
          final geojson = result['geojson'] as Map<String, dynamic>?;
          final String placeClass = result['class'] ?? '';
          
          if (placeClass != 'boundary' && placeClass != 'place') continue;
          if (boundingBox != null && boundingBox.length == 4) {
            final minLat = double.tryParse(boundingBox[0].toString()) ?? 0;
            final maxLat = double.tryParse(boundingBox[1].toString()) ?? 0;
            final minLon = double.tryParse(boundingBox[2].toString()) ?? 0;
            final maxLon = double.tryParse(boundingBox[3].toString()) ?? 0;
            final lat = double.tryParse(result['lat'].toString()) ?? ((minLat + maxLat) / 2);
            final lon = double.tryParse(result['lon'].toString()) ?? ((minLon + maxLon) / 2);
            final name = result['name'] ?? displayName.split(',').first;
            parsedRegions.add(Region(
              id: 'global_${result['place_id']}',
              name: name,
              displayName: displayName,
              centerLat: lat,
              centerLon: lon,
              minLat: minLat,
              minLon: minLon,
              maxLat: maxLat,
              maxLon: maxLon,
              geoJson: geojson,
              nominatimQuery: displayName,
            ));
          }
        }
        return parsedRegions;
      }

      var results = response.data is String
          ? jsonDecode(response.data as String)
          : response.data as List<dynamic>;
      var regions = parseNominatimResponse(results);

      // --- Fuzzy Fallback via Photon API ---
      if (regions.isEmpty && !currentToken.isCancelled) {
        final photonUrl = 'https://photon.komoot.io/api/?q=${Uri.encodeComponent(query)}&limit=3';
        final photonResponse = await _dio.get(photonUrl, cancelToken: currentToken);
        
        if (photonResponse.statusCode == 200 && photonResponse.data != null) {
          final pData = photonResponse.data is String ? jsonDecode(photonResponse.data as String) : photonResponse.data;
          final features = pData['features'] as List<dynamic>? ?? [];
          
          if (features.isNotEmpty) {
            final osmIds = <String>[];
            for (final f in features) {
              final props = f['properties'];
              if (props == null) continue;
              final osmType = props['osm_type']?.toString().toUpperCase(); // R, W, N
              final osmId = props['osm_id'];
              if (osmType != null && osmId != null && (osmType == 'R' || osmType == 'W' || osmType == 'N')) {
                osmIds.add('$osmType$osmId');
              }
            }
            
            if (osmIds.isNotEmpty && !currentToken.isCancelled) {
              final lookupUrl = 'https://nominatim.openstreetmap.org/lookup?osm_ids=${osmIds.join(',')}&format=json&polygon_geojson=1';
              
              final now2 = DateTime.now();
              final diff2 = now2.difference(_lastNominatimRequest);
              if (diff2.inMilliseconds < 1000) {
                await Future.delayed(Duration(milliseconds: 1000 - diff2.inMilliseconds));
                if (currentToken.isCancelled) return [];
              }
              _lastNominatimRequest = DateTime.now();
              
              final lookupResponse = await _dio.get(lookupUrl, cancelToken: currentToken);
              if (lookupResponse.statusCode == 200 && lookupResponse.data != null) {
                final lResults = lookupResponse.data is String
                    ? jsonDecode(lookupResponse.data as String)
                    : lookupResponse.data as List<dynamic>;
                regions = parseNominatimResponse(lResults);
              }
            }
          }
        }
      }

      return regions;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        return [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<String?> _fetchFromNominatim(
    String query,
    String label, {
    required double centerLat,
    required double centerLon,
    required double latSpan,
    required double lonSpan,
  }) async {
    final now = DateTime.now();
    final diff = now.difference(_lastNominatimRequest);
    if (diff.inMilliseconds < 1000) {
      await Future.delayed(Duration(milliseconds: 1000 - diff.inMilliseconds));
    }
    _lastNominatimRequest = DateTime.now();

    final url = 'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&polygon_geojson=1'
        '&format=json'
        '&limit=1'
        '&polygon_threshold=0.01';

    try {
      final response = await _dio.get(url);
      if (response.statusCode != 200 || response.data == null) return null;

      final List<dynamic> results = response.data is String
          ? jsonDecode(response.data as String)
          : response.data as List<dynamic>;
      if (results.isEmpty) return null;

      final firstResult = results.first as Map<String, dynamic>;
      final geojson = firstResult['geojson'] as Map<String, dynamic>?;
      if (geojson == null) return null;

      return _buildKmlFromGeoJson(
        geojson,
        label,
        centerLat: centerLat,
        centerLon: centerLon,
        latSpan: latSpan,
        lonSpan: lonSpan,
      );
    } catch (e) {
      debugPrint('[RegionBoundary] Nominatim error: $e');
      return null;
    }
  }

  static String? _buildKmlFromGeoJson(
    Map<String, dynamic> geojson,
    String label, {
    required double centerLat,
    required double centerLon,
    required double latSpan,
    required double lonSpan,
  }) {
    final type = geojson['type'] as String?;
    final coordinates = geojson['coordinates'];
    if (type == null || coordinates == null) return null;

    final buf = StringBuffer();

    // ── Shared style definitions ──────────────────────────────────────────
    buf.writeln(_sharedStyles());

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

    // ── Compute camera range from region span ────────────────────────────
    final maxSpan = latSpan > lonSpan ? latSpan : lonSpan;
    double camRange = maxSpan * 111000.0 * 1.4;
    if (camRange < 400000) camRange = 400000;
    if (camRange > 12000000) camRange = 12000000;

    // ── Embed LookAt camera in the document ──────────────────────────────
    final lookAt = KmlUtils.lookAt(
      lat: centerLat,
      lon: centerLon,
      altitude: 0,
      heading: 0,
      tilt: 55,
      range: camRange,
    );
    buf.writeln(lookAt);

    return KmlUtils.wrapInKmlDocument(buf.toString(), name: label);
  }

  // ── Shared KML styles ─────────────────────────────────────────────────────

  /// Reusable style definitions for the 3D extruded region polygon.
  /// EcoGrid cyan #38BDF8 → KML bbggrr = f8bd38
  /// Fill: 0xa0 = ~63% opacity — semi-transparent, shows terrain through walls
  /// Outline: 0xff = fully opaque, thick glowing border for large screens
  static String _sharedStyles() {
    return '''
    <Style id="ecogrid_region_fill">
      <PolyStyle>
        <color>a0f8bd38</color>
        <fill>1</fill>
        <outline>1</outline>
      </PolyStyle>
      <LineStyle>
        <color>fff8bd38</color>
        <width>4</width>
      </LineStyle>
      <LabelStyle><scale>0</scale></LabelStyle>
      <IconStyle><scale>0</scale></IconStyle>
    </Style>
    <Style id="ecogrid_region_glow">
      <PolyStyle>
        <color>a0f8bd38</color>
        <fill>1</fill>
        <outline>1</outline>
      </PolyStyle>
      <LineStyle>
        <color>5affffff</color>
        <width>6</width>
      </LineStyle>
      <LabelStyle><scale>0</scale></LabelStyle>
      <IconStyle><scale>0</scale></IconStyle>
    </Style>''';
  }

  // ── GeoJSON → 3D KML ──────────────────────────────────────────────────────

  /// Converts one GeoJSON Polygon ([list of rings]) to 3D extruded KML
  /// `<Placemark>` elements. Creates TWO placemarks:
  /// 1. The main extruded polygon with semi-transparent fill
  /// 2. A ground-clamped outline for a "glow" effect at the base
  static String? _polygonToKml(List<dynamic> rings, String name) {
    if (rings.isEmpty) return null;

    // ── Extruded polygon (3D wall) ────────────────────────────────────────
    final outerCoords3d =
        _ringToKmlCoords(rings[0] as List<dynamic>, altitude: _extrusionHeight);
    if (outerCoords3d == null) return null;

    final holeParts3d = <String>[];
    for (int i = 1; i < rings.length; i++) {
      final hc = _ringToKmlCoords(rings[i] as List<dynamic>,
          altitude: _extrusionHeight);
      if (hc != null) {
        holeParts3d.add(
          '<innerBoundaryIs>'
          '<LinearRing><coordinates>$hc</coordinates></LinearRing>'
          '</innerBoundaryIs>',
        );
      }
    }

    // ── Ground outline (glow effect at base) ──────────────────────────────
    final outerCoordsGround =
        _ringToKmlCoords(rings[0] as List<dynamic>, altitude: 0);

    final buf = StringBuffer();

    // Main 3D extruded polygon
    buf.writeln('''
    <Placemark>
      <name>${_escXml(name)}</name>
      <styleUrl>#ecogrid_region_fill</styleUrl>
      <Polygon>
        <extrude>1</extrude>
        <altitudeMode>relativeToGround</altitudeMode>
        <outerBoundaryIs>
          <LinearRing><coordinates>$outerCoords3d</coordinates></LinearRing>
        </outerBoundaryIs>
        ${holeParts3d.join('\n        ')}
      </Polygon>
    </Placemark>''');

    // Ground-level filled outline
    if (outerCoordsGround != null) {
      buf.writeln('''
    <Placemark>
      <name></name>
      <styleUrl>#ecogrid_region_glow</styleUrl>
      <Polygon>
        <altitudeMode>clampToGround</altitudeMode>
        <outerBoundaryIs>
          <LinearRing><coordinates>$outerCoordsGround</coordinates></LinearRing>
        </outerBoundaryIs>
        ${holeParts3d.isNotEmpty ? holeParts3d.join('\n        ') : ''}
      </Polygon>
    </Placemark>''');
    }

    return buf.toString();
  }

  /// Converts a GeoJSON ring (array of [lon, lat] pairs) to a KML coordinate
  /// string with the given altitude: "lon,lat,alt lon,lat,alt …".
  ///
  /// Rings with more than [_maxRingPoints] points are evenly subsampled to
  /// keep KML size under control for large countries (India, USA, China).
  static const int _maxRingPoints = 500;

  static String? _ringToKmlCoords(List<dynamic> ring,
      {double altitude = 0}) {
    if (ring.isEmpty) return null;

    List<dynamic> points = ring;
    // Subsample large rings to prevent KML from exceeding transfer limits.
    if (points.length > _maxRingPoints) {
      final step = points.length / _maxRingPoints;
      final sampled = <dynamic>[];
      for (double i = 0; i < points.length - 1; i += step) {
        sampled.add(points[i.floor()]);
      }
      // Always include the last point to close the ring.
      sampled.add(points.last);
      points = sampled;
    }

    return points.map((pt) {
      final pair = pt as List<dynamic>;
      final lon = (pair[0] as num).toDouble();
      final lat = (pair[1] as num).toDouble();
      return '$lon,$lat,$altitude';
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
    final h = _extrusionHeight;
    final coordStr =
        '$minLon,$minLat,$h $maxLon,$minLat,$h '
        '$maxLon,$maxLat,$h $minLon,$maxLat,$h $minLon,$minLat,$h';
    final groundCoordStr =
        '$minLon,$minLat,0 $maxLon,$minLat,0 '
        '$maxLon,$maxLat,0 $minLon,$maxLat,0 $minLon,$minLat,0';

    final centerLat = (minLat + maxLat) / 2;
    final centerLon = (minLon + maxLon) / 2;
    final maxSpan = (maxLat - minLat) > (maxLon - minLon)
        ? (maxLat - minLat)
        : (maxLon - minLon);
    double camRange = maxSpan * 111000.0 * 1.4;
    if (camRange < 400000) camRange = 400000;
    if (camRange > 12000000) camRange = 12000000;

    final lookAtStr = KmlUtils.lookAt(
      lat: centerLat,
      lon: centerLon,
      altitude: 0,
      heading: 20,
      tilt: 55,
      range: camRange,
    );

    // If the region is massive (e.g. a continent like Europe or huge country),
    // a giant rectangle looks terrible on Google Earth. Just move the camera!
    if (maxSpan > 5) {
      return KmlUtils.wrapInKmlDocument(lookAtStr, name: name);
    }

    final content = '''
    ${_sharedStyles()}
    <Placemark>
      <name>${_escXml(name)}</name>
      <styleUrl>#ecogrid_region_fill</styleUrl>
      <Polygon>
        <extrude>1</extrude>
        <altitudeMode>relativeToGround</altitudeMode>
        <outerBoundaryIs>
          <LinearRing><coordinates>$coordStr</coordinates></LinearRing>
        </outerBoundaryIs>
      </Polygon>
    </Placemark>
    <Placemark>
      <name></name>
      <styleUrl>#ecogrid_region_glow</styleUrl>
      <Polygon>
        <altitudeMode>clampToGround</altitudeMode>
        <outerBoundaryIs>
          <LinearRing><coordinates>$groundCoordStr</coordinates></LinearRing>
        </outerBoundaryIs>
      </Polygon>
    </Placemark>
    $lookAtStr''';
    return KmlUtils.wrapInKmlDocument(content, name: name);
  }

  // ── XML helpers ────────────────────────────────────────────────────────────

  static String _escXml(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}
