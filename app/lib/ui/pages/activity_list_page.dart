import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../domain/stats/aggregate.dart' as k;
import '../../theme/app_theme.dart';
import 'activity_detail_page.dart';

/// 活动列表（M1）：读取 ridesProvider（Drift watch），点击进入详情。
class ActivityListPage extends ConsumerWidget {
  const ActivityListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rides = ref.watch(ridesProvider).valueOrNull ?? const <k.RideLite>[];
    return Scaffold(
      appBar: AppBar(title: const Text('活动')),
      body: rides.isEmpty
          ? const Center(child: Text('还没有骑行记录', style: TextStyle(color: AppTheme.txt3)))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: rides.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final r = rides[i];
                final speed = r.durationMin > 0 ? (r.distanceKm / (r.durationMin / 60)) : 0;
                return ListTile(
                  leading: const Icon(Icons.directions_bike, color: AppTheme.accent),
                  title: Text('${r.startAt.year}-${r.startAt.month}-${r.startAt.day} ${r.startAt.hour}:${r.startAt.minute.toString().padLeft(2, '0')}'),
                  subtitle: Text('${r.distanceKm.toStringAsFixed(1)} km · 爬升 ${r.elevGainM.round()} m'),
                  trailing: Text('${speed.toStringAsFixed(1)} km/h',
                      style: const TextStyle(fontSize: 13, color: AppTheme.txt2)),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ActivityDetailPage(rideId: r.id)),
                  ),
                );
              },
            ),
    );
  }
}
