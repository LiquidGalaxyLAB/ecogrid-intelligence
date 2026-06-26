/// All Hive/Drift cache keys and durations.
class CacheConstants {
  CacheConstants._();


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
}
