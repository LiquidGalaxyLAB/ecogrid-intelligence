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
  bool get isStale =>
      DateTime.now().difference(cachedAt) > staleDuration && !isExpired;
  bool get isExpired => DateTime.now().difference(cachedAt) > expireDuration;
  bool get isFresh => !isStale && !isExpired;
  CacheStatus get status {
    if (isFresh) return CacheStatus.fresh;
    if (isStale) return CacheStatus.stale;
    return CacheStatus.expired;
  }

  Duration get timeUntilStale {
    final diff = staleDuration - DateTime.now().difference(cachedAt);
    return diff.isNegative ? Duration.zero : diff;
  }

  Duration get timeUntilExpiry {
    final diff = expireDuration - DateTime.now().difference(cachedAt);
    return diff.isNegative ? Duration.zero : diff;
  }

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
  Map<String, dynamic> toStorageMap(
    Map<String, dynamic> Function(T) dataSerializer,
  ) {
    return {
      'data': dataSerializer(data),
      'cachedAt': cachedAt.toIso8601String(),
      'staleDuration': staleDuration.inMilliseconds,
      'expireDuration': expireDuration.inMilliseconds,
    };
  }

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

enum CacheStatus { fresh, stale, expired, offline, loading }
