import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import 'package:basho/domain/nav/route_navigator.dart';

void main() {
  // 路线：向北 1km，再向东 1km（共约 2km，向北后右转）
  const start = LatLng(22.5000, 113.9000);
  const corner = LatLng(22.5000 + 1000 / 111320, 113.9000);
  const end = LatLng(22.5000 + 1000 / 111320, 113.9000 + 1000 / (111320 * 0.9239));
  final nav = RouteNavigator(const [start, corner, end]);

  test('总距离约 2km', () {
    expect(nav.totalM, closeTo(2000, 30));
  });

  test('起点：剩余≈2km，前方 1km 处右转', () {
    final p = nav.update(start);
    expect(p.remainingM, closeTo(2000, 30));
    expect(p.offRouteM, lessThan(5));
    expect(p.turnDir, TurnDir.right);
    expect(p.turnInM, closeTo(1000, 30));
    expect(p.arrived, isFalse);
  });

  test('到达转角处：已前进≈1km，剩余≈1km，下一段直行', () {
    final p = nav.update(corner);
    expect(p.alongM, closeTo(1000, 30));
    expect(p.remainingM, closeTo(1000, 30));
    expect(p.turnDir, TurnDir.straight);
  });

  test('到达终点：arrived=true', () {
    final p = nav.update(end);
    expect(p.arrived, isTrue);
    expect(p.progress, closeTo(1.0, 0.02));
  });

  test('偏航：偏离路线 200m 会被识别', () {
    final off = LatLng(start.latitude, start.longitude + 200 / (111320 * 0.9239));
    final p = nav.update(off);
    expect(p.offRouteM, closeTo(200, 20));
    expect(p.offRoute, isTrue);
  });

  test('已骑/未骑分段点：在 500m 处切分', () {
    final p = nav.update(LatLng(start.latitude + 500 / 111320, start.longitude));
    final done = nav.donePoints(p.alongM);
    final todo = nav.todoPoints(p.alongM);
    expect(done.length, greaterThanOrEqualTo(2));
    expect(todo.length, greaterThanOrEqualTo(2));
    // 切分点应约在 500m 处（纬度 +0.0045）
    expect(done.last.latitude, closeTo(start.latitude + 500 / 111320, 1e-4));
  });
}
