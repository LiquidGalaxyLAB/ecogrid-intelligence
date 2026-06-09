import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ecogrid_intelligence/config/theme/app_theme.dart';
import 'package:ecogrid_intelligence/config/theme/map_themes.dart';
import 'package:ecogrid_intelligence/di/di.dart';
import 'package:ecogrid_intelligence/service/lg_service.dart';

class InfrastructureMapScreen extends StatefulWidget {
  const InfrastructureMapScreen({super.key});

  @override
  State<InfrastructureMapScreen> createState() =>
      _InfrastructureMapScreenState();
}

class _InfrastructureMapScreenState extends State<InfrastructureMapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  Timer? _flyDebounce;

  // Defaults
  MapType _mapType = MapType.normal;
  String _mapTheme = MapThemes.mapsThemeNone;

  // Initial position (Global View)
  final CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(20.0, 0.0),
    zoom: 2.0,
  );

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  void dispose() {
    _flyDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Load map type
    final mapTypeIndex = prefs.getInt('map_style') ?? MapType.normal.index;
    if (mapTypeIndex >= 0 && mapTypeIndex < MapType.values.length) {
      _mapType = MapType.values[mapTypeIndex];
    }

    // Load map theme
    _mapTheme = prefs.getString('map_theme') ?? MapThemes.mapsThemeNone;

    if (mounted) {
      setState(() {});
    }
  }

  double _zoomToRange(double zoom) {
    return 40000000 / math.pow(2, zoom);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Infrastructure Map',
          style: AppTheme.headingSmall.copyWith(
            color: isDark ? Colors.white : AppTheme.textPrimary,
          ),
        ),
        backgroundColor: AppTheme.surfaceLight,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : AppTheme.textPrimary,
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: _mapType,
            style: _mapTheme,
            initialCameraPosition: _initialPosition,
            zoomControlsEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            onCameraMove: (cameraPosition) {
              _flyDebounce?.cancel();
              _flyDebounce = Timer(const Duration(milliseconds: 150), () {
                sl<LGService>().flyTo(
                  cameraPosition.target.latitude,
                  cameraPosition.target.longitude,
                  0,
                  0,
                  60,
                  _zoomToRange(cameraPosition.zoom),
                );
              });
            },
          ),
        ],
      ),
    );
  }
}
