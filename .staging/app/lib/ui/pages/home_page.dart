import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 首页（M0 骨架版）：Hero 开始按钮 + 概览占位。
/// 完整实现见《骑行App_首页PRD_v1.1.md》，M1 接入真实数据。
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _HeroStartButton(onPressed: () => _coming(context, '开始骑行')),
          const SizedBox(height: 12),
          const _OverviewPlaceholder(),
        ],
      ),
    );
  }

  void _coming(BuildContext context, String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name：待 M1 接入', textAlign: TextAlign.center)),
    );
  }
}

class _HeroStartButton extends StatelessWidget {
  const _HeroStartButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF6A1A), AppTheme.accent, Color(0xFFE23D00)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: .18),
                    border: Border.all(color: Colors.white.withValues(alpha: .55)),
                  ),
                  child: const Icon(Icons.directions_bike, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('开始骑行',
                          style: TextStyle(color: Colors.white, fontSize: 22,
                              fontWeight: FontWeight.w700, letterSpacing: 1)),
                      SizedBox(height: 3),
                      Text('GPS 轨迹 · 支持心率 / 踏频外设（M3）',
                          style: TextStyle(color: Colors.white, fontSize: 12.5)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverviewPlaceholder extends StatelessWidget {
  const _OverviewPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.line),
      ),
      child: const Column(
        children: [
          Text('今日 / 本周 / 本月', style: TextStyle(color: AppTheme.txt2)),
          SizedBox(height: 8),
          Text('—— 概览卡占位，M1 接入 AggregateService ——',
              style: TextStyle(fontSize: 12, color: AppTheme.txt3)),
        ],
      ),
    );
  }
}
