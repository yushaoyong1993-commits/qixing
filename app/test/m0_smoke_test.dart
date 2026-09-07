import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:basho/app.dart';
import 'package:basho/data/providers.dart';
import 'package:basho/domain/stats/aggregate.dart' as k;

void main() {
  testWidgets('M0 骨架：四文字 Tab 可切换、首页 Hero 存在（覆盖 rides 为空流）', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ridesProvider.overrideWith((ref) => Stream.value(const <k.RideLite>[])),
        ],
        child: const BashoApp(),
      ),
    );
    await tester.pump(); // 渲染一帧；空流立即送达
    await tester.pump();

    expect(find.text('首页'), findsOneWidget);
    expect(find.text('地图'), findsOneWidget);
    expect(find.text('记录'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
    expect(find.text('开始骑行'), findsOneWidget);
    expect(find.text('还没有骑行记录，去「记录」开始第一次骑行吧'), findsOneWidget);

    await tester.tap(find.text('我的'));
    await tester.pump();
    await tester.pump();
    expect(find.text('个人中心（建设中）'), findsOneWidget);

    await tester.tap(find.text('首页'));
    await tester.pump();
    await tester.pump();
    expect(find.text('开始骑行'), findsOneWidget);
  });
}
