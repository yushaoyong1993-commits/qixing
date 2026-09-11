import 'package:drift/drift.dart';

import 'database.dart';

/// 设置仓库：Settings 表（key-value）读写 + 数据统计/清理。
class SettingsRepository {
  SettingsRepository(this._db);

  final BashoDatabase _db;

  Stream<Map<String, String>> watchAll() =>
      _db.select(_db.settings).watch().map((rows) => {
            for (final r in rows) r.key: (r.value ?? ''),
          });

  Future<String?> get(String key) async {
    final row = await (_db.select(_db.settings)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> set(String key, String value) =>
      _db.into(_db.settings).insertOnConflictUpdate(
            SettingsCompanion.insert(key: key, value: Value(value)),
          );

  /// 数据量统计（设置页"数据"区块）
  Future<Map<String, int>> counts() async {
    Future<int> one(String sql) async {
      final row = await _db.customSelect(sql).getSingle();
      return row.data.values.first as int? ?? 0;
    }

    return {
      'activities': await one('SELECT COUNT(*) AS c FROM activities'),
      'tracks': await one('SELECT COUNT(*) AS c FROM track_points'),
      'routes': await one('SELECT COUNT(*) AS c FROM routes'),
    };
  }

  /// 清空草稿（保留已保存数据）
  Future<void> clearDrafts() => _db.delete(_db.drafts).go();

  /// 清除全部本地数据（活动/轨迹点/路线/草稿）
  Future<void> clearAll() async {
    await _db.delete(_db.trackPoints).go();
    await _db.delete(_db.activities).go();
    await _db.delete(_db.routes).go();
    await _db.delete(_db.drafts).go();
  }
}
