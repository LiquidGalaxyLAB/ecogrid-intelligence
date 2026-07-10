part of 'app_database.dart';

class $LgSettingsTableTable extends LgSettingsTable
    with TableInfo<$LgSettingsTableTable, LgSettingsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LgSettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hostMeta = const VerificationMeta('host');
  @override
  late final GeneratedColumn<String> host = GeneratedColumn<String>(
    'host',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _portMeta = const VerificationMeta('port');
  @override
  late final GeneratedColumn<int> port = GeneratedColumn<int>(
    'port',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _passwordMeta = const VerificationMeta(
    'password',
  );
  @override
  late final GeneratedColumn<String> password = GeneratedColumn<String>(
    'password',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _screenCountMeta = const VerificationMeta(
    'screenCount',
  );
  @override
  late final GeneratedColumn<int> screenCount = GeneratedColumn<int>(
    'screen_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    host,
    port,
    username,
    password,
    screenCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lg_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<LgSettingsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('host')) {
      context.handle(
        _hostMeta,
        host.isAcceptableOrUnknown(data['host']!, _hostMeta),
      );
    } else if (isInserting) {
      context.missing(_hostMeta);
    }
    if (data.containsKey('port')) {
      context.handle(
        _portMeta,
        port.isAcceptableOrUnknown(data['port']!, _portMeta),
      );
    } else if (isInserting) {
      context.missing(_portMeta);
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('password')) {
      context.handle(
        _passwordMeta,
        password.isAcceptableOrUnknown(data['password']!, _passwordMeta),
      );
    } else if (isInserting) {
      context.missing(_passwordMeta);
    }
    if (data.containsKey('screen_count')) {
      context.handle(
        _screenCountMeta,
        screenCount.isAcceptableOrUnknown(
          data['screen_count']!,
          _screenCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_screenCountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LgSettingsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LgSettingsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      host: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}host'],
      )!,
      port: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}port'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      password: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}password'],
      )!,
      screenCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}screen_count'],
      )!,
    );
  }

  @override
  $LgSettingsTableTable createAlias(String alias) {
    return $LgSettingsTableTable(attachedDatabase, alias);
  }
}

class LgSettingsTableData extends DataClass
    implements Insertable<LgSettingsTableData> {
  final int id;
  final String host;
  final int port;
  final String username;
  final String password;
  final int screenCount;
  const LgSettingsTableData({
    required this.id,
    required this.host,
    required this.port,
    required this.username,
    required this.password,
    required this.screenCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['host'] = Variable<String>(host);
    map['port'] = Variable<int>(port);
    map['username'] = Variable<String>(username);
    map['password'] = Variable<String>(password);
    map['screen_count'] = Variable<int>(screenCount);
    return map;
  }

  LgSettingsTableCompanion toCompanion(bool nullToAbsent) {
    return LgSettingsTableCompanion(
      id: Value(id),
      host: Value(host),
      port: Value(port),
      username: Value(username),
      password: Value(password),
      screenCount: Value(screenCount),
    );
  }

  factory LgSettingsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LgSettingsTableData(
      id: serializer.fromJson<int>(json['id']),
      host: serializer.fromJson<String>(json['host']),
      port: serializer.fromJson<int>(json['port']),
      username: serializer.fromJson<String>(json['username']),
      password: serializer.fromJson<String>(json['password']),
      screenCount: serializer.fromJson<int>(json['screenCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'host': serializer.toJson<String>(host),
      'port': serializer.toJson<int>(port),
      'username': serializer.toJson<String>(username),
      'password': serializer.toJson<String>(password),
      'screenCount': serializer.toJson<int>(screenCount),
    };
  }

  LgSettingsTableData copyWith({
    int? id,
    String? host,
    int? port,
    String? username,
    String? password,
    int? screenCount,
  }) => LgSettingsTableData(
    id: id ?? this.id,
    host: host ?? this.host,
    port: port ?? this.port,
    username: username ?? this.username,
    password: password ?? this.password,
    screenCount: screenCount ?? this.screenCount,
  );
  LgSettingsTableData copyWithCompanion(LgSettingsTableCompanion data) {
    return LgSettingsTableData(
      id: data.id.present ? data.id.value : this.id,
      host: data.host.present ? data.host.value : this.host,
      port: data.port.present ? data.port.value : this.port,
      username: data.username.present ? data.username.value : this.username,
      password: data.password.present ? data.password.value : this.password,
      screenCount: data.screenCount.present
          ? data.screenCount.value
          : this.screenCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LgSettingsTableData(')
          ..write('id: $id, ')
          ..write('host: $host, ')
          ..write('port: $port, ')
          ..write('username: $username, ')
          ..write('password: $password, ')
          ..write('screenCount: $screenCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, host, port, username, password, screenCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LgSettingsTableData &&
          other.id == this.id &&
          other.host == this.host &&
          other.port == this.port &&
          other.username == this.username &&
          other.password == this.password &&
          other.screenCount == this.screenCount);
}

class LgSettingsTableCompanion extends UpdateCompanion<LgSettingsTableData> {
  final Value<int> id;
  final Value<String> host;
  final Value<int> port;
  final Value<String> username;
  final Value<String> password;
  final Value<int> screenCount;
  const LgSettingsTableCompanion({
    this.id = const Value.absent(),
    this.host = const Value.absent(),
    this.port = const Value.absent(),
    this.username = const Value.absent(),
    this.password = const Value.absent(),
    this.screenCount = const Value.absent(),
  });
  LgSettingsTableCompanion.insert({
    this.id = const Value.absent(),
    required String host,
    required int port,
    required String username,
    required String password,
    required int screenCount,
  }) : host = Value(host),
       port = Value(port),
       username = Value(username),
       password = Value(password),
       screenCount = Value(screenCount);
  static Insertable<LgSettingsTableData> custom({
    Expression<int>? id,
    Expression<String>? host,
    Expression<int>? port,
    Expression<String>? username,
    Expression<String>? password,
    Expression<int>? screenCount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (host != null) 'host': host,
      if (port != null) 'port': port,
      if (username != null) 'username': username,
      if (password != null) 'password': password,
      if (screenCount != null) 'screen_count': screenCount,
    });
  }

  LgSettingsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? host,
    Value<int>? port,
    Value<String>? username,
    Value<String>? password,
    Value<int>? screenCount,
  }) {
    return LgSettingsTableCompanion(
      id: id ?? this.id,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      screenCount: screenCount ?? this.screenCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (host.present) {
      map['host'] = Variable<String>(host.value);
    }
    if (port.present) {
      map['port'] = Variable<int>(port.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (password.present) {
      map['password'] = Variable<String>(password.value);
    }
    if (screenCount.present) {
      map['screen_count'] = Variable<int>(screenCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LgSettingsTableCompanion(')
          ..write('id: $id, ')
          ..write('host: $host, ')
          ..write('port: $port, ')
          ..write('username: $username, ')
          ..write('password: $password, ')
          ..write('screenCount: $screenCount')
          ..write(')'))
        .toString();
  }
}

class $ClimateCacheTableTable extends ClimateCacheTable
    with TableInfo<$ClimateCacheTableTable, ClimateCacheTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClimateCacheTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cacheKeyMeta = const VerificationMeta(
    'cacheKey',
  );
  @override
  late final GeneratedColumn<String> cacheKey = GeneratedColumn<String>(
    'cache_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [cacheKey, data, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'climate_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClimateCacheTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cache_key')) {
      context.handle(
        _cacheKeyMeta,
        cacheKey.isAcceptableOrUnknown(data['cache_key']!, _cacheKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_cacheKeyMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cacheKey};
  @override
  ClimateCacheTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClimateCacheTableData(
      cacheKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cache_key'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $ClimateCacheTableTable createAlias(String alias) {
    return $ClimateCacheTableTable(attachedDatabase, alias);
  }
}

class ClimateCacheTableData extends DataClass
    implements Insertable<ClimateCacheTableData> {
  final String cacheKey;
  final String data;
  final DateTime cachedAt;
  const ClimateCacheTableData({
    required this.cacheKey,
    required this.data,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cache_key'] = Variable<String>(cacheKey);
    map['data'] = Variable<String>(data);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  ClimateCacheTableCompanion toCompanion(bool nullToAbsent) {
    return ClimateCacheTableCompanion(
      cacheKey: Value(cacheKey),
      data: Value(data),
      cachedAt: Value(cachedAt),
    );
  }

  factory ClimateCacheTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClimateCacheTableData(
      cacheKey: serializer.fromJson<String>(json['cacheKey']),
      data: serializer.fromJson<String>(json['data']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cacheKey': serializer.toJson<String>(cacheKey),
      'data': serializer.toJson<String>(data),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  ClimateCacheTableData copyWith({
    String? cacheKey,
    String? data,
    DateTime? cachedAt,
  }) => ClimateCacheTableData(
    cacheKey: cacheKey ?? this.cacheKey,
    data: data ?? this.data,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  ClimateCacheTableData copyWithCompanion(ClimateCacheTableCompanion data) {
    return ClimateCacheTableData(
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      data: data.data.present ? data.data.value : this.data,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClimateCacheTableData(')
          ..write('cacheKey: $cacheKey, ')
          ..write('data: $data, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(cacheKey, data, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClimateCacheTableData &&
          other.cacheKey == this.cacheKey &&
          other.data == this.data &&
          other.cachedAt == this.cachedAt);
}

class ClimateCacheTableCompanion
    extends UpdateCompanion<ClimateCacheTableData> {
  final Value<String> cacheKey;
  final Value<String> data;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const ClimateCacheTableCompanion({
    this.cacheKey = const Value.absent(),
    this.data = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClimateCacheTableCompanion.insert({
    required String cacheKey,
    required String data,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : cacheKey = Value(cacheKey),
       data = Value(data),
       cachedAt = Value(cachedAt);
  static Insertable<ClimateCacheTableData> custom({
    Expression<String>? cacheKey,
    Expression<String>? data,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cacheKey != null) 'cache_key': cacheKey,
      if (data != null) 'data': data,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClimateCacheTableCompanion copyWith({
    Value<String>? cacheKey,
    Value<String>? data,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return ClimateCacheTableCompanion(
      cacheKey: cacheKey ?? this.cacheKey,
      data: data ?? this.data,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cacheKey.present) {
      map['cache_key'] = Variable<String>(cacheKey.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClimateCacheTableCompanion(')
          ..write('cacheKey: $cacheKey, ')
          ..write('data: $data, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AiInsightCacheTableTable extends AiInsightCacheTable
    with TableInfo<$AiInsightCacheTableTable, AiInsightCacheTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AiInsightCacheTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cacheKeyMeta = const VerificationMeta(
    'cacheKey',
  );
  @override
  late final GeneratedColumn<String> cacheKey = GeneratedColumn<String>(
    'cache_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _insightMeta = const VerificationMeta(
    'insight',
  );
  @override
  late final GeneratedColumn<String> insight = GeneratedColumn<String>(
    'insight',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cvsScoreMeta = const VerificationMeta(
    'cvsScore',
  );
  @override
  late final GeneratedColumn<double> cvsScore = GeneratedColumn<double>(
    'cvs_score',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [cacheKey, insight, cachedAt, cvsScore];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_insight_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<AiInsightCacheTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cache_key')) {
      context.handle(
        _cacheKeyMeta,
        cacheKey.isAcceptableOrUnknown(data['cache_key']!, _cacheKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_cacheKeyMeta);
    }
    if (data.containsKey('insight')) {
      context.handle(
        _insightMeta,
        insight.isAcceptableOrUnknown(data['insight']!, _insightMeta),
      );
    } else if (isInserting) {
      context.missing(_insightMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    if (data.containsKey('cvs_score')) {
      context.handle(
        _cvsScoreMeta,
        cvsScore.isAcceptableOrUnknown(data['cvs_score']!, _cvsScoreMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cacheKey};
  @override
  AiInsightCacheTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AiInsightCacheTableData(
      cacheKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cache_key'],
      )!,
      insight: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}insight'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
      cvsScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cvs_score'],
      ),
    );
  }

  @override
  $AiInsightCacheTableTable createAlias(String alias) {
    return $AiInsightCacheTableTable(attachedDatabase, alias);
  }
}

class AiInsightCacheTableData extends DataClass
    implements Insertable<AiInsightCacheTableData> {
  final String cacheKey;
  final String insight;
  final DateTime cachedAt;
  final double? cvsScore;
  const AiInsightCacheTableData({
    required this.cacheKey,
    required this.insight,
    required this.cachedAt,
    this.cvsScore,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cache_key'] = Variable<String>(cacheKey);
    map['insight'] = Variable<String>(insight);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    if (!nullToAbsent || cvsScore != null) {
      map['cvs_score'] = Variable<double>(cvsScore);
    }
    return map;
  }

  AiInsightCacheTableCompanion toCompanion(bool nullToAbsent) {
    return AiInsightCacheTableCompanion(
      cacheKey: Value(cacheKey),
      insight: Value(insight),
      cachedAt: Value(cachedAt),
      cvsScore: cvsScore == null && nullToAbsent
          ? const Value.absent()
          : Value(cvsScore),
    );
  }

  factory AiInsightCacheTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AiInsightCacheTableData(
      cacheKey: serializer.fromJson<String>(json['cacheKey']),
      insight: serializer.fromJson<String>(json['insight']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
      cvsScore: serializer.fromJson<double?>(json['cvsScore']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cacheKey': serializer.toJson<String>(cacheKey),
      'insight': serializer.toJson<String>(insight),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
      'cvsScore': serializer.toJson<double?>(cvsScore),
    };
  }

  AiInsightCacheTableData copyWith({
    String? cacheKey,
    String? insight,
    DateTime? cachedAt,
    Value<double?> cvsScore = const Value.absent(),
  }) => AiInsightCacheTableData(
    cacheKey: cacheKey ?? this.cacheKey,
    insight: insight ?? this.insight,
    cachedAt: cachedAt ?? this.cachedAt,
    cvsScore: cvsScore.present ? cvsScore.value : this.cvsScore,
  );
  AiInsightCacheTableData copyWithCompanion(AiInsightCacheTableCompanion data) {
    return AiInsightCacheTableData(
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      insight: data.insight.present ? data.insight.value : this.insight,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
      cvsScore: data.cvsScore.present ? data.cvsScore.value : this.cvsScore,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiInsightCacheTableData(')
          ..write('cacheKey: $cacheKey, ')
          ..write('insight: $insight, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('cvsScore: $cvsScore')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(cacheKey, insight, cachedAt, cvsScore);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiInsightCacheTableData &&
          other.cacheKey == this.cacheKey &&
          other.insight == this.insight &&
          other.cachedAt == this.cachedAt &&
          other.cvsScore == this.cvsScore);
}

class AiInsightCacheTableCompanion
    extends UpdateCompanion<AiInsightCacheTableData> {
  final Value<String> cacheKey;
  final Value<String> insight;
  final Value<DateTime> cachedAt;
  final Value<double?> cvsScore;
  final Value<int> rowid;
  const AiInsightCacheTableCompanion({
    this.cacheKey = const Value.absent(),
    this.insight = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.cvsScore = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AiInsightCacheTableCompanion.insert({
    required String cacheKey,
    required String insight,
    required DateTime cachedAt,
    this.cvsScore = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : cacheKey = Value(cacheKey),
       insight = Value(insight),
       cachedAt = Value(cachedAt);
  static Insertable<AiInsightCacheTableData> custom({
    Expression<String>? cacheKey,
    Expression<String>? insight,
    Expression<DateTime>? cachedAt,
    Expression<double>? cvsScore,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cacheKey != null) 'cache_key': cacheKey,
      if (insight != null) 'insight': insight,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (cvsScore != null) 'cvs_score': cvsScore,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AiInsightCacheTableCompanion copyWith({
    Value<String>? cacheKey,
    Value<String>? insight,
    Value<DateTime>? cachedAt,
    Value<double?>? cvsScore,
    Value<int>? rowid,
  }) {
    return AiInsightCacheTableCompanion(
      cacheKey: cacheKey ?? this.cacheKey,
      insight: insight ?? this.insight,
      cachedAt: cachedAt ?? this.cachedAt,
      cvsScore: cvsScore ?? this.cvsScore,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cacheKey.present) {
      map['cache_key'] = Variable<String>(cacheKey.value);
    }
    if (insight.present) {
      map['insight'] = Variable<String>(insight.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (cvsScore.present) {
      map['cvs_score'] = Variable<double>(cvsScore.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AiInsightCacheTableCompanion(')
          ..write('cacheKey: $cacheKey, ')
          ..write('insight: $insight, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('cvsScore: $cvsScore, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LgSettingsTableTable lgSettingsTable = $LgSettingsTableTable(
    this,
  );
  late final $ClimateCacheTableTable climateCacheTable =
      $ClimateCacheTableTable(this);
  late final $AiInsightCacheTableTable aiInsightCacheTable =
      $AiInsightCacheTableTable(this);
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  late final ClimateDao climateDao = ClimateDao(this as AppDatabase);
  late final AiCacheDao aiCacheDao = AiCacheDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    lgSettingsTable,
    climateCacheTable,
    aiInsightCacheTable,
  ];
}

typedef $$LgSettingsTableTableCreateCompanionBuilder =
    LgSettingsTableCompanion Function({
      Value<int> id,
      required String host,
      required int port,
      required String username,
      required String password,
      required int screenCount,
    });
typedef $$LgSettingsTableTableUpdateCompanionBuilder =
    LgSettingsTableCompanion Function({
      Value<int> id,
      Value<String> host,
      Value<int> port,
      Value<String> username,
      Value<String> password,
      Value<int> screenCount,
    });

class $$LgSettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $LgSettingsTableTable> {
  $$LgSettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );
  ColumnFilters<String> get host => $composableBuilder(
    column: $table.host,
    builder: (column) => ColumnFilters(column),
  );
  ColumnFilters<int> get port => $composableBuilder(
    column: $table.port,
    builder: (column) => ColumnFilters(column),
  );
  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );
  ColumnFilters<String> get password => $composableBuilder(
    column: $table.password,
    builder: (column) => ColumnFilters(column),
  );
  ColumnFilters<int> get screenCount => $composableBuilder(
    column: $table.screenCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LgSettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $LgSettingsTableTable> {
  $$LgSettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );
  ColumnOrderings<String> get host => $composableBuilder(
    column: $table.host,
    builder: (column) => ColumnOrderings(column),
  );
  ColumnOrderings<int> get port => $composableBuilder(
    column: $table.port,
    builder: (column) => ColumnOrderings(column),
  );
  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );
  ColumnOrderings<String> get password => $composableBuilder(
    column: $table.password,
    builder: (column) => ColumnOrderings(column),
  );
  ColumnOrderings<int> get screenCount => $composableBuilder(
    column: $table.screenCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LgSettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $LgSettingsTableTable> {
  $$LgSettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);
  GeneratedColumn<String> get host =>
      $composableBuilder(column: $table.host, builder: (column) => column);
  GeneratedColumn<int> get port =>
      $composableBuilder(column: $table.port, builder: (column) => column);
  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);
  GeneratedColumn<String> get password =>
      $composableBuilder(column: $table.password, builder: (column) => column);
  GeneratedColumn<int> get screenCount => $composableBuilder(
    column: $table.screenCount,
    builder: (column) => column,
  );
}

class $$LgSettingsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LgSettingsTableTable,
          LgSettingsTableData,
          $$LgSettingsTableTableFilterComposer,
          $$LgSettingsTableTableOrderingComposer,
          $$LgSettingsTableTableAnnotationComposer,
          $$LgSettingsTableTableCreateCompanionBuilder,
          $$LgSettingsTableTableUpdateCompanionBuilder,
          (
            LgSettingsTableData,
            BaseReferences<
              _$AppDatabase,
              $LgSettingsTableTable,
              LgSettingsTableData
            >,
          ),
          LgSettingsTableData,
          PrefetchHooks Function()
        > {
  $$LgSettingsTableTableTableManager(
    _$AppDatabase db,
    $LgSettingsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LgSettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LgSettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LgSettingsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> host = const Value.absent(),
                Value<int> port = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String> password = const Value.absent(),
                Value<int> screenCount = const Value.absent(),
              }) => LgSettingsTableCompanion(
                id: id,
                host: host,
                port: port,
                username: username,
                password: password,
                screenCount: screenCount,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String host,
                required int port,
                required String username,
                required String password,
                required int screenCount,
              }) => LgSettingsTableCompanion.insert(
                id: id,
                host: host,
                port: port,
                username: username,
                password: password,
                screenCount: screenCount,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LgSettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LgSettingsTableTable,
      LgSettingsTableData,
      $$LgSettingsTableTableFilterComposer,
      $$LgSettingsTableTableOrderingComposer,
      $$LgSettingsTableTableAnnotationComposer,
      $$LgSettingsTableTableCreateCompanionBuilder,
      $$LgSettingsTableTableUpdateCompanionBuilder,
      (
        LgSettingsTableData,
        BaseReferences<
          _$AppDatabase,
          $LgSettingsTableTable,
          LgSettingsTableData
        >,
      ),
      LgSettingsTableData,
      PrefetchHooks Function()
    >;
typedef $$ClimateCacheTableTableCreateCompanionBuilder =
    ClimateCacheTableCompanion Function({
      required String cacheKey,
      required String data,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$ClimateCacheTableTableUpdateCompanionBuilder =
    ClimateCacheTableCompanion Function({
      Value<String> cacheKey,
      Value<String> data,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$ClimateCacheTableTableFilterComposer
    extends Composer<_$AppDatabase, $ClimateCacheTableTable> {
  $$ClimateCacheTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnFilters(column),
  );
  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );
  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ClimateCacheTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ClimateCacheTableTable> {
  $$ClimateCacheTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnOrderings(column),
  );
  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );
  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClimateCacheTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClimateCacheTableTable> {
  $$ClimateCacheTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cacheKey =>
      $composableBuilder(column: $table.cacheKey, builder: (column) => column);
  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);
  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$ClimateCacheTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClimateCacheTableTable,
          ClimateCacheTableData,
          $$ClimateCacheTableTableFilterComposer,
          $$ClimateCacheTableTableOrderingComposer,
          $$ClimateCacheTableTableAnnotationComposer,
          $$ClimateCacheTableTableCreateCompanionBuilder,
          $$ClimateCacheTableTableUpdateCompanionBuilder,
          (
            ClimateCacheTableData,
            BaseReferences<
              _$AppDatabase,
              $ClimateCacheTableTable,
              ClimateCacheTableData
            >,
          ),
          ClimateCacheTableData,
          PrefetchHooks Function()
        > {
  $$ClimateCacheTableTableTableManager(
    _$AppDatabase db,
    $ClimateCacheTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClimateCacheTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClimateCacheTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClimateCacheTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> cacheKey = const Value.absent(),
                Value<String> data = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClimateCacheTableCompanion(
                cacheKey: cacheKey,
                data: data,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cacheKey,
                required String data,
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => ClimateCacheTableCompanion.insert(
                cacheKey: cacheKey,
                data: data,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ClimateCacheTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClimateCacheTableTable,
      ClimateCacheTableData,
      $$ClimateCacheTableTableFilterComposer,
      $$ClimateCacheTableTableOrderingComposer,
      $$ClimateCacheTableTableAnnotationComposer,
      $$ClimateCacheTableTableCreateCompanionBuilder,
      $$ClimateCacheTableTableUpdateCompanionBuilder,
      (
        ClimateCacheTableData,
        BaseReferences<
          _$AppDatabase,
          $ClimateCacheTableTable,
          ClimateCacheTableData
        >,
      ),
      ClimateCacheTableData,
      PrefetchHooks Function()
    >;
typedef $$AiInsightCacheTableTableCreateCompanionBuilder =
    AiInsightCacheTableCompanion Function({
      required String cacheKey,
      required String insight,
      required DateTime cachedAt,
      Value<double?> cvsScore,
      Value<int> rowid,
    });
typedef $$AiInsightCacheTableTableUpdateCompanionBuilder =
    AiInsightCacheTableCompanion Function({
      Value<String> cacheKey,
      Value<String> insight,
      Value<DateTime> cachedAt,
      Value<double?> cvsScore,
      Value<int> rowid,
    });

class $$AiInsightCacheTableTableFilterComposer
    extends Composer<_$AppDatabase, $AiInsightCacheTableTable> {
  $$AiInsightCacheTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnFilters(column),
  );
  ColumnFilters<String> get insight => $composableBuilder(
    column: $table.insight,
    builder: (column) => ColumnFilters(column),
  );
  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
  ColumnFilters<double> get cvsScore => $composableBuilder(
    column: $table.cvsScore,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AiInsightCacheTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AiInsightCacheTableTable> {
  $$AiInsightCacheTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnOrderings(column),
  );
  ColumnOrderings<String> get insight => $composableBuilder(
    column: $table.insight,
    builder: (column) => ColumnOrderings(column),
  );
  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
  ColumnOrderings<double> get cvsScore => $composableBuilder(
    column: $table.cvsScore,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AiInsightCacheTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AiInsightCacheTableTable> {
  $$AiInsightCacheTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cacheKey =>
      $composableBuilder(column: $table.cacheKey, builder: (column) => column);
  GeneratedColumn<String> get insight =>
      $composableBuilder(column: $table.insight, builder: (column) => column);
  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
  GeneratedColumn<double> get cvsScore =>
      $composableBuilder(column: $table.cvsScore, builder: (column) => column);
}

class $$AiInsightCacheTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AiInsightCacheTableTable,
          AiInsightCacheTableData,
          $$AiInsightCacheTableTableFilterComposer,
          $$AiInsightCacheTableTableOrderingComposer,
          $$AiInsightCacheTableTableAnnotationComposer,
          $$AiInsightCacheTableTableCreateCompanionBuilder,
          $$AiInsightCacheTableTableUpdateCompanionBuilder,
          (
            AiInsightCacheTableData,
            BaseReferences<
              _$AppDatabase,
              $AiInsightCacheTableTable,
              AiInsightCacheTableData
            >,
          ),
          AiInsightCacheTableData,
          PrefetchHooks Function()
        > {
  $$AiInsightCacheTableTableTableManager(
    _$AppDatabase db,
    $AiInsightCacheTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AiInsightCacheTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AiInsightCacheTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AiInsightCacheTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> cacheKey = const Value.absent(),
                Value<String> insight = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<double?> cvsScore = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AiInsightCacheTableCompanion(
                cacheKey: cacheKey,
                insight: insight,
                cachedAt: cachedAt,
                cvsScore: cvsScore,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cacheKey,
                required String insight,
                required DateTime cachedAt,
                Value<double?> cvsScore = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AiInsightCacheTableCompanion.insert(
                cacheKey: cacheKey,
                insight: insight,
                cachedAt: cachedAt,
                cvsScore: cvsScore,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AiInsightCacheTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AiInsightCacheTableTable,
      AiInsightCacheTableData,
      $$AiInsightCacheTableTableFilterComposer,
      $$AiInsightCacheTableTableOrderingComposer,
      $$AiInsightCacheTableTableAnnotationComposer,
      $$AiInsightCacheTableTableCreateCompanionBuilder,
      $$AiInsightCacheTableTableUpdateCompanionBuilder,
      (
        AiInsightCacheTableData,
        BaseReferences<
          _$AppDatabase,
          $AiInsightCacheTableTable,
          AiInsightCacheTableData
        >,
      ),
      AiInsightCacheTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LgSettingsTableTableTableManager get lgSettingsTable =>
      $$LgSettingsTableTableTableManager(_db, _db.lgSettingsTable);
  $$ClimateCacheTableTableTableManager get climateCacheTable =>
      $$ClimateCacheTableTableTableManager(_db, _db.climateCacheTable);
  $$AiInsightCacheTableTableTableManager get aiInsightCacheTable =>
      $$AiInsightCacheTableTableTableManager(_db, _db.aiInsightCacheTable);
}

mixin _$SettingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $LgSettingsTableTable get lgSettingsTable => attachedDatabase.lgSettingsTable;
  SettingsDaoManager get managers => SettingsDaoManager(this);
}

class SettingsDaoManager {
  final _$SettingsDaoMixin _db;
  SettingsDaoManager(this._db);
  $$LgSettingsTableTableTableManager get lgSettingsTable =>
      $$LgSettingsTableTableTableManager(
        _db.attachedDatabase,
        _db.lgSettingsTable,
      );
}

mixin _$ClimateDaoMixin on DatabaseAccessor<AppDatabase> {
  $ClimateCacheTableTable get climateCacheTable =>
      attachedDatabase.climateCacheTable;
  ClimateDaoManager get managers => ClimateDaoManager(this);
}

class ClimateDaoManager {
  final _$ClimateDaoMixin _db;
  ClimateDaoManager(this._db);
  $$ClimateCacheTableTableTableManager get climateCacheTable =>
      $$ClimateCacheTableTableTableManager(
        _db.attachedDatabase,
        _db.climateCacheTable,
      );
}

mixin _$AiCacheDaoMixin on DatabaseAccessor<AppDatabase> {
  $AiInsightCacheTableTable get aiInsightCacheTable =>
      attachedDatabase.aiInsightCacheTable;
  AiCacheDaoManager get managers => AiCacheDaoManager(this);
}

class AiCacheDaoManager {
  final _$AiCacheDaoMixin _db;
  AiCacheDaoManager(this._db);
  $$AiInsightCacheTableTableTableManager get aiInsightCacheTable =>
      $$AiInsightCacheTableTableTableManager(
        _db.attachedDatabase,
        _db.aiInsightCacheTable,
      );
}
