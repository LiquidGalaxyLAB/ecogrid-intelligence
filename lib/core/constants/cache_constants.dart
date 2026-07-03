class CacheConstants {
  CacheConstants._();
  static const Duration climateStaleDuration = Duration(hours: 1);
  static const Duration climateExpireDuration = Duration(hours: 6);
  static const Duration historicalStaleDuration = Duration(days: 30);
  static const Duration historicalExpireDuration = Duration(days: 90);
  static const Duration plantDbStaleDuration = Duration(days: 7);
  static const Duration plantDbExpireDuration = Duration(days: 30);
  static const Duration aiInsightStaleDuration = Duration(hours: 24);
  static const Duration aiInsightExpireDuration = Duration(hours: 72);
  static const Duration cvsStaleDuration = Duration(hours: 1);
  static const Duration cvsExpireDuration = Duration(hours: 6);
}
