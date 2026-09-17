import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:basho/ui/widgets/amap_native_view.dart';

void main() {
  testWidgets('原生地图：测试环境（无平台实现）降级为占位，不抛异常', (tester) async {
    AmapNativeView.enabled = false;
    addTearDown(() => AmapNativeView.enabled = true);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 200,
          child: AmapNativeView(
            onTapLngLat: (lng, lat) {},
            onReady: () {},
            onError: (msg) {},
          ),
        ),
      ),
    ));
    await tester.pump();

    expect(find.textContaining('地图不可用'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('原生地图 API 在未就绪时调用不崩溃（参数缓存，就绪后重放）', (tester) async {
    AmapNativeView.enabled = false;
    addTearDown(() => AmapNativeView.enabled = true);

    final key = GlobalKey<AmapNativeViewState>();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 200,
          child: AmapNativeView(
            key: key,
            onTapLngLat: (lng, lat) {},
          ),
        ),
      ),
    ));
    await tester.pump();

    // 未创建原生视图时调用各 API 应安全返回（不抛异常）
    key.currentState!.render(path: const [
      [113.9, 22.5],
      [113.91, 22.51],
    ]);
    key.currentState!.renderNav(done: const [], todo: const [], me: null);
    key.currentState!.moveTo(113.9, 22.5);
    key.currentState!.fitRoute();
    key.currentState!.refresh();
    key.currentState!.rebuild();
    expect(tester.takeException(), isNull);
  });
}
