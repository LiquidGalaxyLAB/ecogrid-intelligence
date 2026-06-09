/// Truly global app-wide constants that don't belong to any specific system.
class AppConstants {
  AppConstants._();

  // ─── App Identity ────────────────────────────────────
  static const String appName = 'EcoGrid Intelligence';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'AI-Driven Climate Resilience Analysis for Global Energy Infrastructure';

  // ─── Default Coordinates ─────────────────────────────
  static const double defaultLat = 20.5937;
  static const double defaultLng = 78.9629;
  static const double defaultAltitude = 5000000;

  // ─── Search ──────────────────────────────────────────
  static const int maxSearchResults = 50;
  static const int searchDebounceMs = 300;

  // ─── Clustering ──────────────────────────────────────
  static const double clusterGridSizeKm = 50.0;
  static const int maxPlacemarksPerRegion = 500;
}
