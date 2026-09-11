import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../domain/stats/aggregate.dart' as k;
import '../../theme/app_theme.dart';
import 'activity_list_page.dart';
import 'settings_page.dart';
import 'stats_page.dart';
import '../widgets/not_ready.dart';

/// 我的（M1）：本地骑行者 + 真实数据总览 + 功能入口。
class MePage extends ConsumerWidget {
  const MePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rides = ref.watch(ridesProvider).valueOrNull ?? const <k.RideLite>[];
    final u = ref.watch(unitPrefsProvider);
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
                _tile(u.distValue(km), '总里程 ${u.distUnit}'),
                _tile(_fmtMin(min), '总时长'),
                _tile(u.elevValue(elev), '总爬升 ${u.elevUnit}'),
                _tile('${rides.length}', '总次数'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('功能入口', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppTheme.line),
            ),
            child: Column(
              children: [
                EntryTile(
                  icon: Icons.insights,
                  title: '统计概览',
                  trailingText: '›',
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const StatsPage())),
                ),
                const Divider(height: 1),
                EntryTile(
                  icon: Icons.list_alt,
                  title: '全部活动',
                  trailingText: '›',
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const ActivityListPage())),
                ),
                const Divider(height: 1),
                const EntryTile(
                    icon: Icons.pedal_bike, title: '我的装备', notReady: true, trailingText: '›'),
                const Divider(height: 1),
                const EntryTile(
                    icon: Icons.download, title: '导入骑行数据（GPX/FIT）', notReady: true, trailingText: '›'),
                const Divider(height: 1),
                const EntryTile(
                    icon: Icons.upload, title: '导出数据（GPX）', notReady: true, trailingText: '›'),
                const Divider(height: 1),
                EntryTile(
                  icon: Icons.settings_outlined,
                  title: '设置',
                  subtitle: '单位 / 记录默认值 / 后台记录 / 数据 / 关于',
                  trailingText: '›',
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const SettingsPage())),
                ),
                const Divider(height: 1),
                EntryTile(
                  icon: Icons.info_outline,
                  title: '关于跋涉',
                  trailingText: '›',
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: '跋涉',
                    applicationVersion: '0.1.0 · M1',
                    children: const [
                      Text('本地优先的骑行记录 App：GPS 记录、统计、地图路线。\n'
                          '数据全部保存在本机（SQLite），无需登录、不上传。\n'
                          '地图与骑行路线规划由高德提供。'),
                    ],
                  ),
                ),
              ],
            ),
          ),
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

  String _fmtMin(double min) {
    final h = (min / 60).floor();
    return h > 0 ? '${h}h ${(min % 60).round()}m' : '${min.round()}m';
  }
}
