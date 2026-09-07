import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:basho/data/activity_repository.dart';
import 'package:basho/data/providers.dart';
import 'package:basho/data/route_repository.dart';
import 'package:basho/ui/pages/record_page.dart';

void main() {
  testWidgets('M1 闭环①：记录→停止→保存 → 写入数据库', (tester) async {
    final db = await openInMemoryDatabase();
    addTearDown(db.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: Scaffold(body: RecordPage())),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('开始记录'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3)); // 计时器推进
    await tester.pump();

    await tester.tap(find.byIcon(Icons.stop));
    await tester.pump();
    expect(find.text('骑行完成 🎉'), findsOneWidget);

    await tester.tap(find.text('保存'));
    await tester.pump();

    final rides = await tester.runAsync(() => ActivityRepository(db).rides());
    expect(rides, isNotNull);
    expect(rides!.length, 1);
    expect(rides.first.distanceKm, greaterThan(0));
  });

  test('M1 闭环②（仓库级）：路线 add → watch 可见 → delete 清空', () async {
    final db = await openInMemoryDatabase();
    addTearDown(db.close);
    final repo = RouteRepository(db);
    expect((await repo.watchRoutes().first), isEmpty);

    await repo.addRoute(name: '测试路线', points: const [[1, 1], [50, 50], [90, 20]], distKm: 3.0);
    final afterAdd = await repo.watchRoutes().first;
    expect(afterAdd.length, 1);
    expect(afterAdd.first.name, '测试路线');
    expect(afterAdd.first.distKm, closeTo(3.0, 1e-9));
    expect(afterAdd.first.points.length, 3);

    await repo.deleteRoute(afterAdd.first.id);
    expect((await repo.watchRoutes().first), isEmpty);
  });
}
