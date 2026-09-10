import 'package:drift/drift.dart';

import 'database.dart';

/// 路线（领域模型）。
class RouteModel {
  const RouteModel({
    required this.id,
    required this.name,
    required this.points,
    required this.distKm,
    required this.createdAt,
  });

  final int id;
  final String name;
  /// 路线点：[lat, lng]（全高德方案下为 GCJ-02 经纬度）。
  final List<List<double>> points;
  final double distKm;
  final DateTime createdAt;
}

/// 路线仓库：手绘路线（MP-10 纯数据版）存 Routes 表。
class RouteRepository {
  RouteRepository(this._db);

  final BashoDatabase _db;

  Stream<List<RouteModel>> watchRoutes() {
    final q = _db.select(_db.routes)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return q.watch().map((rows) => rows.map(_toModel).toList());
  }

  Future<int> addRoute({
    required String name,
    required List<List<double>> points,
    required double distKm,
  }) {
    return _db.into(_db.routes).insert(RoutesCompanion.insert(
          name: name,
          pointsJson: _encode(points),
          distKm: Value(distKm),
          createdAt: DateTime.now(),
        ));
  }

  Future<void> updateRoute({
    required int id,
    required String name,
    required List<List<double>> points,
    required double distKm,
  }) {
    return (_db.update(_db.routes)..where((t) => t.id.equals(id))).write(
      RoutesCompanion(
        name: Value(name),
        pointsJson: Value(_encode(points)),
        distKm: Value(distKm),
      ),
    );
  }

  Future<void> deleteRoute(int id) {
    return (_db.delete(_db.routes)..where((t) => t.id.equals(id))).go();
  }

  RouteModel _toModel(Route r) => RouteModel(
        id: r.id,
        name: r.name,
        points: _decode(r.pointsJson),
        distKm: r.distKm,
        createdAt: r.createdAt,
      );

  static String _encode(List<List<double>> pts) =>
      pts.map((p) => '${p[0].toStringAsFixed(6)},${p[1].toStringAsFixed(6)}').join(';');

  static List<List<double>> _decode(String s) => s
      .split(';')
      .where((e) => e.contains(','))
      .map((e) {
        final parts = e.split(',');
        return [double.tryParse(parts[0]) ?? 0, double.tryParse(parts[1]) ?? 0];
      })
      .toList();
}
