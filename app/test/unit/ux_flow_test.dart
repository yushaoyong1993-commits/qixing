import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:basho/core/units.dart';
import 'package:basho/data/activity_repository.dart';
import 'package:basho/data/providers.dart';
import 'package:basho/ui/pages/activity_detail_page.dart';
import 'package:basho/ui/pages/activity_list_page.dart';
import 'package:basho/ui/pages/navigation_page.dart';
import 'package:basho/ui/pages/settings_page.dart';
import 'package:basho/ui/pages/stats_page.dart';
import 'package:basho/data/route_repository.dart';
import 'package:basho/domain/stats/aggregate.dart' as k;

/// 卸载并让 Drift/ Stream 的零延时计时器跑完，避免 pending timer 断言
Future<void> _flush(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 60));
}

void main() {
  test('单位偏好：公制/英制换算正确', () {
    const metric = UnitPrefs(UnitSystem.metric);
    const imperial = UnitPrefs(UnitSystem.imperial);
    expect(metric.dist(10), '10.0 km');
    expect(imperial.dist(10), '6.2 mi');
    expect(metric.speed(20), '20.0 km/h');
    expect(imperial.speed(20), '12.4 mph');
    expect(metric.elev(100), '100 m');
    expect(imperial.elev(100), '328 ft');
    expect(UnitPrefs.fromSettings({'unit_system': 'imperial'}).system, UnitSystem.imperial);
    expect(UnitPrefs.fromSettings(const {}).system, UnitSystem.metric);
  });

  testWidgets('统计页：显示周期数据，点热力图某天弹出当天卡片', (tester) async {
    final db = await openInMemoryDatabase();
    addTearDown(db.close);
    final now = DateTime.now();
    final rides = <k.RideLite>[
      k.RideLite(
        id: 1,
        startAt: DateTime(now.year, now.month, now.day, 8),
        distanceKm: 30,
        durationMin: 60,
        elevGainM: 120,
        name: '今日骑行',
        type: '公路',
      ),
    ];

    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        settingsProvider.overrideWith((ref) => Stream.value(const <String, String>{})),
        ridesProvider.overrideWith((ref) => Stream.value(rides)),
      ],
      child: const MaterialApp(home: StatsPage()),
    ));
    await tester.pumpAndSettle();

    // 周期磁贴存在（次数/距离/时长/爬升）
    expect(find.text('次数'), findsOneWidget);

    // 向下滚动到"累计"区块（ListView 懒加载）
    await tester.scrollUntilVisible(find.text('累计'), 300,
        scrollable: find.byType(Scrollable).first);

    // 滚动到热力图，点选"今天"这一格
    final cell = find.descendant(
      of: find.byType(GridView),
      matching: find.text('${now.day}'),
    );
    await tester.scrollUntilVisible(cell, 200,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(cell);
    await tester.pumpAndSettle();
    expect(cell, findsOneWidget);
    await tester.tap(cell);
    await tester.pumpAndSettle();

    // 当天卡片在页面顶部 → 滚回顶部后再断言
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 2500));
    await tester.pumpAndSettle();
    expect(find.text('${now.year}-${now.month}-${now.day} 当天'), findsOneWidget);
    expect(find.text('今日骑行'), findsWidgets);
    await _flush(tester);
  });

  testWidgets('活动列表：按日期分组 + 类型筛选', (tester) async {
    final db = await openInMemoryDatabase();
    addTearDown(db.close);
    final now = DateTime.now();
    final rides = <k.RideLite>[
      k.RideLite(
          id: 1,
          startAt: DateTime(now.year, now.month, now.day, 9),
          distanceKm: 10,
          durationMin: 30,
          elevGainM: 20,
          name: '公路活动',
          type: '公路'),
      k.RideLite(
          id: 2,
          startAt: DateTime(now.year, now.month, now.day - 2, 9),
          distanceKm: 20,
          durationMin: 60,
          elevGainM: 300,
          name: '山地活动',
          type: '山地'),
    ];

    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        settingsProvider.overrideWith((ref) => Stream.value(const <String, String>{})),
        ridesProvider.overrideWith((ref) => Stream.value(rides)),
      ],
      child: const MaterialApp(home: ActivityListPage()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('今天'), findsOneWidget); // 日期分组标题
    expect(find.text('公路活动'), findsOneWidget);
    expect(find.text('山地活动'), findsOneWidget);

    // 筛选"山地" → 只剩山地活动
    await tester.tap(find.widgetWithText(ChoiceChip, '山地'));
    await tester.pumpAndSettle();
    expect(find.text('山地活动'), findsOneWidget);
    expect(find.text('公路活动'), findsNothing);
    await _flush(tester);
  });

  testWidgets('活动详情：显示分段计圈与导出入口', (tester) async {
    final db = await openInMemoryDatabase();
    addTearDown(db.close);
    final repo = ActivityRepository(db);
    final start = DateTime(2026, 9, 10, 7, 30);
    final id = await repo.saveRide(
      name: '分段测试', type: '训练', startAt: start,
      durationS: 1800, movingS: 1800, distanceM: 10000, elevGainM: 80, elevLossM: 60,
      hrAvg: null, hrMax: null, kcal: 250,
    );
    await repo.saveLaps(id, [
      LapRecord(idx: 1, startAt: start, endAt: start.add(const Duration(minutes: 9)), distM: 5000),
      LapRecord(idx: 2, startAt: start.add(const Duration(minutes: 9)),
          endAt: start.add(const Duration(minutes: 18)), distM: 5000),
    ]);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        settingsProvider.overrideWith((ref) => Stream.value(const <String, String>{})),
        ridesProvider.overrideWith((ref) => Stream.value(<k.RideLite>[
              k.RideLite(
                  id: id,
                  startAt: start,
                  distanceKm: 10,
                  durationMin: 30,
                  elevGainM: 80,
                  name: '分段测试',
                  type: '训练'),
            ])),
      ],
      child: MaterialApp(home: ActivityDetailPage(rideId: id)),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('分段 / 计圈'), findsOneWidget);
    expect(find.text('L1'), findsOneWidget);
    expect(find.text('L2'), findsOneWidget);
    expect(find.text('训练'), findsOneWidget); // 类型
    expect(find.byIcon(Icons.ios_share), findsOneWidget); // 导出 GPX
    expect(find.text('编辑'), findsOneWidget);
    await _flush(tester);
  });

  testWidgets('设置页：切换英制单位写入设置', (tester) async {
    final db = await openInMemoryDatabase();
    addTearDown(db.close);
    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const MaterialApp(home: SettingsPage()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('公制 km/m'), findsOneWidget);
    await tester.tap(find.text('英制 mi/ft'));
    await tester.pumpAndSettle();

    final saved = await SettingsRepositoryForTest.get(db, UnitPrefs.keyUnitSystem);
    expect(saved, 'imperial');
    await _flush(tester);
  });

  testWidgets('导航页：给定路线可打开并显示剩余距离', (tester) async {
    final route = RouteModel(
      id: 1,
      name: '测试路线',
      points: const [
        [22.5000, 113.9000],
        [22.5090, 113.9000],
        [22.5090, 113.9100],
      ],
      distKm: 2.0,
      createdAt: DateTime(2026, 9, 10),
    );
    final db = await openInMemoryDatabase();
    addTearDown(db.close);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        settingsProvider.overrideWith((ref) => Stream.value(const <String, String>{})),
      ],
      child: MaterialApp(home: NavigationPage(route: route)),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('导航 · 测试路线'), findsOneWidget);
    expect(find.textContaining('剩余'), findsOneWidget);
    expect(find.text('结束导航'), findsOneWidget);
    await _flush(tester);
  });
}

/// 测试用：直接读设置表（避免依赖 UI 层）
class SettingsRepositoryForTest {
  static Future<String?> get(dynamic db, String key) async {
    final rows = await db.select(db.settings).get();
    for (final r in rows) {
      if (r.key == key) return r.value;
    }
    return null;
  }
}
