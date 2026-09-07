import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:basho/app.dart';

void main() {
  testWidgets('M0 骨架：四文字 Tab 可切换、首页 Hero 存在', (tester) async {
    await tester.pumpWidget(const BashoApp());

    // 底部文字 Tab（纯文字，无图标要求见 PRD）
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('地图'), findsOneWidget);
    expect(find.text('记录'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);

    // 默认落在首页：Hero 按钮可见
    expect(find.text('开始骑行'), findsOneWidget);

    // 切换到「我的」
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    expect(find.text('个人中心（建设中）'), findsOneWidget);

    // 切回「首页」
    await tester.tap(find.text('首页'));
    await tester.pumpAndSettle();
    expect(find.text('开始骑行'), findsOneWidget);
  });
}
