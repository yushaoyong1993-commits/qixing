import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../domain/stats/aggregate.dart' as k;
import '../../theme/app_theme.dart';

/// 我的（M1）：本地骑行者 + 真实数据总览 + 功能入口。
class MePage extends ConsumerWidget {
  const MePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rides = ref.watch(ridesProvider).valueOrNull ?? const <k.RideLite>[];
    var km = 0.0, min = 0.0, elev = 0.0;
    for (final r in rides) {
      km += r.distanceKm;
      min += r.durationMin;
      elev += r.elevGainM;
    }
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.card2,
                child: const Text('跋', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppTheme.accentInk)),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('本地骑行者', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  SizedBox(height: 2),
                  Text('本地模式 · 无需登录', style: TextStyle(fontSize: 12, color: AppTheme.txt3)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.line),
            ),
            child: Row(
              children: [
                _tile(km.toStringAsFixed(1), '总里程 km'),
                _tile(_fmtMin(min), '总时长'),
                _tile('${elev.round()}', '总爬升 m'),
                _tile('${rides.length}', '总次数'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('功能入口', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          _entry(context, Icons.import_export, '导入骑行数据', '待接入（IO-01）'),
          _entry(context, Icons.ios_share, '导出数据', '待接入（IO-05）'),
          _entry(context, Icons.settings_outlined, '设置', '待接入'),
        ],
      ),
    );
  }

  Widget _tile(String v, String l) => Expanded(
        child: Column(
          children: [
            Text(v, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.txt)),
            const SizedBox(height: 2),
            Text(l, style: const TextStyle(fontSize: 10.5, color: AppTheme.txt3)),
          ],
        ),
      );

  Widget _entry(BuildContext context, IconData icon, String title, String sub) => Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppTheme.line),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: Icon(icon, color: AppTheme.accentInk),
          title: Text(title, style: const TextStyle(fontSize: 14)),
          subtitle: Text(sub, style: const TextStyle(fontSize: 11, color: AppTheme.txt3)),
        ),
      );

  String _fmtMin(double min) {
    final h = (min / 60).floor();
    return h > 0 ? '${h}h ${(min % 60).round()}m' : '${min.round()}m';
  }
}
