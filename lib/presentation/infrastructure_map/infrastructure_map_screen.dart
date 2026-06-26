import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/theme/app_theme.dart';
import '../../config/theme/map_themes.dart';
import '../../core/enums/risk_level.dart';
import '../../core/utils/kml_utils.dart';
import '../../di/di.dart';
import '../../domain/model/power_plant.dart';
import '../../domain/model/cvs_result.dart';
import '../../domain/repository/cvs_repository.dart';
import '../components/plant_map_bottom_sheet.dart';
import '../explore/bloc/explore_bloc.dart';
import '../explore/bloc/explore_event.dart';
import '../explore/bloc/explore_state.dart';
import '../../service/lg_service.dart';

class InfrastructureMapScreen extends StatefulWidget {
  const InfrastructureMapScreen({super.key});

  @override
  State<InfrastructureMapScreen> createState() =>
      _InfrastructureMapScreenState();
}

class _InfrastructureMapScreenState extends State<InfrastructureMapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  Timer? _flyDebounce;
  Timer? _markerDebounce;

  // Defaults
  MapType _mapType = MapType.normal;
  String _mapTheme = MapThemes.mapsThemeNone;

  // Zoom State
  double _currentZoom = 2.0;
  final double _minZoom = 2.0;
  final double _maxZoom = 12.0;
  bool _isDraggingSlider = false;
  bool _lgSyncEnabled = true;

  // Markers
  Set<Marker> _markers = {};
  Set<Marker>? _cachedWorldMarkers;

  // Initial position (Global View)
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(20.0, 0.0),
    zoom: 2.0,
  );

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    // Dispatch global plant load immediately — bloc starts at ExploreInitial
    // and needs this event to fetch all plants and pre-compute CVS scores.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExploreBloc>().add(const ExploreGlobalLoaded());
    });
  }

  @override
  void dispose() {
    _flyDebounce?.cancel();
    _markerDebounce?.cancel();
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

  Future<void> _onZoomChanged(double zoom) async {
    setState(() {
      _currentZoom = zoom;
    });
    final controller = await _controller.future;
    controller.moveCamera(CameraUpdate.zoomTo(zoom));
  }

  Future<void> _onZoomEnd(double zoom) async {
    setState(() {
      _isDraggingSlider = false;
    });
    final controller = await _controller.future;
    controller.animateCamera(CameraUpdate.zoomTo(zoom));
  }

  // ─── Marker Density ──────────────────────────────────────────────────────

  int _getMarkerLimitForZoom(double zoom) {
    if (zoom < 4.0) return 80;
    if (zoom < 6.0) return 200;
    if (zoom < 9.0) return 350;
    return 500;
  }

  // ─── Proportional Risk Mix ───────────────────────────────────────────────

  List<PowerPlant> _selectProportionalSample(
    List<PowerPlant> viewportPlants,
    int limit,
  ) {
    if (viewportPlants.length <= limit) return viewportPlants;

    final cvsRepo = context.read<CvsRepository>();

    // IMPORTANT: Only use getCachedCvs here — never computeInstantCvs.
    // computeInstantCvs on 34k+ plants on the main thread causes a full UI freeze.
    // Uncached plants are treated as low risk and sorted last (score 0).
    final high = viewportPlants
        .where((p) => cvsRepo.getCachedCvs(p)?.riskLevel == RiskLevel.high)
        .toList();
    final medium = viewportPlants
        .where((p) => cvsRepo.getCachedCvs(p)?.riskLevel == RiskLevel.medium)
        .toList();
    final low = viewportPlants
        .where((p) {
          final r = cvsRepo.getCachedCvs(p)?.riskLevel;
          return r == RiskLevel.low || r == null;
        })
        .toList();

    final total = viewportPlants.length;
    final highCount = ((high.length / total) * limit).round();
    final mediumCount = ((medium.length / total) * limit).round();
    final lowCount = limit - highCount - mediumCount;

    // Sort by cached score only (uncached plants get score 0 and appear last)
    high.sort((a, b) => (cvsRepo.getCachedCvs(b)?.score ?? 0)
        .compareTo(cvsRepo.getCachedCvs(a)?.score ?? 0));
    medium.sort((a, b) => (cvsRepo.getCachedCvs(b)?.score ?? 0)
        .compareTo(cvsRepo.getCachedCvs(a)?.score ?? 0));
    low.sort((a, b) => (cvsRepo.getCachedCvs(b)?.score ?? 0)
        .compareTo(cvsRepo.getCachedCvs(a)?.score ?? 0));

    return [
      ...high.take(highCount),
      ...medium.take(mediumCount),
      ...low.take(lowCount < 0 ? 0 : lowCount),
    ];
  }

  // ─── Viewport Filtering ──────────────────────────────────────────────────

  Future<List<PowerPlant>> _getPlantsInViewport(
    List<PowerPlant> allPlants,
    LatLngBounds bounds,
  ) async {
    return allPlants.where((plant) {
      return bounds.contains(LatLng(plant.latitude, plant.longitude));
    }).toList();
  }

  // ─── Marker Builders ─────────────────────────────────────────────────────

  BitmapDescriptor _riskToMarkerColor(RiskLevel risk) {
    switch (risk) {
      case RiskLevel.high:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case RiskLevel.medium:
        return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange);
      case RiskLevel.low:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }
  }

  void _showBottomSheet(PowerPlant plant, CVSResult cvs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlantMapBottomSheet(plant: plant, cvs: cvs),
    );
  }

  Set<Marker> _buildMarkers(List<PowerPlant> plants) {
    return plants.map((plant) {
      final cvsRepo = context.read<CvsRepository>();
      final cvs = cvsRepo.getCachedCvs(plant) ?? cvsRepo.computeInstantCvs(plant);
      final risk = cvs.riskLevel;
      
      return Marker(
        markerId: MarkerId(plant.id),
        position: LatLng(plant.latitude, plant.longitude),
        icon: _riskToMarkerColor(risk),
        onTap: () => _showBottomSheet(plant, cvs),
      );
    }).toSet();
  }

  Future<Set<Marker>> _buildWorldViewMarkers(
    List<PowerPlant> allPlants,
  ) async {
    final Map<String, List<PowerPlant>> byCountry = {};
    for (final plant in allPlants) {
      final countryName = plant.countryLong ?? 'Unknown';
      byCountry.putIfAbsent(countryName, () => []).add(plant);
    }

    final markers = <Marker>{};

    for (final entry in byCountry.entries) {
      final countryName = entry.key;
      final plants = entry.value;

      double sumLat = 0;
      double sumLon = 0;
      for (final p in plants) {
        sumLat += p.latitude;
        sumLon += p.longitude;
      }
      final avgLat = sumLat / plants.length;
      final avgLon = sumLon / plants.length;

      // Yield occasionally to keep the main thread fluid
      if (markers.length % 20 == 0) {
        await Future.delayed(Duration.zero);
      }

      markers.add(Marker(
        markerId: MarkerId('country_$countryName'),
        position: LatLng(avgLat, avgLon),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueAzure,
        ),
        infoWindow: InfoWindow(
          title: countryName,
          snippet: '${plants.length} plants',
        ),
        onTap: () async {
          final controller = await _controller.future;
          await controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(avgLat, avgLon),
                zoom: 5.0, // lands in continentalView mode
              ),
            ),
          );
        },
      ));
    }

    return markers;
  }

  // ─── LG KML Sync ─────────────────────────────────────────────────────────

  Future<void> _syncMarkersToLG(List<PowerPlant> plants) async {
    if (!_lgSyncEnabled) return;
    final lgService = sl<LGService>();
    if (plants.isEmpty) {
      await lgService.clearMasterScreen();
      return;
    }

    final cvsRepo = context.read<CvsRepository>();
    final scores = plants.map((p) => cvsRepo.getUnifiedScore(p)).toList();
    final risks = plants
        .map((p) => cvsRepo.getCachedCvs(p)?.riskLevel ?? RiskLevel.low)
        .toList();

    final kml = KmlUtils.plantPlacemarksBatch(
      plants: plants,
      scores: scores,
      risks: risks,
      title: 'Infrastructure Map Plants',
    );

    await lgService.sendKmlToMaster(kml);
  }

  // ─── Central Refresh Logic ───────────────────────────────────────────────

  Future<void> _refreshMarkers(LatLng center, double zoom) async {
    if (!mounted) return;

    final exploreState = context.read<ExploreBloc>().state;
    final allPlants = exploreState is ExploreLoaded
        ? exploreState.plants
        : <PowerPlant>[];

    if (allPlants.isEmpty) return;

    if (zoom < 4.0) {
      // Level 1 — World: Country anchors only
      _cachedWorldMarkers ??= await _buildWorldViewMarkers(allPlants);

      if (mounted) {
        setState(() {
          _markers = _cachedWorldMarkers!;
        });
      }
      await sl<LGService>().clearMasterScreen();
      return;
    }

    final controller = await _controller.future;
    final bounds = await controller.getVisibleRegion();
    final viewportPlants = await _getPlantsInViewport(allPlants, bounds);
    final limit = _getMarkerLimitForZoom(zoom);

    // For all zoom levels >= 4.0, show all risk levels proportionally based on zoom limit
    final selectedPlants = _selectProportionalSample(viewportPlants, limit);

    if (mounted) {
      setState(() {
        _markers = _buildMarkers(selectedPlants);
      });
    }

    await _syncMarkersToLG(selectedPlants);
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
        actions: [
          IconButton(
            icon: Icon(
              _lgSyncEnabled ? Icons.sync : Icons.sync_disabled,
              color: _lgSyncEnabled
                  ? AppTheme.primary
                  : (isDark ? Colors.white54 : Colors.black38),
            ),
            tooltip: _lgSyncEnabled
                ? 'LG Sync: ON — tap to disable'
                : 'LG Sync: OFF — tap to enable',
            onPressed: () {
              setState(() {
                _lgSyncEnabled = !_lgSyncEnabled;
              });
            },
          ),
        ],
      ),
      body: BlocListener<ExploreBloc, ExploreState>(
        listenWhen: (previous, current) {
          // Fire only once: when we first enter ExploreLoaded from a non-loaded state.
          // The instant CVS fallback means all plants render immediately without
          // waiting for the background warmer to compute individual scores.
          return current is ExploreLoaded && previous is! ExploreLoaded;
        },
        listener: (context, state) {
          if (state is ExploreLoaded && state.plants.isNotEmpty) {
            _refreshMarkers(_initialPosition.target, _currentZoom);
          }
        },
        child: Stack(
        children: [
          GoogleMap(
            mapType: _mapType,
            style: _mapTheme,
            initialCameraPosition: _initialPosition,
            zoomControlsEnabled: false,
            minMaxZoomPreference: MinMaxZoomPreference(_minZoom, _maxZoom),
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            onCameraMove: (cameraPosition) {
              // Only update slider from map gestures if we aren't actively dragging the slider
              if (mounted &&
                  !_isDraggingSlider &&
                  _currentZoom != cameraPosition.zoom) {
                setState(() {
                  _currentZoom = cameraPosition.zoom;
                });
              }
              _flyDebounce?.cancel();
              _flyDebounce =
                  Timer(const Duration(milliseconds: 150), () {
                if (_lgSyncEnabled) {
                  sl<LGService>().flyTo(
                    cameraPosition.target.latitude,
                    cameraPosition.target.longitude,
                    0,
                    0,
                    60,
                    _zoomToRange(cameraPosition.zoom),
                  );
                }
              });
              // Separate, longer debounce for heavy marker computation.
              // 800ms ensures the user has stopped moving before we iterate
              // through tens of thousands of plants on the main thread.
              _markerDebounce?.cancel();
              _markerDebounce = Timer(
                const Duration(milliseconds: 800),
                () => _refreshMarkers(
                    cameraPosition.target, cameraPosition.zoom),
              );
            },
          ),
          // Custom Vertical Zoom Slider
          Positioned(
            right: 16,
            bottom: 40,
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.surfaceLight : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.add,
                        color: isDark ? Colors.white : Colors.black),
                    onPressed: () async {
                      if (_currentZoom < _maxZoom) {
                        final controller = await _controller.future;
                        controller.animateCamera(CameraUpdate.zoomIn());
                      }
                    },
                  ),
                  Expanded(
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4.0,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8.0),
                          overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 16.0),
                          activeTrackColor: AppTheme.primary,
                          inactiveTrackColor:
                              Colors.grey.withValues(alpha: 0.3),
                          thumbColor: AppTheme.primary,
                        ),
                        child: Slider(
                          value: _currentZoom,
                          min: _minZoom,
                          max: _maxZoom,
                          onChangeStart: (_) {
                            setState(() {
                              _isDraggingSlider = true;
                            });
                          },
                          onChanged: _onZoomChanged,
                          onChangeEnd: _onZoomEnd,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.remove,
                        color: isDark ? Colors.white : Colors.black),
                    onPressed: () async {
                      if (_currentZoom > _minZoom) {
                        final controller = await _controller.future;
                        controller.animateCamera(CameraUpdate.zoomOut());
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
