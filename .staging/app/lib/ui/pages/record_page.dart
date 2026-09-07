import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 记录（M0 占位）。
/// 见《骑行App_记录PRD_v1.1.md》：准备页 → 记录中 → 摘要状态机（M1）。
class RecordPage extends StatelessWidget {
  const RecordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_bike, size: 48, color: AppTheme.txt3),
            const SizedBox(height: 12),
            Text('骑行记录（建设中）', style: _h),
            const SizedBox(height: 6),
            Text('准备页 / 实时数据 / 会话状态机 —— M1',
                style: TextStyle(fontSize: 12.5, color: AppTheme.txt3)),
          ],
        ),
      ),
    );
  }

  static const _h = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
}
