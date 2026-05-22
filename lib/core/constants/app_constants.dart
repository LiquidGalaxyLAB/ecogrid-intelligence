/// Cache durations and application-wide constants.
class AppConstants {
  AppConstants._();

  // ─── Cache Staling Durations ─────────────────────────
  /// Climate data (current conditions): fresh for 1h, stale-while-revalidate up to 6h
  static const Duration climateStaleDuration = Duration(hours: 1);
  static const Duration climateExpireDuration = Duration(hours: 6);

  /// Historical climate data: rarely changes
  static const Duration historicalStaleDuration = Duration(days: 30);
  static const Duration historicalExpireDuration = Duration(days: 90);

  /// Power plant database: updated infrequently
  static const Duration plantDbStaleDuration = Duration(days: 7);
  static const Duration plantDbExpireDuration = Duration(days: 30);

  /// AI-generated insights: cache per plant/region
  static const Duration aiInsightStaleDuration = Duration(hours: 24);
  static const Duration aiInsightExpireDuration = Duration(hours: 72);

  /// CVS computed results: tied to climate data freshness
  static const Duration cvsStaleDuration = Duration(hours: 1);
  static const Duration cvsExpireDuration = Duration(hours: 6);

  // ─── Default Coordinates ─────────────────────────────
  static const double defaultLat = 20.5937;
  static const double defaultLng = 78.9629;
  static const double defaultAltitude = 5000000;

  // ─── Search ─────────────────────────────────────────
  static const int maxSearchResults = 50;
  static const int searchDebounceMs = 300;

  // ─── Clustering ──────────────────────────────────────
  static const double clusterGridSizeKm = 50.0;
  static const int maxPlacemarksPerRegion = 500;

  // ─── LG Orbit ───────────────────────────────────────
  static const double defaultOrbitRadius = 5000;
  static const int orbitSteps = 36;
  static const double defaultTilt = 60.0;
  static const double defaultRange = 10000.0;

  // ─── Hive Box Names ─────────────────────────────────
  static const String plantBox = 'power_plants';
  static const String climateBox = 'climate_data';
  static const String cvsBox = 'cvs_results';
  static const String aiInsightBox = 'ai_insights';
  static const String settingsBox = 'settings';
  static const String searchHistoryBox = 'search_history';
}
