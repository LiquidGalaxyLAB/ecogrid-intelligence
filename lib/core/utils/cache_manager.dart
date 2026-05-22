/// Generic cache wrapper with stale-while-revalidate support.
///
/// Freshness lifecycle:
///   FRESH   → use directly, no background refresh
///   STALE   → use immediately, trigger background refresh
///   EXPIRED → must re-fetch before use
class CachedData<T> {
  final T data;
  final DateTime cachedAt;
  final Duration staleDuration;
  final Duration expireDuration;

  CachedData({
    required this.data,
    required this.cachedAt,
    required this.staleDuration,
    required this.expireDuration,
  });

  /// Whether data is older than stale threshold but not yet expired.
  bool get isStale =>
      DateTime.now().difference(cachedAt) > staleDuration && !isExpired;

  /// Whether data has exceeded its maximum lifetime.
  bool get isExpired =>
      DateTime.now().difference(cachedAt) > expireDuration;

  /// Whether data is within its fresh window.
  bool get isFresh => !isStale && !isExpired;

  /// Current freshness status.
  CacheStatus get status {
    if (isFresh) return CacheStatus.fresh;
    if (isStale) return CacheStatus.stale;
    return CacheStatus.expired;
  }

  /// Time remaining until data becomes stale.
  Duration get timeUntilStale {
    final diff = staleDuration - DateTime.now().difference(cachedAt);
    return diff.isNegative ? Duration.zero : diff;
  }

  /// Time remaining until data expires.
  Duration get timeUntilExpiry {
    final diff = expireDuration - DateTime.now().difference(cachedAt);
    return diff.isNegative ? Duration.zero : diff;
  }

  /// Create a fresh cache entry with current timestamp.
  factory CachedData.fresh({
    required T data,
    required Duration staleDuration,
    required Duration expireDuration,
  }) {
    return CachedData(
      data: data,
      cachedAt: DateTime.now(),
      staleDuration: staleDuration,
      expireDuration: expireDuration,
    );
  }

  /// Serialize to map for Hive storage.
  Map<String, dynamic> toStorageMap(Map<String, dynamic> Function(T) dataSerializer) {
    return {
      'data': dataSerializer(data),
      'cachedAt': cachedAt.toIso8601String(),
      'staleDuration': staleDuration.inMilliseconds,
      'expireDuration': expireDuration.inMilliseconds,
    };
  }

  /// Deserialize from Hive storage map.
  static CachedData<T>? fromStorageMap<T>(
    Map<String, dynamic>? map,
    T Function(Map<String, dynamic>) dataDeserializer,
  ) {
    if (map == null) return null;
    try {
      return CachedData<T>(
        data: dataDeserializer(map['data'] as Map<String, dynamic>),
        cachedAt: DateTime.parse(map['cachedAt'] as String),
        staleDuration: Duration(milliseconds: map['staleDuration'] as int),
        expireDuration: Duration(milliseconds: map['expireDuration'] as int),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Cache freshness status for BLoC consumption.
enum CacheStatus {
  fresh,
  stale,
  expired,
  offline,
  loading,
}
