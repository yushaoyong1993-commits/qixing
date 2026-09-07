import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 地图 · 路线（M0 占位）。
/// 见《骑行App_地图路线PRD_v1.1.md》：M1 地图浏览/路线列表/手绘。
class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map_outlined, size: 48, color: AppTheme.txt3),
            const SizedBox(height: 12),
            Text('地图 · 路线（建设中）', style: _h),
            const SizedBox(height: 6),
            Text('标准/卫星底图、我的路线、手绘 —— M1',
                style: TextStyle(fontSize: 12.5, color: AppTheme.txt3)),
          ],
        ),
      ),
    );
  }

  static const _h = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
}
