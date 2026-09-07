import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'ui/nav/root_shell.dart';

/// 跋涉 App 根组件：浅色主题 + 四 Tab 主壳。
class BashoApp extends StatelessWidget {
  const BashoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '跋涉',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const RootShell(),
    );
  }
}
