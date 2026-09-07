import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../domain/stats/aggregate.dart' as k;
import '../../theme/app_theme.dart';

/// 活动详情（M1）：从 ridesProvider 按 id 读取，展示指标，可删除。
class ActivityDetailPage extends ConsumerWidget {
  const ActivityDetailPage({super.key, required this.rideId});

  final int rideId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rides = ref.watch(ridesProvider).valueOrNull ?? const <k.RideLite>[];
    k.RideLite? r;
    for (final x in rides) {
      if (x.id == rideId) r = x;
    }
    if (r == null) {
      return const Scaffold(
        body: Center(child: Text('活动不存在', style: TextStyle(color: AppTheme.txt3))),
      );
    }
    final speed = r.durationMin > 0 ? (r.distanceKm / (r.durationMin / 60)) : 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('骑行详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref, r!.id),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _item('日期时间',
              '${r.startAt.year}-${r.startAt.month}-${r.startAt.day} ${r.startAt.hour}:${r.startAt.minute.toString().padLeft(2, '0')}'),
          _item('距离', '${r.distanceKm.toStringAsFixed(1)} km'),
          _item('时长(移动)', _fmtSec(r.durationMin),
              sub: '${_fmtSec(r.durationMin * 60)}'),
          _item('均速', '${speed.toStringAsFixed(1)} km/h'),
          _item('累计爬升', '${r.elevGainM.round()} m'),
          const SizedBox(height: 10),
          const Text('轨迹地图将在接入地图引擎后展示（M1 后续）',
              style: TextStyle(fontSize: 12, color: AppTheme.txt3)),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('删除该活动？'),
        content: const Text('删除后不可恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('删除')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(activityRepositoryProvider).deleteRide(id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已删除 · 列表已刷新')));
      Navigator.pop(context);
    }
  }

  Widget _item(String label, String value, {String? sub}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(color: AppTheme.txt2))),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (sub != null)
                  Text(sub, style: const TextStyle(fontSize: 11, color: AppTheme.txt3)),
              ],
            ),
          ],
        ),
      );

  String _fmtSec(double minutes) {
    final total = (minutes * 60).round();
    final h = total ~/ 3600, m = (total % 3600) ~/ 60, s = total % 60;
    String p(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '${p(h)}:${p(m)}:${p(s)}' : '${p(m)}:${p(s)}';
  }
}
