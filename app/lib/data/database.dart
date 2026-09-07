import 'package:drift/drift.dart';

part 'database.g.dart';

/// 活动（一次骑行）
class Activities extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withDefault(const Constant('骑行'))();
  TextColumn get type => text().withDefault(const Constant('公路'))();
  DateTimeColumn get startAt => dateTime()();
  DateTimeColumn get endAt => dateTime().nullable()();
  IntColumn get durationS => integer().withDefault(const Constant(0))();
  IntColumn get movingS => integer().withDefault(const Constant(0))();
  RealColumn get distanceM => real().withDefault(const Constant(0))();
  RealColumn get elevGainM => real().withDefault(const Constant(0))();
  RealColumn get elevLossM => real().withDefault(const Constant(0))();
  IntColumn get hrAvg => integer().nullable()();
  IntColumn get hrMax => integer().nullable()();
  IntColumn get kcal => integer().withDefault(const Constant(0))();
  TextColumn get source => text().withDefault(const Constant('手机'))();
  TextColumn get note => text().withDefault(const Constant(''))();
}

/// 轨迹点（落库抽稀后；整型坐标压缩）
class TrackPoints extends Table {
  IntColumn get activityId => integer().references(Activities, #id)();
  IntColumn get tMs => integer()(); // unix millis
  IntColumn get latE7 => integer()(); // lat * 1e7
  IntColumn get lonE7 => integer()(); // lon * 1e7
  IntColumn get altCm => integer().nullable()(); // 海拔 cm
  RealColumn get speedMps => real().nullable()();
  IntColumn get hr => integer().nullable()();
  IntColumn get cad => integer().nullable()();
  IntColumn get power => integer().nullable()();
  IntColumn get hdop => integer().nullable()();
  IntColumn get flags => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {activityId, tMs};
}

/// 计圈
class Laps extends Table {
  IntColumn get activityId => integer().references(Activities, #id)();
  IntColumn get idx => integer()();
  IntColumn get startT => integer()();
  IntColumn get endT => integer()();
  RealColumn get distM => real().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {activityId, idx};
}

/// 记录会话草稿（崩溃恢复唯一权威）
class Drafts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text().withDefault(const Constant('公路'))();
  DateTimeColumn get startedAt => dateTime()();
  IntColumn get totalS => integer().withDefault(const Constant(0))();
  RealColumn get distanceKm => real().withDefault(const Constant(0))();
  IntColumn get laps => integer().withDefault(const Constant(0))();
}

/// 聚合缓存（周期桶，写入/删除活动时增量更新；统计页零扫描）
class SummaryCache extends Table {
  TextColumn get periodKind => text()(); // today|week|month|day:<key>|week:<key>...
  TextColumn get bucketKey => text()(); // 桶标识（如 2026-09-07 / 2026-W36 / 2026-09）
  RealColumn get km => real().withDefault(const Constant(0))();
  RealColumn get min => real().withDefault(const Constant(0))();
  RealColumn get elev => real().withDefault(const Constant(0))();
  IntColumn get cnt => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {periodKind, bucketKey};
}

/// 用户设置 KV
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text().nullable()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Activities, TrackPoints, Laps, Drafts, SummaryCache, Settings])
class BashoDatabase extends _$BashoDatabase {
  BashoDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
