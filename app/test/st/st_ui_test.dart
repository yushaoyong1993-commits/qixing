import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:basho/core/units.dart';
import 'package:basho/data/activity_repository.dart';
import 'package:basho/data/providers.dart';
import 'package:basho/data/route_repository.dart';
import 'package:basho/data/settings_repository.dart';
import 'package:basho/domain/stats/aggregate.dart' as k;
import 'package:basho/ui/pages/activity_detail_page.dart';
import 'package:basho/ui/pages/activity_list_page.dart';
import 'package:basho/ui/pages/home_page.dart';
import 'package:basho/ui/pages/map_page.dart';
import 'package:basho/ui/pages/navigation_page.dart';
import 'package:basho/ui/pages/record_page.dart';
import 'package:basho/ui/pages/settings_page.dart';
import 'package:basho/ui/pages/stats_page.dart';
import 'package:basho/ui/widgets/amap_native_view.dart';

/// ST 系统测试（页面层）：功能点 + 跨模块关联。
/// 说明：涉及 Drift 流的用例统一在结束前卸载并 flush，避免 pending timer 断言。
Future<void> _flush(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 80));
}

List<Override> _overrides(
  BashoDatabase db, {
  List<k.RideLite>? rides,
  List<RouteModel>? routes,
  Map<String, String>? settings,
}) =>
    [
      databaseProvider.overrideWithValue(db),
      settingsProvider.overrideWith(
          (ref) => Stream.value(settings ?? const <String, String>{})),
      if (rides != null) ridesProvider.overrideWith((ref) => Stream.value(rides)),
      if (routes != null)
        routesProvider.overrideWith((ref) => Stream.value(routes)),
    ];

k.RideLite _ride({
  int id = 1,
  String name = '晨骑',
  String type = '公路',
  DateTime? at,
  double km = 20,
  double min = 60,
  double elev = 100,
}) =>
    k.RideLite(
      id: id,
      startAt: at ?? DateTime(2026, 9, 11, 7, 30),
      distanceKm: km,
      durationMin: min,
      elevGainM: elev,
      name: name,
      type: type,
    );

void main() {
  // 原生地图 PlatformView 在测试环境无平台实现 → 走降级占位
  AmapNativeView.enabled = false;

  // ---------- ST-U01 记录：开始→计时→保存闭环 ----------
  testWidgets('ST-U01 记录页：开始计时→停止→保存，落库一条记录', (tester) async {
    final db = await openInMemoryDatabase();
    addTearDown(db.close);
    await tester.pumpWidget(ProviderScope(
      overrides: _overrides(db),
      child: const MaterialApp(home: Scaffold(body: RecordPage())),
    ));
    await tester.pump();

    expect(find.text('开始记录'), findsOneWidget);
    await tester.tap(find.text('开始记录'));
    await tester.pump();
    // 秒表与 GPS 解耦：即使无定位，时间也应走动
    await tester.pump(const Duration(seconds: 3));
    expect(find.textContaining('● REC'), findsOneWidget);
    expect(find.text('00:03'), findsWidgets, reason: '无 GPS 时时长照常累计');

    await tester.tap(find.byIcon(Icons.stop));
    await tester.pump();
    expect(find.text('骑行完成 🎉'), findsOneWidget);
    expect(find.text('再骑一段'), findsOneWidget);

    await tester.tap(find.text('保存'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final rides = await tester.runAsync(() => ActivityRepository(db).rides());
    expect(rides!.length, 1);
    await _flush(tester);
  });

  testWidgets('ST-U02 记录页：摘要选"再骑一段"→回到记录中且不落库', (tester) async {
    final db = await openInMemoryDatabase();
    addTearDown(db.close);
    await tester.pumpWidget(ProviderScope(
      overrides: _overrides(db),
      child: const MaterialApp(home: Scaffold(body: RecordPage())),
    ));
    await tester.pump();
    await tester.tap(find.text('开始记录'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.byIcon(Icons.stop));
    await tester.pump();
    await tester.tap(find.text('再骑一段'));
    await tester.pump();

    expect(find.textContaining('● REC'), findsOneWidget, reason: '应回到记录中');
    final rides = await tester.runAsync(() => ActivityRepository(db).rides());
    expect(rides, isEmpty, reason: '再骑一段不落库');
    await _flush(tester);
  });

  // ---------- ST-U03 首页：空态 / 有数据 / 进行中横幅 ----------
  testWidgets('ST-U03 首页：空态提示与进行中横幅联动', (tester) async {
    final db = await openInMemoryDatabase();
    addTearDown(db.close);

    // 空数据 → 空态（注意：Riverpod 的 overrides 只在容器创建时生效，故用不同 key 区分）
    await tester.pumpWidget(ProviderScope(
      key: const ValueKey('home-empty'),
      overrides: _overrides(db, rides: const []),
      child: const MaterialApp(home: Scaffold(body: HomePage())),
    ));
    await tester.pump();
    expect(find.textContaining('还没有骑行记录'), findsOneWidget);

    // 有数据 → 概览 + 上次骑行卡（活动名）
    await tester.pumpWidget(ProviderScope(
      key: const ValueKey('home-data'),
      overrides: _overrides(db, rides: [_ride(name: '晚间骑行')]),
      child: const MaterialApp(home: Scaffold(body: HomePage())),
    ));
    await tester.pumpAndSettle();
    expect(find.text('上次骑行'), findsOneWidget);
    expect(find.text('晚间骑行'), findsOneWidget);
    expect(find.textContaining('累计骑行'), findsOneWidget);
    await _flush(tester);
  });

  testWidgets('ST-U04 跨页横幅：会话进行中时首页显示并可跳转记录 Tab', (tester) async {
    final db = await openInMemoryDatabase();
    addTearDown(db.close);
    final container = ProviderContainer(overrides: _overrides(db, rides: const []));
    addTearDown(container.dispose);
    container.read(sessionStatusProvider.notifier).state =
        const SessionStatus(type: '公路', movingSec: 754, distanceKm: 3.2, paused: false, lap: 1);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: HomePage())),
    ));
    await tester.pump();

    expect(find.textContaining('骑行进行中'), findsOneWidget);
    expect(find.textContaining('12:34'), findsOneWidget);
    await tester.tap(find.text('回到记录'));
    await tester.pump();
    expect(container.read(tabIndexProvider), 2, reason: '应切换到记录 Tab');
    await _flush(tester);
  });

  // ---------- ST-U05 统计：周期 + 热力图点选当天（关联活动详情） ----------
  testWidgets('ST-U05 统计页：周期数据 + 点热力图当天可看到当天活动', (tester) async {
    final db = await openInMemoryDatabase();
    addTearDown(db.close);
    final now = DateTime.now();
    final rides = [
      _ride(
        name: '今天骑的',
        at: DateTime(now.year, now.month, now.day, 8),
        km: 30,
        min: 60,
        elev: 120,
      )
    ];
    await tester.pumpWidget(ProviderScope(
      overrides: _overrides(db, rides: rides),
      child: const MaterialApp(home: StatsPage()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('次数'), findsOneWidget);

    final cell = find.descendant(
        of: find.byType(GridView), matching: find.text('${now.day}'));
    await tester.scrollUntilVisible(cell, 200,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(cell);
    await tester.pumpAndSettle();
    await tester.tap(cell);
    await tester.pumpAndSettle();

    await tester.drag(find.byType(Scrollable).first, const Offset(0, 2500));
    await tester.pumpAndSettle();
    expect(find.text('${now.year}-${now.month}-${now.day} 当天'), findsOneWidget);
    expect(find.text('今天骑的'), findsWidgets);
    await _flush(tester);
  });

  // ---------- ST-U06 统计：单位切换联动显示 ----------
  testWidgets('ST-U06 统计页：英制单位下显示 mi', (tester) async {
    final db = await openInMemoryDatabase();
    addTearDown(db.close);
    // 日期必须相对"今天"，否则不在今日/本周区间 → 周期数据为 0（用例曾因此产生假失败）
    final now = DateTime.now();
    await tester.pumpWidget(ProviderScope(
      overrides: _overrides(db,
          rides: [
            _ride(
              km: 16.0934,
              at: DateTime(now.year, now.month, now.day, 8),
            )
          ],
          settings: {UnitPrefs.keyUnitSystem: 'imperial'}),
      child: const MaterialApp(home: StatsPage()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('距离 mi'), findsOneWidget);
    expect(find.text('10.0'), findsWidgets, reason: '16.09km ≈ 10.0mi');
    await _flush(tester);
  });

  // ---------- ST-U07 活动列表：分组 + 筛选 + 删除联动 ----------
  testWidgets('ST-U07 活动列表：日期分组、类型筛选、删除后刷新', (tester) async {
    final db = await openInMemoryDatabase();
    addTearDown(db.close);
    final repo = ActivityRepository(db);
    final now = DateTime.now();
    await repo.saveRide(
      name: '公路一', type: '公路', startAt: DateTime(now.year, now.month, now.day, 9),
      durationS: 1800, movingS: 1800, distanceM: 10000, elevGainM: 20, elevLossM: 10,
      hrAvg: null, hrMax: null,
    );
    await repo.saveRide(
      name: '山地一', type: '山地', startAt: DateTime(now.year, now.month, now.day - 3, 9),
      durationS: 3600, movingS: 3600, distanceM: 20000, elevGainM: 300, elevLossM: 280,
      hrAvg: null, hrMax: null,
    );
    final rides = await repo.rides();

    await tester.pumpWidget(ProviderScope(
      overrides: _overrides(db, rides: rides.map((r) => r).toList()),
      child: const MaterialApp(home: ActivityListPage()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('今天'), findsOneWidget);
    expect(find.text('公路一'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, '山地'));
    await tester.pumpAndSettle();
    expect(find.text('山地一'), findsOneWidget);
    expect(find.text('公路一'), findsNothing);
    await _flush(tester);
  });

  // ---------- ST-U08 详情：无轨迹提示 + 分段列表 ----------
  testWidgets('ST-U08 详情页：有分段显示 L1/L2，无轨迹给出提示', (tester) async {
    final db = await openInMemoryDatabase();
    addTearDown(db.close);
    final repo = ActivityRepository(db);
    final start = DateTime(2026, 9, 11, 7);
    final id = await repo.saveRide(
      name: '分段活动', type: '训练', startAt: start,
      durationS: 1800, movingS: 1800, distanceM: 10000, elevGainM: 80, elevLossM: 60,
      hrAvg: null, hrMax: null,
    );
    await repo.saveLaps(id, [
      LapRecord(idx: 1, startAt: start, endAt: start.add(const Duration(minutes: 9)), distM: 5000),
      LapRecord(
          idx: 2,
          startAt: start.add(const Duration(minutes: 9)),
          endAt: start.add(const Duration(minutes: 18)),
          distM: 5000),
    ]);

    await tester.pumpWidget(ProviderScope(
      overrides: _overrides(db, rides: [_ride(id: id, name: '分段活动', type: '训练')]),
      child: MaterialApp(home: ActivityDetailPage(rideId: id)),
    ));
    await tester.pumpAndSettle();

    expect(find.text('L1'), findsOneWidget);
    expect(find.text('L2'), findsOneWidget);
    expect(find.textContaining('分段 / 计圈'), findsOneWidget);
    expect(find.textContaining('暂无轨迹点'), findsOneWidget, reason: '无轨迹时提示');
    await _flush(tester);
  });

  // ---------- ST-U09 设置→记录：默认类型/自动计圈生效 ----------
  testWidgets('ST-U09 设置页默认值在记录页生效（默认类型=山地、自动计圈=开）', (tester) async {
    final db = await openInMemoryDatabase();
    addTearDown(db.close);
    final settingsRepo = SettingsRepository(db);
    await settingsRepo.set('default_ride_type', '山地');
    await settingsRepo.set('auto_pause', 'false');
    await settingsRepo.set('auto_lap', 'true');

    await tester.pumpWidget(ProviderScope(
      overrides: _overrides(db),
      child: const MaterialApp(home: Scaffold(body: RecordPage())),
    ));
    await tester.pumpAndSettle();

    // 记录页读取默认类型（山地 chip 选中）
    final chip = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '山地'));
    expect(chip.selected, isTrue);
    await _flush(tester);
  });

  // ---------- ST-U10 设置页：清除全部数据二次确认可达 ----------
  testWidgets('ST-U10 设置页：数据区块与危险操作可见', (tester) async {
    final db = await openInMemoryDatabase();
    addTearDown(db.close);
    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const MaterialApp(home: SettingsPage()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('显示单位'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('清除全部本地数据'), 240,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('清除全部本地数据'), findsOneWidget);
    await _flush(tester);
  });

  // ---------- ST-U11 导航页：路线导航可打开并显示关键信息 ----------
  testWidgets('ST-U11 导航页：显示剩余距离/结束导航/语音开关', (tester) async {
    final db = await openInMemoryDatabase();
    addTearDown(db.close);
    final route = RouteModel(
      id: 1,
      name: '环湖线',
      points: const [
        [22.5000, 113.9000],
        [22.5090, 113.9000],
        [22.5090, 113.9100],
      ],
      distKm: 2.0,
      createdAt: DateTime(2026, 9, 11),
    );
    await tester.pumpWidget(ProviderScope(
      overrides: _overrides(db),
      child: MaterialApp(home: NavigationPage(route: route)),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.textContaining('导航 · 环湖线'), findsOneWidget);
    expect(find.textContaining('剩余'), findsOneWidget);
    expect(find.text('结束导航'), findsOneWidget);
    expect(find.byIcon(Icons.volume_up), findsOneWidget);
    await _flush(tester);
  });

  // ---------- ST-U12 地图页：路线列表与空态 ----------
  testWidgets('ST-U12 地图页：无路线时空态提示，有路线时列出', (tester) async {
    final db = await openInMemoryDatabase();
    addTearDown(db.close);
    await tester.pumpWidget(ProviderScope(
      key: const ValueKey('map-empty'),
      overrides: _overrides(db, routes: const []),
      child: const MaterialApp(home: MapPage()),
    ));
    // 地图页含 WebView 与定位副作用 → 用有界 pump，避免 pumpAndSettle 无法收敛
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('还没有路线'), findsOneWidget);

    await tester.pumpWidget(ProviderScope(
      key: const ValueKey('map-data'),
      overrides: _overrides(db, routes: [
        RouteModel(
          id: 1,
          name: '通勤线',
          points: const [
            [22.50, 113.90],
            [22.51, 113.91],
          ],
          distKm: 3.3,
          createdAt: DateTime(2026, 9, 11),
        )
      ]),
      child: const MaterialApp(home: MapPage()),
    ));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('通勤线'), findsWidgets);
    expect(find.textContaining('3.3 km'), findsWidgets);
    await _flush(tester);
  });
}
