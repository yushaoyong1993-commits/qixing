import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import 'package:basho/core/periods.dart';
import 'package:basho/core/units.dart';
import 'package:basho/data/activity_repository.dart';
import 'package:basho/data/gpx.dart';
import 'package:basho/data/route_repository.dart';
import 'package:basho/data/settings_repository.dart';
import 'package:basho/domain/nav/route_navigator.dart';
import 'package:basho/domain/record/session_machine.dart';
import 'package:basho/domain/stats/aggregate.dart' as k;

/// ST 系统测试（数据/服务层）：覆盖功能点及其跨模块关联。
void main() {
  late BashoDatabase db;
  late ActivityRepository act;
  late RouteRepository routes;
  late SettingsRepository settings;

  setUp(() async {
    db = await openInMemoryDatabase();
    act = ActivityRepository(db);
    routes = RouteRepository(db);
    settings = SettingsRepository(db);
  });

  tearDown(() async => db.close());

  Future<Map<String, String>> settingsMap() async {
    final rows = await db.select(db.settings).get();
    return {for (final r in rows) r.key: (r.value ?? '')};
  }


  Future<int> saveOne({
    String name = '系统测试骑行',
    String type = '公路',
    DateTime? at,
    double km = 20,
    int min = 60,
    double elev = 100,
  }) =>
      act.saveRide(
        name: name,
        type: type,
        startAt: at ?? DateTime(2026, 9, 11, 8),
        durationS: min * 60,
        movingS: min * 60,
        distanceM: km * 1000,
        elevGainM: elev,
        elevLossM: elev * 0.8,
        hrAvg: null,
        hrMax: null,
        kcal: (km * 24).round(),
      );

  // ---------- ST-D01 记录→保存→统计链路 ----------
  test('ST-D01 记录会话→保存→聚合可见（距离/时长/爬升口径一致）', () async {
    final m = SessionMachine();
    m.start(autoLapKm: 5);
    m.tickSec(1800);
    for (var i = 0; i < 10; i++) {
      m.addSample(distKm: 0.5, elevM: 3);
    }
    m.finish();

    final id = await act.saveRide(
      name: '链路测试',
      type: '训练',
      startAt: DateTime(2026, 9, 11, 7),
      durationS: m.elapsedSec,
      movingS: m.movingSec,
      distanceM: m.distanceKm * 1000,
      elevGainM: m.elevGainM,
      elevLossM: m.elevGainM * 0.9,
      hrAvg: null,
      hrMax: null,
      kcal: (m.distanceKm * 24).round(),
    );
    await act.saveLaps(
      id,
      [
        for (final l in m.laps)
          LapRecord(
            idx: l.index,
            startAt: DateTime(2026, 9, 11, 7).add(Duration(seconds: l.startSec)),
            endAt: DateTime(2026, 9, 11, 7).add(Duration(seconds: l.endSec)),
            distM: l.distanceKm * 1000,
          ),
      ],
    );

    final rides = await act.rides();
    expect(rides.length, 1);
    expect(rides.first.distanceKm, closeTo(5.0, 1e-6));
    expect(rides.first.durationMin, closeTo(30, 1e-6));
    expect(rides.first.elevGainM, closeTo(30, 1e-6));

    final laps = await act.lapsFor(id);
    // 自动圈恰好封在 5.0km 终点 → 不产生空的收尾圈
    expect(laps.length, 1, reason: '恰好 5km 收尾时不产生空圈');
    expect(laps.first.km, closeTo(5.0, 1e-6));
    expect(laps.first.seconds, greaterThan(0));

    // 再骑一点后结束 → 应生成第 2 圈（收尾圈）
    final m2 = SessionMachine();
    m2.start(autoLapKm: 5);
    m2.tickSec(100);
    m2.addSample(distKm: 5.5);
    m2.tickSec(100);
    m2.addSample(distKm: 0.5);
    m2.finish();
    expect(m2.laps.length, 2);
    expect(m2.laps.last.distanceKm, closeTo(0.5, 1e-6));
  });

  // ---------- ST-D02 删除活动必须级联清理轨迹与分段 ----------
  test('ST-D02 删除活动应级联删除轨迹点与分段（无孤儿数据）', () async {
    final id = await saveOne();
    final start = DateTime(2026, 9, 11, 8);
    await act.saveTrackPoints(id, [
      SimpleTrack(tMs: start.millisecondsSinceEpoch, lat: 22.5, lon: 113.9),
      SimpleTrack(
          tMs: start.millisecondsSinceEpoch + 10000, lat: 22.51, lon: 113.91),
    ]);
    await act.saveLaps(id, [
      LapRecord(idx: 1, startAt: start, endAt: start.add(const Duration(minutes: 5)), distM: 2000),
    ]);

    await act.deleteRide(id);

    expect(await act.rides(), isEmpty);
    expect(await act.trackPointsFor(id), isEmpty, reason: '轨迹点应随活动删除');
    expect(await act.lapsFor(id), isEmpty, reason: '分段应随活动删除');
  });

  // ---------- ST-D03 GPX 导出→解析往返 ----------
  test('ST-D03 活动轨迹导出 GPX 后可被重新解析（坐标/海拔/时间一致）', () async {
    final id = await saveOne(km: 5);
    final base = DateTime.utc(2026, 9, 11, 1);
    final pts = [
      SimpleTrack(tMs: base.millisecondsSinceEpoch, lat: 22.5, lon: 113.9, altM: 12),
      SimpleTrack(
          tMs: base.millisecondsSinceEpoch + 60000, lat: 22.51, lon: 113.91, altM: 45),
    ];
    await act.saveTrackPoints(id, pts);

    final stored = await act.trackPointsFor(id);
    final xml = Gpx.build(name: '往返', points: stored);
    final back = Gpx.parse(xml);

    expect(back.length, stored.length);
    expect(back.first.lat, closeTo(stored.first.lat, 1e-6));
    expect(back.first.altM, closeTo(12, 0.2));
    expect(back.first.tMs, stored.first.tMs);
    final (km, _) = Gpx.stats(back);
    expect(km, greaterThan(0));
  });

  // ---------- ST-D04 GPX 导入：文件名去扩展名 + 类型/来源正确 ----------
  test('ST-D04 GPX 导入活动名去掉 .gpx 后缀且类型为导入', () async {
    // 直接调用解析 + 落库（避开文件选择器插件）
    final xml = Gpx.build(name: 'x', points: [
      SimpleTrack(tMs: DateTime.utc(2026, 9, 11, 1).millisecondsSinceEpoch, lat: 22.5, lon: 113.9),
      SimpleTrack(
          tMs: DateTime.utc(2026, 9, 11, 1, 5).millisecondsSinceEpoch, lat: 22.52, lon: 113.92),
    ]);
    final pts = Gpx.parse(xml);
    final name = Gpx.stripGpxExtension('晨骑记录.gpx');
    expect(name, '晨骑记录', reason: '导入的名称应去掉 .gpx 后缀');

    final id = await act.saveRide(
      name: name,
      type: '导入',
      startAt: DateTime.fromMillisecondsSinceEpoch(pts.first.tMs),
      durationS: 300,
      movingS: 300,
      distanceM: Gpx.stats(pts).$1 * 1000,
      elevGainM: 0,
      elevLossM: 0,
      hrAvg: null,
      hrMax: null,
      source: '导入',
    );
    await act.saveTrackPoints(id, pts); // 导入流程会把轨迹一并落库
    final rides = await act.rides();
    expect(rides.single.type, '导入');
    expect(rides.single.name, '晨骑记录');
    expect(await act.trackPointsFor(id), isNotEmpty);
  });

  // ---------- ST-D05 单位切换只影响显示 ----------
  test('ST-D05 单位切换：存储值不变，仅显示换算', () async {
    await saveOne(km: 10, elev: 100);
    await settings.set(UnitPrefs.keyUnitSystem, 'imperial');
    final saved = k.sumPeriod(await act.rides(), DateTime(2026, 9, 11, 12), PeriodKind.today);
    final storedKm = (await act.rides()).single.distanceKm;

    expect(storedKm, closeTo(10, 1e-9), reason: '存储始终为公制');
    final u = UnitPrefs.fromSettings(await settingsMap());
    expect(u.dist(storedKm), '6.2 mi');
    expect(saved.km, closeTo(10, 1e-9));
  });

  // ---------- ST-D06 统计口径一致性 ----------
  test('ST-D06 统计口径：今日/本周/本月与总量关系一致', () async {
    final now = DateTime(2026, 9, 11, 12);
    await saveOne(km: 5, at: DateTime(2026, 9, 11, 7));
    await saveOne(km: 7, at: DateTime(2026, 9, 9, 7)); // 同周
    await saveOne(km: 11, at: DateTime(2026, 9, 1, 7)); // 同月不同周

    final rides = await act.rides();
    final today = k.sumPeriod(rides, now, PeriodKind.today);
    final week = k.sumPeriod(rides, now, PeriodKind.week);
    final month = k.sumPeriod(rides, now, PeriodKind.month);

    expect(today.km, closeTo(5, 1e-9));
    expect(week.km, closeTo(12, 1e-9));
    expect(month.km, closeTo(23, 1e-9));
    expect(today.km <= week.km && week.km <= month.km, isTrue);
  });

  // ---------- ST-D07 分段计圈边界 ----------
  test('ST-D07 分段：暂停不封圈、手动误触过滤、结束后封最后一圈', () {
    // 误触：刚开始 3 秒、只走了 20m → 不封圈
    final mis = SessionMachine();
    mis.start();
    mis.tickSec(3);
    mis.addSample(distKm: 0.02);
    expect(mis.lap(), isFalse, reason: '<100m 且 <10s 视为误触');
    expect(mis.laps, isEmpty);

    final m = SessionMachine();
    m.start();
    m.tickSec(60);
    m.addSample(distKm: 1);
    m.pause();
    m.tickSec(120);
    expect(m.laps, isEmpty, reason: '暂停不封圈');
    expect(m.elapsedSec, 180);
    expect(m.movingSec, 60, reason: '暂停不计移动时长');
    m.resume();
    m.tickSec(120);
    m.addSample(distKm: 2);
    expect(m.lap(), isTrue);
    expect(m.laps.length, 1);
    m.finish();
    expect(m.laps.length, 1, reason: '刚计圈就结束 → 不产生空的收尾圈');

    // 计圈后再骑一段才结束 → 收尾圈被保留
    final m2 = SessionMachine();
    m2.start();
    m2.tickSec(300);
    m2.addSample(distKm: 2);
    expect(m2.lap(), isTrue);
    m2.tickSec(120);
    m2.addSample(distKm: 0.8);
    m2.finish();
    expect(m2.laps.length, 2, reason: '结束后封最后一圈');
    expect(m2.laps.last.distanceKm, closeTo(0.8, 1e-9));
  });

  // ---------- ST-D08 路线增改删 ----------
  test('ST-D08 路线：新增→更新名称与距离→删除', () async {
    final id = await routes.addRoute(
      name: '测试路线',
      points: const [
        [22.50, 113.90],
        [22.51, 113.91],
      ],
      distKm: 1.5,
    );
    expect((await routes.watchRoutes().first).length, 1);

    await routes.updateRoute(
      id: id,
      name: '改名路线',
      points: const [
        [22.50, 113.90],
        [22.52, 113.92],
        [22.53, 113.93],
      ],
      distKm: 4.2,
    );
    final r = (await routes.watchRoutes().first).single;
    expect(r.name, '改名路线');
    expect(r.distKm, closeTo(4.2, 1e-9));
    expect(r.points.length, 3);

    await routes.deleteRoute(id);
    expect(await routes.watchRoutes().first, isEmpty);
  });

  // ---------- ST-D09 导航多位置序列 ----------
  test('ST-D09 导航：直行→偏航→回到路线→到达', () {
    const start = LatLng(22.5000, 113.9000);
    final corner = LatLng(22.5000 + 1000 / 111320, 113.9000);
    final end = LatLng(22.5000 + 1000 / 111320, 113.9000 + 1000 / (111320 * 0.9239));
    final nav = RouteNavigator([start, corner, end]);

    // 前进 500m：剩余约 1.5km
    final p1 = nav.update(LatLng(22.5000 + 500 / 111320, 113.9000));
    expect(p1.remainingM, closeTo(1500, 40));
    expect(p1.offRoute, isFalse);

    // 偏航 150m
    final p2 = nav.update(LatLng(22.5000 + 500 / 111320, 113.9000 + 150 / (111320 * 0.9239)));
    expect(p2.offRoute, isTrue);
    expect(p2.offRouteM, closeTo(150, 20));

    // 到达
    final p3 = nav.update(end);
    expect(p3.arrived, isTrue);
    expect(p3.progress, closeTo(1.0, 0.02));
  });

  // ---------- ST-D10 清除全部数据 ----------
  test('ST-D10 清除全部数据：活动/轨迹/路线/草稿全部清空', () async {
    final id = await saveOne();
    await act.saveTrackPoints(id, [
      SimpleTrack(tMs: DateTime.now().millisecondsSinceEpoch, lat: 22.5, lon: 113.9),
      SimpleTrack(
          tMs: DateTime.now().millisecondsSinceEpoch + 1000, lat: 22.51, lon: 113.91),
    ]);
    await routes.addRoute(name: 'r', points: const [
      [22.5, 113.9],
      [22.51, 113.91],
    ], distKm: 1);
    await act.saveDraft(
      type: '公路',
      startedAt: DateTime.now(),
      totalS: 10,
      distanceKm: 1,
      laps: 0,
    );

    await settings.clearAll();

    expect(await act.rides(), isEmpty);
    expect(await act.loadDraft(), isNull);
    expect(await routes.watchRoutes().first, isEmpty);
    expect((await settings.counts())['tracks'], 0);
  });
}
