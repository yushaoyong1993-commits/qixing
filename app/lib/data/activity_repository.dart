import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/stats/aggregate.dart';
import 'database.dart';

export 'database.dart';

/// 打开应用的持久化数据库（移动端/桌面：Documents 目录下的 basho.db）。
Future<BashoDatabase> openBashoDatabase() async {
  final dir = await getApplicationDocumentsDirectory();
  final file = p.join(dir.path, 'basho.db');
  return _openFile(file);
}

/// 测试用：内存数据库。
Future<BashoDatabase> openInMemoryDatabase() async {
  return BashoDatabase(NativeDatabase.memory());
}

BashoDatabase _openFile(String path) {
  return BashoDatabase(LazyDatabase(() async {
    final file = File(path);
    return NativeDatabase.createInBackground(file);
  }));
}

/// 活动仓库：负责把 DB 的 Activity 映射为领域层 [RideLite]，供聚合内核使用。
class ActivityRepository {
  ActivityRepository(this._db);

  final BashoDatabase _db;

  /// 全部活动（倒序），映射为 [RideLite]（距离/时长/爬升换算为 km 与 min）。
  Stream<List<RideLite>> watchRides() {
    final q = _db.select(_db.activities)
      ..orderBy([(t) => OrderingTerm.desc(t.startAt)]);
    return q.watch().map((rows) => rows.map(_toRide).toList());
  }

  Future<List<RideLite>> rides() async {
    final rows = await (_db.select(_db.activities)
          ..orderBy([(t) => OrderingTerm.desc(t.startAt)])).get();
    return rows.map(_toRide).toList();
  }

  /// 保存一次骑行（记录摘要落库；轨迹在后续 M1 增量实现）。
  Future<int> saveRide({
    required String name,
    required String type,
    required DateTime startAt,
    required int durationS,
    required int movingS,
    required double distanceM,
    required double elevGainM,
    required double elevLossM,
    int? hrAvg,
    int? hrMax,
    int kcal = 0,
    String source = '手机',
    String note = '',
  }) {
    return _db.into(_db.activities).insert(ActivitiesCompanion.insert(
          name: Value(name),
          type: Value(type),
          startAt: startAt,
          endAt: Value(DateTime.now()),
          durationS: Value(durationS),
          movingS: Value(movingS),
          distanceM: Value(distanceM),
          elevGainM: Value(elevGainM),
          elevLossM: Value(elevLossM),
          hrAvg: Value(hrAvg),
          hrMax: Value(hrMax),
          kcal: Value(kcal),
          source: Value(source),
          note: Value(note),
        ));
  }

  Future<void> deleteRide(int id) {
    return (_db.delete(_db.activities)..where((t) => t.id.equals(id))).go();
  }

  Future<void> updateMeta(int id, {String? name, String? type, String? note}) {
    final patch = ActivitiesCompanion(
      name: name == null ? const Value.absent() : Value(name),
      type: type == null ? const Value.absent() : Value(type),
      note: note == null ? const Value.absent() : Value(note),
    );
    return (_db.update(_db.activities)..where((t) => t.id.equals(id))).write(patch);
  }

  // —— 草稿（崩溃恢复，RCD-07）——
  Future<void> saveDraft({
    required String type,
    required DateTime startedAt,
    required int totalS,
    required double distanceKm,
    required int laps,
  }) {
    return _db.into(_db.drafts).insert(DraftsCompanion.insert(
          type: Value(type),
          startedAt: startedAt,
          totalS: Value(totalS),
          distanceKm: Value(distanceKm),
          laps: Value(laps),
        ));
  }

  Future<DraftData?> loadDraft() async {
    final rows = await (_db.select(_db.drafts)
          ..orderBy([(t) => OrderingTerm.desc(t.id)])
          ..limit(1)).get();
    if (rows.isEmpty) return null;
    final d = rows.first;
    return DraftData(type: d.type, startedAt: d.startedAt, totalS: d.totalS, distanceKm: d.distanceKm, laps: d.laps);
  }

  Future<void> deleteDraft() {
    return _db.delete(_db.drafts).go();
  }

  // —— 轨迹点 ——
  Future<void> saveTrackPoints(int activityId, List<SimpleTrack> points) async {
    if (points.isEmpty) return;
    await _db.batch((b) {
      b.insertAll(_db.trackPoints, [
        for (final p in points)
          TrackPointsCompanion.insert(
            activityId: activityId,
            tMs: p.tMs,
            latE7: (p.lat * 1e7).round(),
            lonE7: (p.lon * 1e7).round(),
            altCm: Value(p.altM == null ? null : (p.altM! * 100).round()),
            speedMps: Value(p.speedMps),
          ),
      ]);
    });
  }

  Future<List<SimpleTrack>> trackPointsFor(int activityId) async {
    final q = _db.select(_db.trackPoints)
      ..where((t) => t.activityId.equals(activityId))
      ..orderBy([(t) => OrderingTerm.asc(t.tMs)]);
    final rows = await q.get();
    return rows.map((r) => SimpleTrack(
          tMs: r.tMs,
          lat: r.latE7 / 1e7,
          lon: r.lonE7 / 1e7,
          altM: r.altCm == null ? null : r.altCm! / 100,
          speedMps: r.speedMps,
        )).toList();
  }

  RideLite _toRide(Activity a) => RideLite(
        id: a.id,
        startAt: a.startAt,
        distanceKm: a.distanceM / 1000,
        durationMin: a.movingS / 60,
        elevGainM: a.elevGainM,
      );
}

/// 记录会话草稿（用于崩溃恢复）。
class DraftData {
  const DraftData({
    required this.type,
    required this.startedAt,
    required this.totalS,
    required this.distanceKm,
    required this.laps,
  });
  final String type;
  final DateTime startedAt;
  final int totalS;
  final double distanceKm;
  final int laps;
}


/// 轨迹点（读写视图）。
class SimpleTrack {
  const SimpleTrack({
    required this.tMs,
    required this.lat,
    required this.lon,
    this.altM,
    this.speedMps,
  });
  final int tMs;
  final double lat;
  final double lon;
  final double? altM;
  final double? speedMps;
}
