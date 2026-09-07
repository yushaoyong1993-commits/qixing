// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ActivitiesTable extends Activities
    with TableInfo<$ActivitiesTable, Activity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('骑行'),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('公路'),
  );
  static const VerificationMeta _startAtMeta = const VerificationMeta(
    'startAt',
  );
  @override
  late final GeneratedColumn<DateTime> startAt = GeneratedColumn<DateTime>(
    'start_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endAtMeta = const VerificationMeta('endAt');
  @override
  late final GeneratedColumn<DateTime> endAt = GeneratedColumn<DateTime>(
    'end_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSMeta = const VerificationMeta(
    'durationS',
  );
  @override
  late final GeneratedColumn<int> durationS = GeneratedColumn<int>(
    'duration_s',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _movingSMeta = const VerificationMeta(
    'movingS',
  );
  @override
  late final GeneratedColumn<int> movingS = GeneratedColumn<int>(
    'moving_s',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _distanceMMeta = const VerificationMeta(
    'distanceM',
  );
  @override
  late final GeneratedColumn<double> distanceM = GeneratedColumn<double>(
    'distance_m',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _elevGainMMeta = const VerificationMeta(
    'elevGainM',
  );
  @override
  late final GeneratedColumn<double> elevGainM = GeneratedColumn<double>(
    'elev_gain_m',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _elevLossMMeta = const VerificationMeta(
    'elevLossM',
  );
  @override
  late final GeneratedColumn<double> elevLossM = GeneratedColumn<double>(
    'elev_loss_m',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _hrAvgMeta = const VerificationMeta('hrAvg');
  @override
  late final GeneratedColumn<int> hrAvg = GeneratedColumn<int>(
    'hr_avg',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hrMaxMeta = const VerificationMeta('hrMax');
  @override
  late final GeneratedColumn<int> hrMax = GeneratedColumn<int>(
    'hr_max',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kcalMeta = const VerificationMeta('kcal');
  @override
  late final GeneratedColumn<int> kcal = GeneratedColumn<int>(
    'kcal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('手机'),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    type,
    startAt,
    endAt,
    durationS,
    movingS,
    distanceM,
    elevGainM,
    elevLossM,
    hrAvg,
    hrMax,
    kcal,
    source,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activities';
  @override
  VerificationContext validateIntegrity(
    Insertable<Activity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('start_at')) {
      context.handle(
        _startAtMeta,
        startAt.isAcceptableOrUnknown(data['start_at']!, _startAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startAtMeta);
    }
    if (data.containsKey('end_at')) {
      context.handle(
        _endAtMeta,
        endAt.isAcceptableOrUnknown(data['end_at']!, _endAtMeta),
      );
    }
    if (data.containsKey('duration_s')) {
      context.handle(
        _durationSMeta,
        durationS.isAcceptableOrUnknown(data['duration_s']!, _durationSMeta),
      );
    }
    if (data.containsKey('moving_s')) {
      context.handle(
        _movingSMeta,
        movingS.isAcceptableOrUnknown(data['moving_s']!, _movingSMeta),
      );
    }
    if (data.containsKey('distance_m')) {
      context.handle(
        _distanceMMeta,
        distanceM.isAcceptableOrUnknown(data['distance_m']!, _distanceMMeta),
      );
    }
    if (data.containsKey('elev_gain_m')) {
      context.handle(
        _elevGainMMeta,
        elevGainM.isAcceptableOrUnknown(data['elev_gain_m']!, _elevGainMMeta),
      );
    }
    if (data.containsKey('elev_loss_m')) {
      context.handle(
        _elevLossMMeta,
        elevLossM.isAcceptableOrUnknown(data['elev_loss_m']!, _elevLossMMeta),
      );
    }
    if (data.containsKey('hr_avg')) {
      context.handle(
        _hrAvgMeta,
        hrAvg.isAcceptableOrUnknown(data['hr_avg']!, _hrAvgMeta),
      );
    }
    if (data.containsKey('hr_max')) {
      context.handle(
        _hrMaxMeta,
        hrMax.isAcceptableOrUnknown(data['hr_max']!, _hrMaxMeta),
      );
    }
    if (data.containsKey('kcal')) {
      context.handle(
        _kcalMeta,
        kcal.isAcceptableOrUnknown(data['kcal']!, _kcalMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Activity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Activity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      startAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_at'],
      )!,
      endAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_at'],
      ),
      durationS: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_s'],
      )!,
      movingS: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}moving_s'],
      )!,
      distanceM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_m'],
      )!,
      elevGainM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}elev_gain_m'],
      )!,
      elevLossM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}elev_loss_m'],
      )!,
      hrAvg: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hr_avg'],
      ),
      hrMax: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hr_max'],
      ),
      kcal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}kcal'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
    );
  }

  @override
  $ActivitiesTable createAlias(String alias) {
    return $ActivitiesTable(attachedDatabase, alias);
  }
}

class Activity extends DataClass implements Insertable<Activity> {
  final int id;
  final String name;
  final String type;
  final DateTime startAt;
  final DateTime? endAt;
  final int durationS;
  final int movingS;
  final double distanceM;
  final double elevGainM;
  final double elevLossM;
  final int? hrAvg;
  final int? hrMax;
  final int kcal;
  final String source;
  final String note;
  const Activity({
    required this.id,
    required this.name,
    required this.type,
    required this.startAt,
    this.endAt,
    required this.durationS,
    required this.movingS,
    required this.distanceM,
    required this.elevGainM,
    required this.elevLossM,
    this.hrAvg,
    this.hrMax,
    required this.kcal,
    required this.source,
    required this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['start_at'] = Variable<DateTime>(startAt);
    if (!nullToAbsent || endAt != null) {
      map['end_at'] = Variable<DateTime>(endAt);
    }
    map['duration_s'] = Variable<int>(durationS);
    map['moving_s'] = Variable<int>(movingS);
    map['distance_m'] = Variable<double>(distanceM);
    map['elev_gain_m'] = Variable<double>(elevGainM);
    map['elev_loss_m'] = Variable<double>(elevLossM);
    if (!nullToAbsent || hrAvg != null) {
      map['hr_avg'] = Variable<int>(hrAvg);
    }
    if (!nullToAbsent || hrMax != null) {
      map['hr_max'] = Variable<int>(hrMax);
    }
    map['kcal'] = Variable<int>(kcal);
    map['source'] = Variable<String>(source);
    map['note'] = Variable<String>(note);
    return map;
  }

  ActivitiesCompanion toCompanion(bool nullToAbsent) {
    return ActivitiesCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      startAt: Value(startAt),
      endAt: endAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endAt),
      durationS: Value(durationS),
      movingS: Value(movingS),
      distanceM: Value(distanceM),
      elevGainM: Value(elevGainM),
      elevLossM: Value(elevLossM),
      hrAvg: hrAvg == null && nullToAbsent
          ? const Value.absent()
          : Value(hrAvg),
      hrMax: hrMax == null && nullToAbsent
          ? const Value.absent()
          : Value(hrMax),
      kcal: Value(kcal),
      source: Value(source),
      note: Value(note),
    );
  }

  factory Activity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Activity(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      startAt: serializer.fromJson<DateTime>(json['startAt']),
      endAt: serializer.fromJson<DateTime?>(json['endAt']),
      durationS: serializer.fromJson<int>(json['durationS']),
      movingS: serializer.fromJson<int>(json['movingS']),
      distanceM: serializer.fromJson<double>(json['distanceM']),
      elevGainM: serializer.fromJson<double>(json['elevGainM']),
      elevLossM: serializer.fromJson<double>(json['elevLossM']),
      hrAvg: serializer.fromJson<int?>(json['hrAvg']),
      hrMax: serializer.fromJson<int?>(json['hrMax']),
      kcal: serializer.fromJson<int>(json['kcal']),
      source: serializer.fromJson<String>(json['source']),
      note: serializer.fromJson<String>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'startAt': serializer.toJson<DateTime>(startAt),
      'endAt': serializer.toJson<DateTime?>(endAt),
      'durationS': serializer.toJson<int>(durationS),
      'movingS': serializer.toJson<int>(movingS),
      'distanceM': serializer.toJson<double>(distanceM),
      'elevGainM': serializer.toJson<double>(elevGainM),
      'elevLossM': serializer.toJson<double>(elevLossM),
      'hrAvg': serializer.toJson<int?>(hrAvg),
      'hrMax': serializer.toJson<int?>(hrMax),
      'kcal': serializer.toJson<int>(kcal),
      'source': serializer.toJson<String>(source),
      'note': serializer.toJson<String>(note),
    };
  }

  Activity copyWith({
    int? id,
    String? name,
    String? type,
    DateTime? startAt,
    Value<DateTime?> endAt = const Value.absent(),
    int? durationS,
    int? movingS,
    double? distanceM,
    double? elevGainM,
    double? elevLossM,
    Value<int?> hrAvg = const Value.absent(),
    Value<int?> hrMax = const Value.absent(),
    int? kcal,
    String? source,
    String? note,
  }) => Activity(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    startAt: startAt ?? this.startAt,
    endAt: endAt.present ? endAt.value : this.endAt,
    durationS: durationS ?? this.durationS,
    movingS: movingS ?? this.movingS,
    distanceM: distanceM ?? this.distanceM,
    elevGainM: elevGainM ?? this.elevGainM,
    elevLossM: elevLossM ?? this.elevLossM,
    hrAvg: hrAvg.present ? hrAvg.value : this.hrAvg,
    hrMax: hrMax.present ? hrMax.value : this.hrMax,
    kcal: kcal ?? this.kcal,
    source: source ?? this.source,
    note: note ?? this.note,
  );
  Activity copyWithCompanion(ActivitiesCompanion data) {
    return Activity(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      startAt: data.startAt.present ? data.startAt.value : this.startAt,
      endAt: data.endAt.present ? data.endAt.value : this.endAt,
      durationS: data.durationS.present ? data.durationS.value : this.durationS,
      movingS: data.movingS.present ? data.movingS.value : this.movingS,
      distanceM: data.distanceM.present ? data.distanceM.value : this.distanceM,
      elevGainM: data.elevGainM.present ? data.elevGainM.value : this.elevGainM,
      elevLossM: data.elevLossM.present ? data.elevLossM.value : this.elevLossM,
      hrAvg: data.hrAvg.present ? data.hrAvg.value : this.hrAvg,
      hrMax: data.hrMax.present ? data.hrMax.value : this.hrMax,
      kcal: data.kcal.present ? data.kcal.value : this.kcal,
      source: data.source.present ? data.source.value : this.source,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Activity(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('startAt: $startAt, ')
          ..write('endAt: $endAt, ')
          ..write('durationS: $durationS, ')
          ..write('movingS: $movingS, ')
          ..write('distanceM: $distanceM, ')
          ..write('elevGainM: $elevGainM, ')
          ..write('elevLossM: $elevLossM, ')
          ..write('hrAvg: $hrAvg, ')
          ..write('hrMax: $hrMax, ')
          ..write('kcal: $kcal, ')
          ..write('source: $source, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    type,
    startAt,
    endAt,
    durationS,
    movingS,
    distanceM,
    elevGainM,
    elevLossM,
    hrAvg,
    hrMax,
    kcal,
    source,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Activity &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.startAt == this.startAt &&
          other.endAt == this.endAt &&
          other.durationS == this.durationS &&
          other.movingS == this.movingS &&
          other.distanceM == this.distanceM &&
          other.elevGainM == this.elevGainM &&
          other.elevLossM == this.elevLossM &&
          other.hrAvg == this.hrAvg &&
          other.hrMax == this.hrMax &&
          other.kcal == this.kcal &&
          other.source == this.source &&
          other.note == this.note);
}

class ActivitiesCompanion extends UpdateCompanion<Activity> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> type;
  final Value<DateTime> startAt;
  final Value<DateTime?> endAt;
  final Value<int> durationS;
  final Value<int> movingS;
  final Value<double> distanceM;
  final Value<double> elevGainM;
  final Value<double> elevLossM;
  final Value<int?> hrAvg;
  final Value<int?> hrMax;
  final Value<int> kcal;
  final Value<String> source;
  final Value<String> note;
  const ActivitiesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.startAt = const Value.absent(),
    this.endAt = const Value.absent(),
    this.durationS = const Value.absent(),
    this.movingS = const Value.absent(),
    this.distanceM = const Value.absent(),
    this.elevGainM = const Value.absent(),
    this.elevLossM = const Value.absent(),
    this.hrAvg = const Value.absent(),
    this.hrMax = const Value.absent(),
    this.kcal = const Value.absent(),
    this.source = const Value.absent(),
    this.note = const Value.absent(),
  });
  ActivitiesCompanion.insert({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    required DateTime startAt,
    this.endAt = const Value.absent(),
    this.durationS = const Value.absent(),
    this.movingS = const Value.absent(),
    this.distanceM = const Value.absent(),
    this.elevGainM = const Value.absent(),
    this.elevLossM = const Value.absent(),
    this.hrAvg = const Value.absent(),
    this.hrMax = const Value.absent(),
    this.kcal = const Value.absent(),
    this.source = const Value.absent(),
    this.note = const Value.absent(),
  }) : startAt = Value(startAt);
  static Insertable<Activity> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<DateTime>? startAt,
    Expression<DateTime>? endAt,
    Expression<int>? durationS,
    Expression<int>? movingS,
    Expression<double>? distanceM,
    Expression<double>? elevGainM,
    Expression<double>? elevLossM,
    Expression<int>? hrAvg,
    Expression<int>? hrMax,
    Expression<int>? kcal,
    Expression<String>? source,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (startAt != null) 'start_at': startAt,
      if (endAt != null) 'end_at': endAt,
      if (durationS != null) 'duration_s': durationS,
      if (movingS != null) 'moving_s': movingS,
      if (distanceM != null) 'distance_m': distanceM,
      if (elevGainM != null) 'elev_gain_m': elevGainM,
      if (elevLossM != null) 'elev_loss_m': elevLossM,
      if (hrAvg != null) 'hr_avg': hrAvg,
      if (hrMax != null) 'hr_max': hrMax,
      if (kcal != null) 'kcal': kcal,
      if (source != null) 'source': source,
      if (note != null) 'note': note,
    });
  }

  ActivitiesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? type,
    Value<DateTime>? startAt,
    Value<DateTime?>? endAt,
    Value<int>? durationS,
    Value<int>? movingS,
    Value<double>? distanceM,
    Value<double>? elevGainM,
    Value<double>? elevLossM,
    Value<int?>? hrAvg,
    Value<int?>? hrMax,
    Value<int>? kcal,
    Value<String>? source,
    Value<String>? note,
  }) {
    return ActivitiesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      durationS: durationS ?? this.durationS,
      movingS: movingS ?? this.movingS,
      distanceM: distanceM ?? this.distanceM,
      elevGainM: elevGainM ?? this.elevGainM,
      elevLossM: elevLossM ?? this.elevLossM,
      hrAvg: hrAvg ?? this.hrAvg,
      hrMax: hrMax ?? this.hrMax,
      kcal: kcal ?? this.kcal,
      source: source ?? this.source,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (startAt.present) {
      map['start_at'] = Variable<DateTime>(startAt.value);
    }
    if (endAt.present) {
      map['end_at'] = Variable<DateTime>(endAt.value);
    }
    if (durationS.present) {
      map['duration_s'] = Variable<int>(durationS.value);
    }
    if (movingS.present) {
      map['moving_s'] = Variable<int>(movingS.value);
    }
    if (distanceM.present) {
      map['distance_m'] = Variable<double>(distanceM.value);
    }
    if (elevGainM.present) {
      map['elev_gain_m'] = Variable<double>(elevGainM.value);
    }
    if (elevLossM.present) {
      map['elev_loss_m'] = Variable<double>(elevLossM.value);
    }
    if (hrAvg.present) {
      map['hr_avg'] = Variable<int>(hrAvg.value);
    }
    if (hrMax.present) {
      map['hr_max'] = Variable<int>(hrMax.value);
    }
    if (kcal.present) {
      map['kcal'] = Variable<int>(kcal.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivitiesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('startAt: $startAt, ')
          ..write('endAt: $endAt, ')
          ..write('durationS: $durationS, ')
          ..write('movingS: $movingS, ')
          ..write('distanceM: $distanceM, ')
          ..write('elevGainM: $elevGainM, ')
          ..write('elevLossM: $elevLossM, ')
          ..write('hrAvg: $hrAvg, ')
          ..write('hrMax: $hrMax, ')
          ..write('kcal: $kcal, ')
          ..write('source: $source, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $TrackPointsTable extends TrackPoints
    with TableInfo<$TrackPointsTable, TrackPoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrackPointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _activityIdMeta = const VerificationMeta(
    'activityId',
  );
  @override
  late final GeneratedColumn<int> activityId = GeneratedColumn<int>(
    'activity_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES activities (id)',
    ),
  );
  static const VerificationMeta _tMsMeta = const VerificationMeta('tMs');
  @override
  late final GeneratedColumn<int> tMs = GeneratedColumn<int>(
    't_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latE7Meta = const VerificationMeta('latE7');
  @override
  late final GeneratedColumn<int> latE7 = GeneratedColumn<int>(
    'lat_e7',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lonE7Meta = const VerificationMeta('lonE7');
  @override
  late final GeneratedColumn<int> lonE7 = GeneratedColumn<int>(
    'lon_e7',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _altCmMeta = const VerificationMeta('altCm');
  @override
  late final GeneratedColumn<int> altCm = GeneratedColumn<int>(
    'alt_cm',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _speedMpsMeta = const VerificationMeta(
    'speedMps',
  );
  @override
  late final GeneratedColumn<double> speedMps = GeneratedColumn<double>(
    'speed_mps',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hrMeta = const VerificationMeta('hr');
  @override
  late final GeneratedColumn<int> hr = GeneratedColumn<int>(
    'hr',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cadMeta = const VerificationMeta('cad');
  @override
  late final GeneratedColumn<int> cad = GeneratedColumn<int>(
    'cad',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _powerMeta = const VerificationMeta('power');
  @override
  late final GeneratedColumn<int> power = GeneratedColumn<int>(
    'power',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hdopMeta = const VerificationMeta('hdop');
  @override
  late final GeneratedColumn<int> hdop = GeneratedColumn<int>(
    'hdop',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _flagsMeta = const VerificationMeta('flags');
  @override
  late final GeneratedColumn<int> flags = GeneratedColumn<int>(
    'flags',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    activityId,
    tMs,
    latE7,
    lonE7,
    altCm,
    speedMps,
    hr,
    cad,
    power,
    hdop,
    flags,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'track_points';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrackPoint> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('activity_id')) {
      context.handle(
        _activityIdMeta,
        activityId.isAcceptableOrUnknown(data['activity_id']!, _activityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_activityIdMeta);
    }
    if (data.containsKey('t_ms')) {
      context.handle(
        _tMsMeta,
        tMs.isAcceptableOrUnknown(data['t_ms']!, _tMsMeta),
      );
    } else if (isInserting) {
      context.missing(_tMsMeta);
    }
    if (data.containsKey('lat_e7')) {
      context.handle(
        _latE7Meta,
        latE7.isAcceptableOrUnknown(data['lat_e7']!, _latE7Meta),
      );
    } else if (isInserting) {
      context.missing(_latE7Meta);
    }
    if (data.containsKey('lon_e7')) {
      context.handle(
        _lonE7Meta,
        lonE7.isAcceptableOrUnknown(data['lon_e7']!, _lonE7Meta),
      );
    } else if (isInserting) {
      context.missing(_lonE7Meta);
    }
    if (data.containsKey('alt_cm')) {
      context.handle(
        _altCmMeta,
        altCm.isAcceptableOrUnknown(data['alt_cm']!, _altCmMeta),
      );
    }
    if (data.containsKey('speed_mps')) {
      context.handle(
        _speedMpsMeta,
        speedMps.isAcceptableOrUnknown(data['speed_mps']!, _speedMpsMeta),
      );
    }
    if (data.containsKey('hr')) {
      context.handle(_hrMeta, hr.isAcceptableOrUnknown(data['hr']!, _hrMeta));
    }
    if (data.containsKey('cad')) {
      context.handle(
        _cadMeta,
        cad.isAcceptableOrUnknown(data['cad']!, _cadMeta),
      );
    }
    if (data.containsKey('power')) {
      context.handle(
        _powerMeta,
        power.isAcceptableOrUnknown(data['power']!, _powerMeta),
      );
    }
    if (data.containsKey('hdop')) {
      context.handle(
        _hdopMeta,
        hdop.isAcceptableOrUnknown(data['hdop']!, _hdopMeta),
      );
    }
    if (data.containsKey('flags')) {
      context.handle(
        _flagsMeta,
        flags.isAcceptableOrUnknown(data['flags']!, _flagsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {activityId, tMs};
  @override
  TrackPoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrackPoint(
      activityId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}activity_id'],
      )!,
      tMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}t_ms'],
      )!,
      latE7: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lat_e7'],
      )!,
      lonE7: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lon_e7'],
      )!,
      altCm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}alt_cm'],
      ),
      speedMps: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed_mps'],
      ),
      hr: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hr'],
      ),
      cad: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cad'],
      ),
      power: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}power'],
      ),
      hdop: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hdop'],
      ),
      flags: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}flags'],
      )!,
    );
  }

  @override
  $TrackPointsTable createAlias(String alias) {
    return $TrackPointsTable(attachedDatabase, alias);
  }
}

class TrackPoint extends DataClass implements Insertable<TrackPoint> {
  final int activityId;
  final int tMs;
  final int latE7;
  final int lonE7;
  final int? altCm;
  final double? speedMps;
  final int? hr;
  final int? cad;
  final int? power;
  final int? hdop;
  final int flags;
  const TrackPoint({
    required this.activityId,
    required this.tMs,
    required this.latE7,
    required this.lonE7,
    this.altCm,
    this.speedMps,
    this.hr,
    this.cad,
    this.power,
    this.hdop,
    required this.flags,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['activity_id'] = Variable<int>(activityId);
    map['t_ms'] = Variable<int>(tMs);
    map['lat_e7'] = Variable<int>(latE7);
    map['lon_e7'] = Variable<int>(lonE7);
    if (!nullToAbsent || altCm != null) {
      map['alt_cm'] = Variable<int>(altCm);
    }
    if (!nullToAbsent || speedMps != null) {
      map['speed_mps'] = Variable<double>(speedMps);
    }
    if (!nullToAbsent || hr != null) {
      map['hr'] = Variable<int>(hr);
    }
    if (!nullToAbsent || cad != null) {
      map['cad'] = Variable<int>(cad);
    }
    if (!nullToAbsent || power != null) {
      map['power'] = Variable<int>(power);
    }
    if (!nullToAbsent || hdop != null) {
      map['hdop'] = Variable<int>(hdop);
    }
    map['flags'] = Variable<int>(flags);
    return map;
  }

  TrackPointsCompanion toCompanion(bool nullToAbsent) {
    return TrackPointsCompanion(
      activityId: Value(activityId),
      tMs: Value(tMs),
      latE7: Value(latE7),
      lonE7: Value(lonE7),
      altCm: altCm == null && nullToAbsent
          ? const Value.absent()
          : Value(altCm),
      speedMps: speedMps == null && nullToAbsent
          ? const Value.absent()
          : Value(speedMps),
      hr: hr == null && nullToAbsent ? const Value.absent() : Value(hr),
      cad: cad == null && nullToAbsent ? const Value.absent() : Value(cad),
      power: power == null && nullToAbsent
          ? const Value.absent()
          : Value(power),
      hdop: hdop == null && nullToAbsent ? const Value.absent() : Value(hdop),
      flags: Value(flags),
    );
  }

  factory TrackPoint.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrackPoint(
      activityId: serializer.fromJson<int>(json['activityId']),
      tMs: serializer.fromJson<int>(json['tMs']),
      latE7: serializer.fromJson<int>(json['latE7']),
      lonE7: serializer.fromJson<int>(json['lonE7']),
      altCm: serializer.fromJson<int?>(json['altCm']),
      speedMps: serializer.fromJson<double?>(json['speedMps']),
      hr: serializer.fromJson<int?>(json['hr']),
      cad: serializer.fromJson<int?>(json['cad']),
      power: serializer.fromJson<int?>(json['power']),
      hdop: serializer.fromJson<int?>(json['hdop']),
      flags: serializer.fromJson<int>(json['flags']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'activityId': serializer.toJson<int>(activityId),
      'tMs': serializer.toJson<int>(tMs),
      'latE7': serializer.toJson<int>(latE7),
      'lonE7': serializer.toJson<int>(lonE7),
      'altCm': serializer.toJson<int?>(altCm),
      'speedMps': serializer.toJson<double?>(speedMps),
      'hr': serializer.toJson<int?>(hr),
      'cad': serializer.toJson<int?>(cad),
      'power': serializer.toJson<int?>(power),
      'hdop': serializer.toJson<int?>(hdop),
      'flags': serializer.toJson<int>(flags),
    };
  }

  TrackPoint copyWith({
    int? activityId,
    int? tMs,
    int? latE7,
    int? lonE7,
    Value<int?> altCm = const Value.absent(),
    Value<double?> speedMps = const Value.absent(),
    Value<int?> hr = const Value.absent(),
    Value<int?> cad = const Value.absent(),
    Value<int?> power = const Value.absent(),
    Value<int?> hdop = const Value.absent(),
    int? flags,
  }) => TrackPoint(
    activityId: activityId ?? this.activityId,
    tMs: tMs ?? this.tMs,
    latE7: latE7 ?? this.latE7,
    lonE7: lonE7 ?? this.lonE7,
    altCm: altCm.present ? altCm.value : this.altCm,
    speedMps: speedMps.present ? speedMps.value : this.speedMps,
    hr: hr.present ? hr.value : this.hr,
    cad: cad.present ? cad.value : this.cad,
    power: power.present ? power.value : this.power,
    hdop: hdop.present ? hdop.value : this.hdop,
    flags: flags ?? this.flags,
  );
  TrackPoint copyWithCompanion(TrackPointsCompanion data) {
    return TrackPoint(
      activityId: data.activityId.present
          ? data.activityId.value
          : this.activityId,
      tMs: data.tMs.present ? data.tMs.value : this.tMs,
      latE7: data.latE7.present ? data.latE7.value : this.latE7,
      lonE7: data.lonE7.present ? data.lonE7.value : this.lonE7,
      altCm: data.altCm.present ? data.altCm.value : this.altCm,
      speedMps: data.speedMps.present ? data.speedMps.value : this.speedMps,
      hr: data.hr.present ? data.hr.value : this.hr,
      cad: data.cad.present ? data.cad.value : this.cad,
      power: data.power.present ? data.power.value : this.power,
      hdop: data.hdop.present ? data.hdop.value : this.hdop,
      flags: data.flags.present ? data.flags.value : this.flags,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackPoint(')
          ..write('activityId: $activityId, ')
          ..write('tMs: $tMs, ')
          ..write('latE7: $latE7, ')
          ..write('lonE7: $lonE7, ')
          ..write('altCm: $altCm, ')
          ..write('speedMps: $speedMps, ')
          ..write('hr: $hr, ')
          ..write('cad: $cad, ')
          ..write('power: $power, ')
          ..write('hdop: $hdop, ')
          ..write('flags: $flags')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    activityId,
    tMs,
    latE7,
    lonE7,
    altCm,
    speedMps,
    hr,
    cad,
    power,
    hdop,
    flags,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackPoint &&
          other.activityId == this.activityId &&
          other.tMs == this.tMs &&
          other.latE7 == this.latE7 &&
          other.lonE7 == this.lonE7 &&
          other.altCm == this.altCm &&
          other.speedMps == this.speedMps &&
          other.hr == this.hr &&
          other.cad == this.cad &&
          other.power == this.power &&
          other.hdop == this.hdop &&
          other.flags == this.flags);
}

class TrackPointsCompanion extends UpdateCompanion<TrackPoint> {
  final Value<int> activityId;
  final Value<int> tMs;
  final Value<int> latE7;
  final Value<int> lonE7;
  final Value<int?> altCm;
  final Value<double?> speedMps;
  final Value<int?> hr;
  final Value<int?> cad;
  final Value<int?> power;
  final Value<int?> hdop;
  final Value<int> flags;
  final Value<int> rowid;
  const TrackPointsCompanion({
    this.activityId = const Value.absent(),
    this.tMs = const Value.absent(),
    this.latE7 = const Value.absent(),
    this.lonE7 = const Value.absent(),
    this.altCm = const Value.absent(),
    this.speedMps = const Value.absent(),
    this.hr = const Value.absent(),
    this.cad = const Value.absent(),
    this.power = const Value.absent(),
    this.hdop = const Value.absent(),
    this.flags = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrackPointsCompanion.insert({
    required int activityId,
    required int tMs,
    required int latE7,
    required int lonE7,
    this.altCm = const Value.absent(),
    this.speedMps = const Value.absent(),
    this.hr = const Value.absent(),
    this.cad = const Value.absent(),
    this.power = const Value.absent(),
    this.hdop = const Value.absent(),
    this.flags = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : activityId = Value(activityId),
       tMs = Value(tMs),
       latE7 = Value(latE7),
       lonE7 = Value(lonE7);
  static Insertable<TrackPoint> custom({
    Expression<int>? activityId,
    Expression<int>? tMs,
    Expression<int>? latE7,
    Expression<int>? lonE7,
    Expression<int>? altCm,
    Expression<double>? speedMps,
    Expression<int>? hr,
    Expression<int>? cad,
    Expression<int>? power,
    Expression<int>? hdop,
    Expression<int>? flags,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (activityId != null) 'activity_id': activityId,
      if (tMs != null) 't_ms': tMs,
      if (latE7 != null) 'lat_e7': latE7,
      if (lonE7 != null) 'lon_e7': lonE7,
      if (altCm != null) 'alt_cm': altCm,
      if (speedMps != null) 'speed_mps': speedMps,
      if (hr != null) 'hr': hr,
      if (cad != null) 'cad': cad,
      if (power != null) 'power': power,
      if (hdop != null) 'hdop': hdop,
      if (flags != null) 'flags': flags,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrackPointsCompanion copyWith({
    Value<int>? activityId,
    Value<int>? tMs,
    Value<int>? latE7,
    Value<int>? lonE7,
    Value<int?>? altCm,
    Value<double?>? speedMps,
    Value<int?>? hr,
    Value<int?>? cad,
    Value<int?>? power,
    Value<int?>? hdop,
    Value<int>? flags,
    Value<int>? rowid,
  }) {
    return TrackPointsCompanion(
      activityId: activityId ?? this.activityId,
      tMs: tMs ?? this.tMs,
      latE7: latE7 ?? this.latE7,
      lonE7: lonE7 ?? this.lonE7,
      altCm: altCm ?? this.altCm,
      speedMps: speedMps ?? this.speedMps,
      hr: hr ?? this.hr,
      cad: cad ?? this.cad,
      power: power ?? this.power,
      hdop: hdop ?? this.hdop,
      flags: flags ?? this.flags,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (activityId.present) {
      map['activity_id'] = Variable<int>(activityId.value);
    }
    if (tMs.present) {
      map['t_ms'] = Variable<int>(tMs.value);
    }
    if (latE7.present) {
      map['lat_e7'] = Variable<int>(latE7.value);
    }
    if (lonE7.present) {
      map['lon_e7'] = Variable<int>(lonE7.value);
    }
    if (altCm.present) {
      map['alt_cm'] = Variable<int>(altCm.value);
    }
    if (speedMps.present) {
      map['speed_mps'] = Variable<double>(speedMps.value);
    }
    if (hr.present) {
      map['hr'] = Variable<int>(hr.value);
    }
    if (cad.present) {
      map['cad'] = Variable<int>(cad.value);
    }
    if (power.present) {
      map['power'] = Variable<int>(power.value);
    }
    if (hdop.present) {
      map['hdop'] = Variable<int>(hdop.value);
    }
    if (flags.present) {
      map['flags'] = Variable<int>(flags.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrackPointsCompanion(')
          ..write('activityId: $activityId, ')
          ..write('tMs: $tMs, ')
          ..write('latE7: $latE7, ')
          ..write('lonE7: $lonE7, ')
          ..write('altCm: $altCm, ')
          ..write('speedMps: $speedMps, ')
          ..write('hr: $hr, ')
          ..write('cad: $cad, ')
          ..write('power: $power, ')
          ..write('hdop: $hdop, ')
          ..write('flags: $flags, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LapsTable extends Laps with TableInfo<$LapsTable, Lap> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LapsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _activityIdMeta = const VerificationMeta(
    'activityId',
  );
  @override
  late final GeneratedColumn<int> activityId = GeneratedColumn<int>(
    'activity_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES activities (id)',
    ),
  );
  static const VerificationMeta _idxMeta = const VerificationMeta('idx');
  @override
  late final GeneratedColumn<int> idx = GeneratedColumn<int>(
    'idx',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startTMeta = const VerificationMeta('startT');
  @override
  late final GeneratedColumn<int> startT = GeneratedColumn<int>(
    'start_t',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTMeta = const VerificationMeta('endT');
  @override
  late final GeneratedColumn<int> endT = GeneratedColumn<int>(
    'end_t',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _distMMeta = const VerificationMeta('distM');
  @override
  late final GeneratedColumn<double> distM = GeneratedColumn<double>(
    'dist_m',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [activityId, idx, startT, endT, distM];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'laps';
  @override
  VerificationContext validateIntegrity(
    Insertable<Lap> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('activity_id')) {
      context.handle(
        _activityIdMeta,
        activityId.isAcceptableOrUnknown(data['activity_id']!, _activityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_activityIdMeta);
    }
    if (data.containsKey('idx')) {
      context.handle(
        _idxMeta,
        idx.isAcceptableOrUnknown(data['idx']!, _idxMeta),
      );
    } else if (isInserting) {
      context.missing(_idxMeta);
    }
    if (data.containsKey('start_t')) {
      context.handle(
        _startTMeta,
        startT.isAcceptableOrUnknown(data['start_t']!, _startTMeta),
      );
    } else if (isInserting) {
      context.missing(_startTMeta);
    }
    if (data.containsKey('end_t')) {
      context.handle(
        _endTMeta,
        endT.isAcceptableOrUnknown(data['end_t']!, _endTMeta),
      );
    } else if (isInserting) {
      context.missing(_endTMeta);
    }
    if (data.containsKey('dist_m')) {
      context.handle(
        _distMMeta,
        distM.isAcceptableOrUnknown(data['dist_m']!, _distMMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {activityId, idx};
  @override
  Lap map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Lap(
      activityId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}activity_id'],
      )!,
      idx: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}idx'],
      )!,
      startT: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_t'],
      )!,
      endT: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_t'],
      )!,
      distM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}dist_m'],
      )!,
    );
  }

  @override
  $LapsTable createAlias(String alias) {
    return $LapsTable(attachedDatabase, alias);
  }
}

class Lap extends DataClass implements Insertable<Lap> {
  final int activityId;
  final int idx;
  final int startT;
  final int endT;
  final double distM;
  const Lap({
    required this.activityId,
    required this.idx,
    required this.startT,
    required this.endT,
    required this.distM,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['activity_id'] = Variable<int>(activityId);
    map['idx'] = Variable<int>(idx);
    map['start_t'] = Variable<int>(startT);
    map['end_t'] = Variable<int>(endT);
    map['dist_m'] = Variable<double>(distM);
    return map;
  }

  LapsCompanion toCompanion(bool nullToAbsent) {
    return LapsCompanion(
      activityId: Value(activityId),
      idx: Value(idx),
      startT: Value(startT),
      endT: Value(endT),
      distM: Value(distM),
    );
  }

  factory Lap.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Lap(
      activityId: serializer.fromJson<int>(json['activityId']),
      idx: serializer.fromJson<int>(json['idx']),
      startT: serializer.fromJson<int>(json['startT']),
      endT: serializer.fromJson<int>(json['endT']),
      distM: serializer.fromJson<double>(json['distM']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'activityId': serializer.toJson<int>(activityId),
      'idx': serializer.toJson<int>(idx),
      'startT': serializer.toJson<int>(startT),
      'endT': serializer.toJson<int>(endT),
      'distM': serializer.toJson<double>(distM),
    };
  }

  Lap copyWith({
    int? activityId,
    int? idx,
    int? startT,
    int? endT,
    double? distM,
  }) => Lap(
    activityId: activityId ?? this.activityId,
    idx: idx ?? this.idx,
    startT: startT ?? this.startT,
    endT: endT ?? this.endT,
    distM: distM ?? this.distM,
  );
  Lap copyWithCompanion(LapsCompanion data) {
    return Lap(
      activityId: data.activityId.present
          ? data.activityId.value
          : this.activityId,
      idx: data.idx.present ? data.idx.value : this.idx,
      startT: data.startT.present ? data.startT.value : this.startT,
      endT: data.endT.present ? data.endT.value : this.endT,
      distM: data.distM.present ? data.distM.value : this.distM,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Lap(')
          ..write('activityId: $activityId, ')
          ..write('idx: $idx, ')
          ..write('startT: $startT, ')
          ..write('endT: $endT, ')
          ..write('distM: $distM')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(activityId, idx, startT, endT, distM);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Lap &&
          other.activityId == this.activityId &&
          other.idx == this.idx &&
          other.startT == this.startT &&
          other.endT == this.endT &&
          other.distM == this.distM);
}

class LapsCompanion extends UpdateCompanion<Lap> {
  final Value<int> activityId;
  final Value<int> idx;
  final Value<int> startT;
  final Value<int> endT;
  final Value<double> distM;
  final Value<int> rowid;
  const LapsCompanion({
    this.activityId = const Value.absent(),
    this.idx = const Value.absent(),
    this.startT = const Value.absent(),
    this.endT = const Value.absent(),
    this.distM = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LapsCompanion.insert({
    required int activityId,
    required int idx,
    required int startT,
    required int endT,
    this.distM = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : activityId = Value(activityId),
       idx = Value(idx),
       startT = Value(startT),
       endT = Value(endT);
  static Insertable<Lap> custom({
    Expression<int>? activityId,
    Expression<int>? idx,
    Expression<int>? startT,
    Expression<int>? endT,
    Expression<double>? distM,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (activityId != null) 'activity_id': activityId,
      if (idx != null) 'idx': idx,
      if (startT != null) 'start_t': startT,
      if (endT != null) 'end_t': endT,
      if (distM != null) 'dist_m': distM,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LapsCompanion copyWith({
    Value<int>? activityId,
    Value<int>? idx,
    Value<int>? startT,
    Value<int>? endT,
    Value<double>? distM,
    Value<int>? rowid,
  }) {
    return LapsCompanion(
      activityId: activityId ?? this.activityId,
      idx: idx ?? this.idx,
      startT: startT ?? this.startT,
      endT: endT ?? this.endT,
      distM: distM ?? this.distM,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (activityId.present) {
      map['activity_id'] = Variable<int>(activityId.value);
    }
    if (idx.present) {
      map['idx'] = Variable<int>(idx.value);
    }
    if (startT.present) {
      map['start_t'] = Variable<int>(startT.value);
    }
    if (endT.present) {
      map['end_t'] = Variable<int>(endT.value);
    }
    if (distM.present) {
      map['dist_m'] = Variable<double>(distM.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LapsCompanion(')
          ..write('activityId: $activityId, ')
          ..write('idx: $idx, ')
          ..write('startT: $startT, ')
          ..write('endT: $endT, ')
          ..write('distM: $distM, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DraftsTable extends Drafts with TableInfo<$DraftsTable, Draft> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DraftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('公路'),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalSMeta = const VerificationMeta('totalS');
  @override
  late final GeneratedColumn<int> totalS = GeneratedColumn<int>(
    'total_s',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _distanceKmMeta = const VerificationMeta(
    'distanceKm',
  );
  @override
  late final GeneratedColumn<double> distanceKm = GeneratedColumn<double>(
    'distance_km',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lapsMeta = const VerificationMeta('laps');
  @override
  late final GeneratedColumn<int> laps = GeneratedColumn<int>(
    'laps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    startedAt,
    totalS,
    distanceKm,
    laps,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'drafts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Draft> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('total_s')) {
      context.handle(
        _totalSMeta,
        totalS.isAcceptableOrUnknown(data['total_s']!, _totalSMeta),
      );
    }
    if (data.containsKey('distance_km')) {
      context.handle(
        _distanceKmMeta,
        distanceKm.isAcceptableOrUnknown(data['distance_km']!, _distanceKmMeta),
      );
    }
    if (data.containsKey('laps')) {
      context.handle(
        _lapsMeta,
        laps.isAcceptableOrUnknown(data['laps']!, _lapsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Draft map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Draft(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      totalS: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_s'],
      )!,
      distanceKm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_km'],
      )!,
      laps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}laps'],
      )!,
    );
  }

  @override
  $DraftsTable createAlias(String alias) {
    return $DraftsTable(attachedDatabase, alias);
  }
}

class Draft extends DataClass implements Insertable<Draft> {
  final int id;
  final String type;
  final DateTime startedAt;
  final int totalS;
  final double distanceKm;
  final int laps;
  const Draft({
    required this.id,
    required this.type,
    required this.startedAt,
    required this.totalS,
    required this.distanceKm,
    required this.laps,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['total_s'] = Variable<int>(totalS);
    map['distance_km'] = Variable<double>(distanceKm);
    map['laps'] = Variable<int>(laps);
    return map;
  }

  DraftsCompanion toCompanion(bool nullToAbsent) {
    return DraftsCompanion(
      id: Value(id),
      type: Value(type),
      startedAt: Value(startedAt),
      totalS: Value(totalS),
      distanceKm: Value(distanceKm),
      laps: Value(laps),
    );
  }

  factory Draft.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Draft(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      totalS: serializer.fromJson<int>(json['totalS']),
      distanceKm: serializer.fromJson<double>(json['distanceKm']),
      laps: serializer.fromJson<int>(json['laps']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(type),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'totalS': serializer.toJson<int>(totalS),
      'distanceKm': serializer.toJson<double>(distanceKm),
      'laps': serializer.toJson<int>(laps),
    };
  }

  Draft copyWith({
    int? id,
    String? type,
    DateTime? startedAt,
    int? totalS,
    double? distanceKm,
    int? laps,
  }) => Draft(
    id: id ?? this.id,
    type: type ?? this.type,
    startedAt: startedAt ?? this.startedAt,
    totalS: totalS ?? this.totalS,
    distanceKm: distanceKm ?? this.distanceKm,
    laps: laps ?? this.laps,
  );
  Draft copyWithCompanion(DraftsCompanion data) {
    return Draft(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      totalS: data.totalS.present ? data.totalS.value : this.totalS,
      distanceKm: data.distanceKm.present
          ? data.distanceKm.value
          : this.distanceKm,
      laps: data.laps.present ? data.laps.value : this.laps,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Draft(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('startedAt: $startedAt, ')
          ..write('totalS: $totalS, ')
          ..write('distanceKm: $distanceKm, ')
          ..write('laps: $laps')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, type, startedAt, totalS, distanceKm, laps);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Draft &&
          other.id == this.id &&
          other.type == this.type &&
          other.startedAt == this.startedAt &&
          other.totalS == this.totalS &&
          other.distanceKm == this.distanceKm &&
          other.laps == this.laps);
}

class DraftsCompanion extends UpdateCompanion<Draft> {
  final Value<int> id;
  final Value<String> type;
  final Value<DateTime> startedAt;
  final Value<int> totalS;
  final Value<double> distanceKm;
  final Value<int> laps;
  const DraftsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.totalS = const Value.absent(),
    this.distanceKm = const Value.absent(),
    this.laps = const Value.absent(),
  });
  DraftsCompanion.insert({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    required DateTime startedAt,
    this.totalS = const Value.absent(),
    this.distanceKm = const Value.absent(),
    this.laps = const Value.absent(),
  }) : startedAt = Value(startedAt);
  static Insertable<Draft> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<DateTime>? startedAt,
    Expression<int>? totalS,
    Expression<double>? distanceKm,
    Expression<int>? laps,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (startedAt != null) 'started_at': startedAt,
      if (totalS != null) 'total_s': totalS,
      if (distanceKm != null) 'distance_km': distanceKm,
      if (laps != null) 'laps': laps,
    });
  }

  DraftsCompanion copyWith({
    Value<int>? id,
    Value<String>? type,
    Value<DateTime>? startedAt,
    Value<int>? totalS,
    Value<double>? distanceKm,
    Value<int>? laps,
  }) {
    return DraftsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      startedAt: startedAt ?? this.startedAt,
      totalS: totalS ?? this.totalS,
      distanceKm: distanceKm ?? this.distanceKm,
      laps: laps ?? this.laps,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (totalS.present) {
      map['total_s'] = Variable<int>(totalS.value);
    }
    if (distanceKm.present) {
      map['distance_km'] = Variable<double>(distanceKm.value);
    }
    if (laps.present) {
      map['laps'] = Variable<int>(laps.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DraftsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('startedAt: $startedAt, ')
          ..write('totalS: $totalS, ')
          ..write('distanceKm: $distanceKm, ')
          ..write('laps: $laps')
          ..write(')'))
        .toString();
  }
}

class $SummaryCacheTable extends SummaryCache
    with TableInfo<$SummaryCacheTable, SummaryCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SummaryCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _periodKindMeta = const VerificationMeta(
    'periodKind',
  );
  @override
  late final GeneratedColumn<String> periodKind = GeneratedColumn<String>(
    'period_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bucketKeyMeta = const VerificationMeta(
    'bucketKey',
  );
  @override
  late final GeneratedColumn<String> bucketKey = GeneratedColumn<String>(
    'bucket_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kmMeta = const VerificationMeta('km');
  @override
  late final GeneratedColumn<double> km = GeneratedColumn<double>(
    'km',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _minMeta = const VerificationMeta('min');
  @override
  late final GeneratedColumn<double> min = GeneratedColumn<double>(
    'min',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _elevMeta = const VerificationMeta('elev');
  @override
  late final GeneratedColumn<double> elev = GeneratedColumn<double>(
    'elev',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _cntMeta = const VerificationMeta('cnt');
  @override
  late final GeneratedColumn<int> cnt = GeneratedColumn<int>(
    'cnt',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    periodKind,
    bucketKey,
    km,
    min,
    elev,
    cnt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'summary_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<SummaryCacheData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('period_kind')) {
      context.handle(
        _periodKindMeta,
        periodKind.isAcceptableOrUnknown(data['period_kind']!, _periodKindMeta),
      );
    } else if (isInserting) {
      context.missing(_periodKindMeta);
    }
    if (data.containsKey('bucket_key')) {
      context.handle(
        _bucketKeyMeta,
        bucketKey.isAcceptableOrUnknown(data['bucket_key']!, _bucketKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_bucketKeyMeta);
    }
    if (data.containsKey('km')) {
      context.handle(_kmMeta, km.isAcceptableOrUnknown(data['km']!, _kmMeta));
    }
    if (data.containsKey('min')) {
      context.handle(
        _minMeta,
        min.isAcceptableOrUnknown(data['min']!, _minMeta),
      );
    }
    if (data.containsKey('elev')) {
      context.handle(
        _elevMeta,
        elev.isAcceptableOrUnknown(data['elev']!, _elevMeta),
      );
    }
    if (data.containsKey('cnt')) {
      context.handle(
        _cntMeta,
        cnt.isAcceptableOrUnknown(data['cnt']!, _cntMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {periodKind, bucketKey};
  @override
  SummaryCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SummaryCacheData(
      periodKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}period_kind'],
      )!,
      bucketKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bucket_key'],
      )!,
      km: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}km'],
      )!,
      min: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}min'],
      )!,
      elev: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}elev'],
      )!,
      cnt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cnt'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SummaryCacheTable createAlias(String alias) {
    return $SummaryCacheTable(attachedDatabase, alias);
  }
}

class SummaryCacheData extends DataClass
    implements Insertable<SummaryCacheData> {
  final String periodKind;
  final String bucketKey;
  final double km;
  final double min;
  final double elev;
  final int cnt;
  final DateTime updatedAt;
  const SummaryCacheData({
    required this.periodKind,
    required this.bucketKey,
    required this.km,
    required this.min,
    required this.elev,
    required this.cnt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['period_kind'] = Variable<String>(periodKind);
    map['bucket_key'] = Variable<String>(bucketKey);
    map['km'] = Variable<double>(km);
    map['min'] = Variable<double>(min);
    map['elev'] = Variable<double>(elev);
    map['cnt'] = Variable<int>(cnt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SummaryCacheCompanion toCompanion(bool nullToAbsent) {
    return SummaryCacheCompanion(
      periodKind: Value(periodKind),
      bucketKey: Value(bucketKey),
      km: Value(km),
      min: Value(min),
      elev: Value(elev),
      cnt: Value(cnt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SummaryCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SummaryCacheData(
      periodKind: serializer.fromJson<String>(json['periodKind']),
      bucketKey: serializer.fromJson<String>(json['bucketKey']),
      km: serializer.fromJson<double>(json['km']),
      min: serializer.fromJson<double>(json['min']),
      elev: serializer.fromJson<double>(json['elev']),
      cnt: serializer.fromJson<int>(json['cnt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'periodKind': serializer.toJson<String>(periodKind),
      'bucketKey': serializer.toJson<String>(bucketKey),
      'km': serializer.toJson<double>(km),
      'min': serializer.toJson<double>(min),
      'elev': serializer.toJson<double>(elev),
      'cnt': serializer.toJson<int>(cnt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SummaryCacheData copyWith({
    String? periodKind,
    String? bucketKey,
    double? km,
    double? min,
    double? elev,
    int? cnt,
    DateTime? updatedAt,
  }) => SummaryCacheData(
    periodKind: periodKind ?? this.periodKind,
    bucketKey: bucketKey ?? this.bucketKey,
    km: km ?? this.km,
    min: min ?? this.min,
    elev: elev ?? this.elev,
    cnt: cnt ?? this.cnt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SummaryCacheData copyWithCompanion(SummaryCacheCompanion data) {
    return SummaryCacheData(
      periodKind: data.periodKind.present
          ? data.periodKind.value
          : this.periodKind,
      bucketKey: data.bucketKey.present ? data.bucketKey.value : this.bucketKey,
      km: data.km.present ? data.km.value : this.km,
      min: data.min.present ? data.min.value : this.min,
      elev: data.elev.present ? data.elev.value : this.elev,
      cnt: data.cnt.present ? data.cnt.value : this.cnt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SummaryCacheData(')
          ..write('periodKind: $periodKind, ')
          ..write('bucketKey: $bucketKey, ')
          ..write('km: $km, ')
          ..write('min: $min, ')
          ..write('elev: $elev, ')
          ..write('cnt: $cnt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(periodKind, bucketKey, km, min, elev, cnt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SummaryCacheData &&
          other.periodKind == this.periodKind &&
          other.bucketKey == this.bucketKey &&
          other.km == this.km &&
          other.min == this.min &&
          other.elev == this.elev &&
          other.cnt == this.cnt &&
          other.updatedAt == this.updatedAt);
}

class SummaryCacheCompanion extends UpdateCompanion<SummaryCacheData> {
  final Value<String> periodKind;
  final Value<String> bucketKey;
  final Value<double> km;
  final Value<double> min;
  final Value<double> elev;
  final Value<int> cnt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SummaryCacheCompanion({
    this.periodKind = const Value.absent(),
    this.bucketKey = const Value.absent(),
    this.km = const Value.absent(),
    this.min = const Value.absent(),
    this.elev = const Value.absent(),
    this.cnt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SummaryCacheCompanion.insert({
    required String periodKind,
    required String bucketKey,
    this.km = const Value.absent(),
    this.min = const Value.absent(),
    this.elev = const Value.absent(),
    this.cnt = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : periodKind = Value(periodKind),
       bucketKey = Value(bucketKey),
       updatedAt = Value(updatedAt);
  static Insertable<SummaryCacheData> custom({
    Expression<String>? periodKind,
    Expression<String>? bucketKey,
    Expression<double>? km,
    Expression<double>? min,
    Expression<double>? elev,
    Expression<int>? cnt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (periodKind != null) 'period_kind': periodKind,
      if (bucketKey != null) 'bucket_key': bucketKey,
      if (km != null) 'km': km,
      if (min != null) 'min': min,
      if (elev != null) 'elev': elev,
      if (cnt != null) 'cnt': cnt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SummaryCacheCompanion copyWith({
    Value<String>? periodKind,
    Value<String>? bucketKey,
    Value<double>? km,
    Value<double>? min,
    Value<double>? elev,
    Value<int>? cnt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SummaryCacheCompanion(
      periodKind: periodKind ?? this.periodKind,
      bucketKey: bucketKey ?? this.bucketKey,
      km: km ?? this.km,
      min: min ?? this.min,
      elev: elev ?? this.elev,
      cnt: cnt ?? this.cnt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (periodKind.present) {
      map['period_kind'] = Variable<String>(periodKind.value);
    }
    if (bucketKey.present) {
      map['bucket_key'] = Variable<String>(bucketKey.value);
    }
    if (km.present) {
      map['km'] = Variable<double>(km.value);
    }
    if (min.present) {
      map['min'] = Variable<double>(min.value);
    }
    if (elev.present) {
      map['elev'] = Variable<double>(elev.value);
    }
    if (cnt.present) {
      map['cnt'] = Variable<int>(cnt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SummaryCacheCompanion(')
          ..write('periodKind: $periodKind, ')
          ..write('bucketKey: $bucketKey, ')
          ..write('km: $km, ')
          ..write('min: $min, ')
          ..write('elev: $elev, ')
          ..write('cnt: $cnt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      ),
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String? value;
  const Setting({required this.key, this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      key: Value(key),
      value: value == null && nullToAbsent
          ? const Value.absent()
          : Value(value),
    );
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String?>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String?>(value),
    };
  }

  Setting copyWith({
    String? key,
    Value<String?> value = const Value.absent(),
  }) => Setting(
    key: key ?? this.key,
    value: value.present ? value.value : this.value,
  );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String?> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String?>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$BashoDatabase extends GeneratedDatabase {
  _$BashoDatabase(QueryExecutor e) : super(e);
  $BashoDatabaseManager get managers => $BashoDatabaseManager(this);
  late final $ActivitiesTable activities = $ActivitiesTable(this);
  late final $TrackPointsTable trackPoints = $TrackPointsTable(this);
  late final $LapsTable laps = $LapsTable(this);
  late final $DraftsTable drafts = $DraftsTable(this);
  late final $SummaryCacheTable summaryCache = $SummaryCacheTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    activities,
    trackPoints,
    laps,
    drafts,
    summaryCache,
    settings,
  ];
}

typedef $$ActivitiesTableCreateCompanionBuilder = ActivitiesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> type,
  required DateTime startAt,
  Value<DateTime?> endAt,
  Value<int> durationS,
  Value<int> movingS,
  Value<double> distanceM,
  Value<double> elevGainM,
  Value<double> elevLossM,
  Value<int?> hrAvg,
  Value<int?> hrMax,
  Value<int> kcal,
  Value<String> source,
  Value<String> note,
});
typedef $$ActivitiesTableUpdateCompanionBuilder = ActivitiesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> type,
  Value<DateTime> startAt,
  Value<DateTime?> endAt,
  Value<int> durationS,
  Value<int> movingS,
  Value<double> distanceM,
  Value<double> elevGainM,
  Value<double> elevLossM,
  Value<int?> hrAvg,
  Value<int?> hrMax,
  Value<int> kcal,
  Value<String> source,
  Value<String> note,
});

final class $$ActivitiesTableReferences
    extends BaseReferences<_$BashoDatabase, $ActivitiesTable, Activity> {
  $$ActivitiesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TrackPointsTable, List<TrackPoint>>
  _trackPointsRefsTable(_$BashoDatabase db) => MultiTypedResultKey.fromTable(
    db.trackPoints,
    aliasName: 'activities__id__track_points__activity_id',
  );

  $$TrackPointsTableProcessedTableManager get trackPointsRefs {
    final manager = $$TrackPointsTableTableManager(
      $_db,
      $_db.trackPoints,
    ).filter((f) => f.activityId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_trackPointsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LapsTable, List<Lap>> _lapsRefsTable(
    _$BashoDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.laps,
    aliasName: 'activities__id__laps__activity_id',
  );

  $$LapsTableProcessedTableManager get lapsRefs {
    final manager = $$LapsTableTableManager(
      $_db,
      $_db.laps,
    ).filter((f) => f.activityId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_lapsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ActivitiesTableFilterComposer
    extends Composer<_$BashoDatabase, $ActivitiesTable> {
  $$ActivitiesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endAt => $composableBuilder(
    column: $table.endAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationS => $composableBuilder(
    column: $table.durationS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get movingS => $composableBuilder(
    column: $table.movingS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceM => $composableBuilder(
    column: $table.distanceM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get elevGainM => $composableBuilder(
    column: $table.elevGainM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get elevLossM => $composableBuilder(
    column: $table.elevLossM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hrAvg => $composableBuilder(
    column: $table.hrAvg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hrMax => $composableBuilder(
    column: $table.hrMax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get kcal => $composableBuilder(
    column: $table.kcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> trackPointsRefs(
    Expression<bool> Function($$TrackPointsTableFilterComposer f) f,
  ) {
    final $$TrackPointsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trackPoints,
      getReferencedColumn: (t) => t.activityId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackPointsTableFilterComposer(
            $db: $db,
            $table: $db.trackPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> lapsRefs(
    Expression<bool> Function($$LapsTableFilterComposer f) f,
  ) {
    final $$LapsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.laps,
      getReferencedColumn: (t) => t.activityId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LapsTableFilterComposer(
            $db: $db,
            $table: $db.laps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ActivitiesTableOrderingComposer
    extends Composer<_$BashoDatabase, $ActivitiesTable> {
  $$ActivitiesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endAt => $composableBuilder(
    column: $table.endAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationS => $composableBuilder(
    column: $table.durationS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get movingS => $composableBuilder(
    column: $table.movingS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceM => $composableBuilder(
    column: $table.distanceM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get elevGainM => $composableBuilder(
    column: $table.elevGainM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get elevLossM => $composableBuilder(
    column: $table.elevLossM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hrAvg => $composableBuilder(
    column: $table.hrAvg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hrMax => $composableBuilder(
    column: $table.hrMax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get kcal => $composableBuilder(
    column: $table.kcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ActivitiesTableAnnotationComposer
    extends Composer<_$BashoDatabase, $ActivitiesTable> {
  $$ActivitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get startAt =>
      $composableBuilder(column: $table.startAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endAt =>
      $composableBuilder(column: $table.endAt, builder: (column) => column);

  GeneratedColumn<int> get durationS =>
      $composableBuilder(column: $table.durationS, builder: (column) => column);

  GeneratedColumn<int> get movingS =>
      $composableBuilder(column: $table.movingS, builder: (column) => column);

  GeneratedColumn<double> get distanceM =>
      $composableBuilder(column: $table.distanceM, builder: (column) => column);

  GeneratedColumn<double> get elevGainM =>
      $composableBuilder(column: $table.elevGainM, builder: (column) => column);

  GeneratedColumn<double> get elevLossM =>
      $composableBuilder(column: $table.elevLossM, builder: (column) => column);

  GeneratedColumn<int> get hrAvg =>
      $composableBuilder(column: $table.hrAvg, builder: (column) => column);

  GeneratedColumn<int> get hrMax =>
      $composableBuilder(column: $table.hrMax, builder: (column) => column);

  GeneratedColumn<int> get kcal =>
      $composableBuilder(column: $table.kcal, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  Expression<T> trackPointsRefs<T extends Object>(
    Expression<T> Function($$TrackPointsTableAnnotationComposer a) f,
  ) {
    final $$TrackPointsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trackPoints,
      getReferencedColumn: (t) => t.activityId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackPointsTableAnnotationComposer(
            $db: $db,
            $table: $db.trackPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> lapsRefs<T extends Object>(
    Expression<T> Function($$LapsTableAnnotationComposer a) f,
  ) {
    final $$LapsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.laps,
      getReferencedColumn: (t) => t.activityId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LapsTableAnnotationComposer(
            $db: $db,
            $table: $db.laps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ActivitiesTableTableManager
    extends
        RootTableManager<
          _$BashoDatabase,
          $ActivitiesTable,
          Activity,
          $$ActivitiesTableFilterComposer,
          $$ActivitiesTableOrderingComposer,
          $$ActivitiesTableAnnotationComposer,
          $$ActivitiesTableCreateCompanionBuilder,
          $$ActivitiesTableUpdateCompanionBuilder,
          (Activity, $$ActivitiesTableReferences),
          Activity,
          PrefetchHooks Function({bool trackPointsRefs, bool lapsRefs})
        > {
  $$ActivitiesTableTableManager(_$BashoDatabase db, $ActivitiesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActivitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActivitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActivitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<DateTime> startAt = const Value.absent(),
                Value<DateTime?> endAt = const Value.absent(),
                Value<int> durationS = const Value.absent(),
                Value<int> movingS = const Value.absent(),
                Value<double> distanceM = const Value.absent(),
                Value<double> elevGainM = const Value.absent(),
                Value<double> elevLossM = const Value.absent(),
                Value<int?> hrAvg = const Value.absent(),
                Value<int?> hrMax = const Value.absent(),
                Value<int> kcal = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> note = const Value.absent(),
              }) => ActivitiesCompanion(
                id: id,
                name: name,
                type: type,
                startAt: startAt,
                endAt: endAt,
                durationS: durationS,
                movingS: movingS,
                distanceM: distanceM,
                elevGainM: elevGainM,
                elevLossM: elevLossM,
                hrAvg: hrAvg,
                hrMax: hrMax,
                kcal: kcal,
                source: source,
                note: note,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                required DateTime startAt,
                Value<DateTime?> endAt = const Value.absent(),
                Value<int> durationS = const Value.absent(),
                Value<int> movingS = const Value.absent(),
                Value<double> distanceM = const Value.absent(),
                Value<double> elevGainM = const Value.absent(),
                Value<double> elevLossM = const Value.absent(),
                Value<int?> hrAvg = const Value.absent(),
                Value<int?> hrMax = const Value.absent(),
                Value<int> kcal = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> note = const Value.absent(),
              }) => ActivitiesCompanion.insert(
                id: id,
                name: name,
                type: type,
                startAt: startAt,
                endAt: endAt,
                durationS: durationS,
                movingS: movingS,
                distanceM: distanceM,
                elevGainM: elevGainM,
                elevLossM: elevLossM,
                hrAvg: hrAvg,
                hrMax: hrMax,
                kcal: kcal,
                source: source,
                note: note,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ActivitiesTable, Activity>(table),
                  $$ActivitiesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({trackPointsRefs = false, lapsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (trackPointsRefs) db.trackPoints,
                if (lapsRefs) db.laps,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (trackPointsRefs)
                    await $_getPrefetchedData<
                      Activity,
                      $ActivitiesTable,
                      TrackPoint
                    >(
                      currentTable: table,
                      referencedTable: $$ActivitiesTableReferences
                          ._trackPointsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ActivitiesTableReferences(
                            db,
                            table,
                            p0,
                          ).trackPointsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.activityId == item.id),
                      typedResults: items,
                    ),
                  if (lapsRefs)
                    await $_getPrefetchedData<Activity, $ActivitiesTable, Lap>(
                      currentTable: table,
                      referencedTable: $$ActivitiesTableReferences
                          ._lapsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ActivitiesTableReferences(db, table, p0).lapsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.activityId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ActivitiesTableProcessedTableManager =
    ProcessedTableManager<
      _$BashoDatabase,
      $ActivitiesTable,
      Activity,
      $$ActivitiesTableFilterComposer,
      $$ActivitiesTableOrderingComposer,
      $$ActivitiesTableAnnotationComposer,
      $$ActivitiesTableCreateCompanionBuilder,
      $$ActivitiesTableUpdateCompanionBuilder,
      (Activity, $$ActivitiesTableReferences),
      Activity,
      PrefetchHooks Function({bool trackPointsRefs, bool lapsRefs})
    >;
typedef $$TrackPointsTableCreateCompanionBuilder =
    TrackPointsCompanion Function({
      required int activityId,
      required int tMs,
      required int latE7,
      required int lonE7,
      Value<int?> altCm,
      Value<double?> speedMps,
      Value<int?> hr,
      Value<int?> cad,
      Value<int?> power,
      Value<int?> hdop,
      Value<int> flags,
      Value<int> rowid,
    });
typedef $$TrackPointsTableUpdateCompanionBuilder =
    TrackPointsCompanion Function({
      Value<int> activityId,
      Value<int> tMs,
      Value<int> latE7,
      Value<int> lonE7,
      Value<int?> altCm,
      Value<double?> speedMps,
      Value<int?> hr,
      Value<int?> cad,
      Value<int?> power,
      Value<int?> hdop,
      Value<int> flags,
      Value<int> rowid,
    });

final class $$TrackPointsTableReferences
    extends BaseReferences<_$BashoDatabase, $TrackPointsTable, TrackPoint> {
  $$TrackPointsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ActivitiesTable _activityIdTable(_$BashoDatabase db) =>
      db.activities.createAlias('track_points__activity_id__activities__id');

  $$ActivitiesTableProcessedTableManager get activityId {
    final $_column = $_itemColumn<int>('activity_id')!;

    final manager = $$ActivitiesTableTableManager(
      $_db,
      $_db.activities,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_activityIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TrackPointsTableFilterComposer
    extends Composer<_$BashoDatabase, $TrackPointsTable> {
  $$TrackPointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get tMs => $composableBuilder(
    column: $table.tMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get latE7 => $composableBuilder(
    column: $table.latE7,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lonE7 => $composableBuilder(
    column: $table.lonE7,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get altCm => $composableBuilder(
    column: $table.altCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speedMps => $composableBuilder(
    column: $table.speedMps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hr => $composableBuilder(
    column: $table.hr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cad => $composableBuilder(
    column: $table.cad,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get power => $composableBuilder(
    column: $table.power,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hdop => $composableBuilder(
    column: $table.hdop,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get flags => $composableBuilder(
    column: $table.flags,
    builder: (column) => ColumnFilters(column),
  );

  $$ActivitiesTableFilterComposer get activityId {
    final $$ActivitiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.activityId,
      referencedTable: $db.activities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActivitiesTableFilterComposer(
            $db: $db,
            $table: $db.activities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackPointsTableOrderingComposer
    extends Composer<_$BashoDatabase, $TrackPointsTable> {
  $$TrackPointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get tMs => $composableBuilder(
    column: $table.tMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get latE7 => $composableBuilder(
    column: $table.latE7,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lonE7 => $composableBuilder(
    column: $table.lonE7,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get altCm => $composableBuilder(
    column: $table.altCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speedMps => $composableBuilder(
    column: $table.speedMps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hr => $composableBuilder(
    column: $table.hr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cad => $composableBuilder(
    column: $table.cad,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get power => $composableBuilder(
    column: $table.power,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hdop => $composableBuilder(
    column: $table.hdop,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get flags => $composableBuilder(
    column: $table.flags,
    builder: (column) => ColumnOrderings(column),
  );

  $$ActivitiesTableOrderingComposer get activityId {
    final $$ActivitiesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.activityId,
      referencedTable: $db.activities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActivitiesTableOrderingComposer(
            $db: $db,
            $table: $db.activities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackPointsTableAnnotationComposer
    extends Composer<_$BashoDatabase, $TrackPointsTable> {
  $$TrackPointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get tMs =>
      $composableBuilder(column: $table.tMs, builder: (column) => column);

  GeneratedColumn<int> get latE7 =>
      $composableBuilder(column: $table.latE7, builder: (column) => column);

  GeneratedColumn<int> get lonE7 =>
      $composableBuilder(column: $table.lonE7, builder: (column) => column);

  GeneratedColumn<int> get altCm =>
      $composableBuilder(column: $table.altCm, builder: (column) => column);

  GeneratedColumn<double> get speedMps =>
      $composableBuilder(column: $table.speedMps, builder: (column) => column);

  GeneratedColumn<int> get hr =>
      $composableBuilder(column: $table.hr, builder: (column) => column);

  GeneratedColumn<int> get cad =>
      $composableBuilder(column: $table.cad, builder: (column) => column);

  GeneratedColumn<int> get power =>
      $composableBuilder(column: $table.power, builder: (column) => column);

  GeneratedColumn<int> get hdop =>
      $composableBuilder(column: $table.hdop, builder: (column) => column);

  GeneratedColumn<int> get flags =>
      $composableBuilder(column: $table.flags, builder: (column) => column);

  $$ActivitiesTableAnnotationComposer get activityId {
    final $$ActivitiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.activityId,
      referencedTable: $db.activities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActivitiesTableAnnotationComposer(
            $db: $db,
            $table: $db.activities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackPointsTableTableManager
    extends
        RootTableManager<
          _$BashoDatabase,
          $TrackPointsTable,
          TrackPoint,
          $$TrackPointsTableFilterComposer,
          $$TrackPointsTableOrderingComposer,
          $$TrackPointsTableAnnotationComposer,
          $$TrackPointsTableCreateCompanionBuilder,
          $$TrackPointsTableUpdateCompanionBuilder,
          (TrackPoint, $$TrackPointsTableReferences),
          TrackPoint,
          PrefetchHooks Function({bool activityId})
        > {
  $$TrackPointsTableTableManager(_$BashoDatabase db, $TrackPointsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrackPointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrackPointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrackPointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> activityId = const Value.absent(),
                Value<int> tMs = const Value.absent(),
                Value<int> latE7 = const Value.absent(),
                Value<int> lonE7 = const Value.absent(),
                Value<int?> altCm = const Value.absent(),
                Value<double?> speedMps = const Value.absent(),
                Value<int?> hr = const Value.absent(),
                Value<int?> cad = const Value.absent(),
                Value<int?> power = const Value.absent(),
                Value<int?> hdop = const Value.absent(),
                Value<int> flags = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrackPointsCompanion(
                activityId: activityId,
                tMs: tMs,
                latE7: latE7,
                lonE7: lonE7,
                altCm: altCm,
                speedMps: speedMps,
                hr: hr,
                cad: cad,
                power: power,
                hdop: hdop,
                flags: flags,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int activityId,
                required int tMs,
                required int latE7,
                required int lonE7,
                Value<int?> altCm = const Value.absent(),
                Value<double?> speedMps = const Value.absent(),
                Value<int?> hr = const Value.absent(),
                Value<int?> cad = const Value.absent(),
                Value<int?> power = const Value.absent(),
                Value<int?> hdop = const Value.absent(),
                Value<int> flags = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrackPointsCompanion.insert(
                activityId: activityId,
                tMs: tMs,
                latE7: latE7,
                lonE7: lonE7,
                altCm: altCm,
                speedMps: speedMps,
                hr: hr,
                cad: cad,
                power: power,
                hdop: hdop,
                flags: flags,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TrackPointsTable, TrackPoint>(table),
                  $$TrackPointsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({activityId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (activityId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.activityId,
                        referencedTable: $$TrackPointsTableReferences
                            ._activityIdTable(db),
                        referencedColumn: $$TrackPointsTableReferences
                            ._activityIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TrackPointsTableProcessedTableManager =
    ProcessedTableManager<
      _$BashoDatabase,
      $TrackPointsTable,
      TrackPoint,
      $$TrackPointsTableFilterComposer,
      $$TrackPointsTableOrderingComposer,
      $$TrackPointsTableAnnotationComposer,
      $$TrackPointsTableCreateCompanionBuilder,
      $$TrackPointsTableUpdateCompanionBuilder,
      (TrackPoint, $$TrackPointsTableReferences),
      TrackPoint,
      PrefetchHooks Function({bool activityId})
    >;
typedef $$LapsTableCreateCompanionBuilder = LapsCompanion Function({
  required int activityId,
  required int idx,
  required int startT,
  required int endT,
  Value<double> distM,
  Value<int> rowid,
});
typedef $$LapsTableUpdateCompanionBuilder = LapsCompanion Function({
  Value<int> activityId,
  Value<int> idx,
  Value<int> startT,
  Value<int> endT,
  Value<double> distM,
  Value<int> rowid,
});

final class $$LapsTableReferences
    extends BaseReferences<_$BashoDatabase, $LapsTable, Lap> {
  $$LapsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ActivitiesTable _activityIdTable(_$BashoDatabase db) =>
      db.activities.createAlias('laps__activity_id__activities__id');

  $$ActivitiesTableProcessedTableManager get activityId {
    final $_column = $_itemColumn<int>('activity_id')!;

    final manager = $$ActivitiesTableTableManager(
      $_db,
      $_db.activities,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_activityIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LapsTableFilterComposer extends Composer<_$BashoDatabase, $LapsTable> {
  $$LapsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get idx => $composableBuilder(
    column: $table.idx,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startT => $composableBuilder(
    column: $table.startT,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endT => $composableBuilder(
    column: $table.endT,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distM => $composableBuilder(
    column: $table.distM,
    builder: (column) => ColumnFilters(column),
  );

  $$ActivitiesTableFilterComposer get activityId {
    final $$ActivitiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.activityId,
      referencedTable: $db.activities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActivitiesTableFilterComposer(
            $db: $db,
            $table: $db.activities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LapsTableOrderingComposer
    extends Composer<_$BashoDatabase, $LapsTable> {
  $$LapsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get idx => $composableBuilder(
    column: $table.idx,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startT => $composableBuilder(
    column: $table.startT,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endT => $composableBuilder(
    column: $table.endT,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distM => $composableBuilder(
    column: $table.distM,
    builder: (column) => ColumnOrderings(column),
  );

  $$ActivitiesTableOrderingComposer get activityId {
    final $$ActivitiesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.activityId,
      referencedTable: $db.activities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActivitiesTableOrderingComposer(
            $db: $db,
            $table: $db.activities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LapsTableAnnotationComposer
    extends Composer<_$BashoDatabase, $LapsTable> {
  $$LapsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get idx =>
      $composableBuilder(column: $table.idx, builder: (column) => column);

  GeneratedColumn<int> get startT =>
      $composableBuilder(column: $table.startT, builder: (column) => column);

  GeneratedColumn<int> get endT =>
      $composableBuilder(column: $table.endT, builder: (column) => column);

  GeneratedColumn<double> get distM =>
      $composableBuilder(column: $table.distM, builder: (column) => column);

  $$ActivitiesTableAnnotationComposer get activityId {
    final $$ActivitiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.activityId,
      referencedTable: $db.activities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActivitiesTableAnnotationComposer(
            $db: $db,
            $table: $db.activities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LapsTableTableManager
    extends
        RootTableManager<
          _$BashoDatabase,
          $LapsTable,
          Lap,
          $$LapsTableFilterComposer,
          $$LapsTableOrderingComposer,
          $$LapsTableAnnotationComposer,
          $$LapsTableCreateCompanionBuilder,
          $$LapsTableUpdateCompanionBuilder,
          (Lap, $$LapsTableReferences),
          Lap,
          PrefetchHooks Function({bool activityId})
        > {
  $$LapsTableTableManager(_$BashoDatabase db, $LapsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LapsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LapsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LapsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> activityId = const Value.absent(),
                Value<int> idx = const Value.absent(),
                Value<int> startT = const Value.absent(),
                Value<int> endT = const Value.absent(),
                Value<double> distM = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LapsCompanion(
                activityId: activityId,
                idx: idx,
                startT: startT,
                endT: endT,
                distM: distM,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int activityId,
                required int idx,
                required int startT,
                required int endT,
                Value<double> distM = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LapsCompanion.insert(
                activityId: activityId,
                idx: idx,
                startT: startT,
                endT: endT,
                distM: distM,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LapsTable, Lap>(table),
                  $$LapsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({activityId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (activityId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.activityId,
                        referencedTable: $$LapsTableReferences._activityIdTable(
                          db,
                        ),
                        referencedColumn: $$LapsTableReferences
                            ._activityIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LapsTableProcessedTableManager =
    ProcessedTableManager<
      _$BashoDatabase,
      $LapsTable,
      Lap,
      $$LapsTableFilterComposer,
      $$LapsTableOrderingComposer,
      $$LapsTableAnnotationComposer,
      $$LapsTableCreateCompanionBuilder,
      $$LapsTableUpdateCompanionBuilder,
      (Lap, $$LapsTableReferences),
      Lap,
      PrefetchHooks Function({bool activityId})
    >;
typedef $$DraftsTableCreateCompanionBuilder = DraftsCompanion Function({
  Value<int> id,
  Value<String> type,
  required DateTime startedAt,
  Value<int> totalS,
  Value<double> distanceKm,
  Value<int> laps,
});
typedef $$DraftsTableUpdateCompanionBuilder = DraftsCompanion Function({
  Value<int> id,
  Value<String> type,
  Value<DateTime> startedAt,
  Value<int> totalS,
  Value<double> distanceKm,
  Value<int> laps,
});

class $$DraftsTableFilterComposer
    extends Composer<_$BashoDatabase, $DraftsTable> {
  $$DraftsTableFilterComposer({
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalS => $composableBuilder(
    column: $table.totalS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceKm => $composableBuilder(
    column: $table.distanceKm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get laps => $composableBuilder(
    column: $table.laps,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DraftsTableOrderingComposer
    extends Composer<_$BashoDatabase, $DraftsTable> {
  $$DraftsTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalS => $composableBuilder(
    column: $table.totalS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceKm => $composableBuilder(
    column: $table.distanceKm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get laps => $composableBuilder(
    column: $table.laps,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DraftsTableAnnotationComposer
    extends Composer<_$BashoDatabase, $DraftsTable> {
  $$DraftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get totalS =>
      $composableBuilder(column: $table.totalS, builder: (column) => column);

  GeneratedColumn<double> get distanceKm => $composableBuilder(
    column: $table.distanceKm,
    builder: (column) => column,
  );

  GeneratedColumn<int> get laps =>
      $composableBuilder(column: $table.laps, builder: (column) => column);
}

class $$DraftsTableTableManager
    extends
        RootTableManager<
          _$BashoDatabase,
          $DraftsTable,
          Draft,
          $$DraftsTableFilterComposer,
          $$DraftsTableOrderingComposer,
          $$DraftsTableAnnotationComposer,
          $$DraftsTableCreateCompanionBuilder,
          $$DraftsTableUpdateCompanionBuilder,
          (Draft, BaseReferences<_$BashoDatabase, $DraftsTable, Draft>),
          Draft,
          PrefetchHooks Function()
        > {
  $$DraftsTableTableManager(_$BashoDatabase db, $DraftsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DraftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DraftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DraftsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<int> totalS = const Value.absent(),
                Value<double> distanceKm = const Value.absent(),
                Value<int> laps = const Value.absent(),
              }) => DraftsCompanion(
                id: id,
                type: type,
                startedAt: startedAt,
                totalS: totalS,
                distanceKm: distanceKm,
                laps: laps,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                required DateTime startedAt,
                Value<int> totalS = const Value.absent(),
                Value<double> distanceKm = const Value.absent(),
                Value<int> laps = const Value.absent(),
              }) => DraftsCompanion.insert(
                id: id,
                type: type,
                startedAt: startedAt,
                totalS: totalS,
                distanceKm: distanceKm,
                laps: laps,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DraftsTable, Draft>(table),
                  BaseReferences<_$BashoDatabase, $DraftsTable, Draft>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DraftsTableProcessedTableManager =
    ProcessedTableManager<
      _$BashoDatabase,
      $DraftsTable,
      Draft,
      $$DraftsTableFilterComposer,
      $$DraftsTableOrderingComposer,
      $$DraftsTableAnnotationComposer,
      $$DraftsTableCreateCompanionBuilder,
      $$DraftsTableUpdateCompanionBuilder,
      (Draft, BaseReferences<_$BashoDatabase, $DraftsTable, Draft>),
      Draft,
      PrefetchHooks Function()
    >;
typedef $$SummaryCacheTableCreateCompanionBuilder =
    SummaryCacheCompanion Function({
      required String periodKind,
      required String bucketKey,
      Value<double> km,
      Value<double> min,
      Value<double> elev,
      Value<int> cnt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$SummaryCacheTableUpdateCompanionBuilder =
    SummaryCacheCompanion Function({
      Value<String> periodKind,
      Value<String> bucketKey,
      Value<double> km,
      Value<double> min,
      Value<double> elev,
      Value<int> cnt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$SummaryCacheTableFilterComposer
    extends Composer<_$BashoDatabase, $SummaryCacheTable> {
  $$SummaryCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get periodKind => $composableBuilder(
    column: $table.periodKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bucketKey => $composableBuilder(
    column: $table.bucketKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get km => $composableBuilder(
    column: $table.km,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get min => $composableBuilder(
    column: $table.min,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get elev => $composableBuilder(
    column: $table.elev,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cnt => $composableBuilder(
    column: $table.cnt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SummaryCacheTableOrderingComposer
    extends Composer<_$BashoDatabase, $SummaryCacheTable> {
  $$SummaryCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get periodKind => $composableBuilder(
    column: $table.periodKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bucketKey => $composableBuilder(
    column: $table.bucketKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get km => $composableBuilder(
    column: $table.km,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get min => $composableBuilder(
    column: $table.min,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get elev => $composableBuilder(
    column: $table.elev,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cnt => $composableBuilder(
    column: $table.cnt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SummaryCacheTableAnnotationComposer
    extends Composer<_$BashoDatabase, $SummaryCacheTable> {
  $$SummaryCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get periodKind => $composableBuilder(
    column: $table.periodKind,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bucketKey =>
      $composableBuilder(column: $table.bucketKey, builder: (column) => column);

  GeneratedColumn<double> get km =>
      $composableBuilder(column: $table.km, builder: (column) => column);

  GeneratedColumn<double> get min =>
      $composableBuilder(column: $table.min, builder: (column) => column);

  GeneratedColumn<double> get elev =>
      $composableBuilder(column: $table.elev, builder: (column) => column);

  GeneratedColumn<int> get cnt =>
      $composableBuilder(column: $table.cnt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SummaryCacheTableTableManager
    extends
        RootTableManager<
          _$BashoDatabase,
          $SummaryCacheTable,
          SummaryCacheData,
          $$SummaryCacheTableFilterComposer,
          $$SummaryCacheTableOrderingComposer,
          $$SummaryCacheTableAnnotationComposer,
          $$SummaryCacheTableCreateCompanionBuilder,
          $$SummaryCacheTableUpdateCompanionBuilder,
          (
            SummaryCacheData,
            BaseReferences<
              _$BashoDatabase,
              $SummaryCacheTable,
              SummaryCacheData
            >,
          ),
          SummaryCacheData,
          PrefetchHooks Function()
        > {
  $$SummaryCacheTableTableManager(_$BashoDatabase db, $SummaryCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SummaryCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SummaryCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SummaryCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> periodKind = const Value.absent(),
                Value<String> bucketKey = const Value.absent(),
                Value<double> km = const Value.absent(),
                Value<double> min = const Value.absent(),
                Value<double> elev = const Value.absent(),
                Value<int> cnt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SummaryCacheCompanion(
                periodKind: periodKind,
                bucketKey: bucketKey,
                km: km,
                min: min,
                elev: elev,
                cnt: cnt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String periodKind,
                required String bucketKey,
                Value<double> km = const Value.absent(),
                Value<double> min = const Value.absent(),
                Value<double> elev = const Value.absent(),
                Value<int> cnt = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SummaryCacheCompanion.insert(
                periodKind: periodKind,
                bucketKey: bucketKey,
                km: km,
                min: min,
                elev: elev,
                cnt: cnt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SummaryCacheTable, SummaryCacheData>(table),
                  BaseReferences<
                    _$BashoDatabase,
                    $SummaryCacheTable,
                    SummaryCacheData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SummaryCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$BashoDatabase,
      $SummaryCacheTable,
      SummaryCacheData,
      $$SummaryCacheTableFilterComposer,
      $$SummaryCacheTableOrderingComposer,
      $$SummaryCacheTableAnnotationComposer,
      $$SummaryCacheTableCreateCompanionBuilder,
      $$SummaryCacheTableUpdateCompanionBuilder,
      (
        SummaryCacheData,
        BaseReferences<_$BashoDatabase, $SummaryCacheTable, SummaryCacheData>,
      ),
      SummaryCacheData,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  Value<String?> value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String?> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$BashoDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$BashoDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$BashoDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$BashoDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$BashoDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$BashoDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String?> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            Value<String?> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, Setting>(table),
                  BaseReferences<_$BashoDatabase, $SettingsTable, Setting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$BashoDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$BashoDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;

class $BashoDatabaseManager {
  final _$BashoDatabase _db;
  $BashoDatabaseManager(this._db);
  $$ActivitiesTableTableManager get activities =>
      $$ActivitiesTableTableManager(_db, _db.activities);
  $$TrackPointsTableTableManager get trackPoints =>
      $$TrackPointsTableTableManager(_db, _db.trackPoints);
  $$LapsTableTableManager get laps => $$LapsTableTableManager(_db, _db.laps);
  $$DraftsTableTableManager get drafts =>
      $$DraftsTableTableManager(_db, _db.drafts);
  $$SummaryCacheTableTableManager get summaryCache =>
      $$SummaryCacheTableTableManager(_db, _db.summaryCache);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
