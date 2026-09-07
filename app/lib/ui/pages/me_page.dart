import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// 我的（M0 占位）。
/// 见《骑行App_我的PRD_v1.0.md》：本地模式、数据总览、功能入口。
class MePage extends StatelessWidget {
  const MePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_outline, size: 48, color: AppTheme.txt3),
            const SizedBox(height: 12),
            Text('个人中心（建设中）', style: _h),
            const SizedBox(height: 6),
            Text('本地骑行者 · 数据总览与功能入口 —— M1',
                style: TextStyle(fontSize: 12.5, color: AppTheme.txt3)),
          ],
        ),
      ),
    );
  }

  static const _h = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
}
