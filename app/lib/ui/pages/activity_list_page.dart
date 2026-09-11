import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../domain/stats/aggregate.dart' as k;
import '../../theme/app_theme.dart';
import '../widgets/not_ready.dart';
import 'activity_detail_page.dart';

/// 活动列表（M1）：读取 ridesProvider（Drift watch），点击进入详情。
class ActivityListPage extends ConsumerStatefulWidget {
  const ActivityListPage({super.key});

  @override
  ConsumerState<ActivityListPage> createState() => _ActivityListPageState();
}

class _ActivityListPageState extends ConsumerState<ActivityListPage> {
  static const _filters = ['全部', '公路', '山地', '通勤', '训练'];
  String _filter = '全部';

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(ridesProvider).valueOrNull ?? const <k.RideLite>[];
    final rides = _filter == '全部'
        ? all
        : all.where((r) => r.type == _filter).toList();
    final u = ref.watch(unitPrefsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('活动'),
        actions: [
          TextButton(
            onPressed: () => showNotReady(context, '手动补记'),
            child: const Text('＋手动（未完成）', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
      body: Column(
        children: [
          // 类型筛选（原型 actFilters）
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                for (final f in _filters)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(f, style: const TextStyle(fontSize: 12)),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: const Text('导入（未完成）', style: TextStyle(fontSize: 12)),
                    selected: false,
                    onSelected: (_) => showNotReady(context, '导入的活动筛选'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: rides.isEmpty
          ? const Center(child: Text('还没有骑行记录', style: TextStyle(color: AppTheme.txt3)))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: rides.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final r = rides[i];
                final speed = r.durationMin > 0 ? (r.distanceKm / (r.durationMin / 60)) : 0.0;
                return ListTile(
                  leading: const Icon(Icons.directions_bike, color: AppTheme.accent),
                  title: Text('${r.startAt.year}-${r.startAt.month}-${r.startAt.day} ${r.startAt.hour}:${r.startAt.minute.toString().padLeft(2, '0')}'),
                  subtitle: Text('${u.dist(r.distanceKm)} · 爬升 ${u.elev(r.elevGainM)}'),
                  trailing: Text(u.speed(speed),
                      style: const TextStyle(fontSize: 13, color: AppTheme.txt2)),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ActivityDetailPage(rideId: r.id)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
