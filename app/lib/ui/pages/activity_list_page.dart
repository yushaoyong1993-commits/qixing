import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/units.dart';
import '../../data/providers.dart';
import '../../domain/stats/aggregate.dart' as k;
import '../../theme/app_theme.dart';
import 'activity_detail_page.dart';

/// 活动列表：类型筛选 + 按日期分组 + 手动补记。
class ActivityListPage extends ConsumerStatefulWidget {
  const ActivityListPage({super.key});

  @override
  ConsumerState<ActivityListPage> createState() => _ActivityListPageState();
}

class _ActivityListPageState extends ConsumerState<ActivityListPage> {
  static const _filters = ['全部', '公路', '山地', '通勤', '训练', '导入'];
  String _filter = '全部';

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(ridesProvider).valueOrNull ?? const <k.RideLite>[];
    final rides =
        _filter == '全部' ? all : all.where((r) => r.type == _filter).toList();
    final u = ref.watch(unitPrefsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('活动'),
        actions: [
          TextButton(
            onPressed: () => _manualAdd(context),
            child: const Text('＋手动补记', style: TextStyle(fontSize: 12)),
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
              ],
            ),
          ),
          Expanded(
            child: rides.isEmpty
                ? const Center(
                    child: Text('没有符合条件骑行记录',
                        style: TextStyle(color: AppTheme.txt3)))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    children: _groupedTiles(rides, u),
                  ),
          ),
        ],
      ),
    );
  }

  /// 按日期分组（原型 actGroups）：今天 / 昨天 / M月D日 周X
  List<Widget> _groupedTiles(List<k.RideLite> rides, UnitPrefs u) {
    final out = <Widget>[];
    String? lastKey;
    for (final r in rides) {
      final key = '${r.startAt.year}-${r.startAt.month}-${r.startAt.day}';
      if (key != lastKey) {
        lastKey = key;
        out.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6, left: 2),
          child: Text(_dayLabel(r.startAt),
              style: const TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.txt2)),
        ));
      }
      final speed = r.durationMin > 0 ? (r.distanceKm / (r.durationMin / 60)) : 0.0;
      out.add(Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppTheme.line),
        ),
        child: ListTile(
          leading: const Icon(Icons.directions_bike, color: AppTheme.accent),
          title: Text(r.name, style: const TextStyle(fontSize: 14)),
          subtitle: Text(
              '${u.dist(r.distanceKm)} · 爬升 ${u.elev(r.elevGainM)} · ${r.type}',
              style: const TextStyle(fontSize: 11.5, color: AppTheme.txt3)),
          trailing:
              Text(u.speed(speed), style: const TextStyle(fontSize: 12, color: AppTheme.txt2)),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ActivityDetailPage(rideId: r.id)),
          ),
        ),
      ));
    }
    return out;
  }

  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return '今天';
    if (diff == 1) return '昨天';
    const wd = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return '${d.month}月${d.day}日 ${wd[d.weekday - 1]}';
  }

  /// 手动补记（AL-08）：录入一次没有 GPS 记录的骑行
  Future<void> _manualAdd(BuildContext context) async {
    final nameCtl = TextEditingController(text: '补记骑行');
    final kmCtl = TextEditingController();
    final minCtl = TextEditingController();
    final elevCtl = TextEditingController();
    var type = '公路';
    var when = DateTime.now();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setD) => AlertDialog(
          title: const Text('手动补记'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameCtl,
                    decoration: const InputDecoration(labelText: '名称')),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final t in const ['公路', '山地', '通勤', '训练'])
                      ChoiceChip(
                        label: Text(t, style: const TextStyle(fontSize: 12)),
                        selected: type == t,
                        onSelected: (_) => setD(() => type = t),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                    controller: kmCtl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '距离（km）')),
                const SizedBox(height: 8),
                TextField(
                    controller: minCtl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '时长（分钟）')),
                const SizedBox(height: 8),
                TextField(
                    controller: elevCtl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '累计爬升（m，可选）')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '时间：${when.year}-${when.month}-${when.day} '
                        '${when.hour}:${when.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: c,
                          initialDate: when,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (!c.mounted) return;
                        final t = await showTimePicker(
                          context: c,
                          initialTime: TimeOfDay.fromDateTime(when),
                        );
                        if (d != null && t != null) {
                          setD(() => when =
                              DateTime(d.year, d.month, d.day, t.hour, t.minute));
                        }
                      },
                      child: const Text('选择时间'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('取消')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('保存')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final km = double.tryParse(kmCtl.text.trim()) ?? 0;
    final min = double.tryParse(minCtl.text.trim()) ?? 0;
    final elev = double.tryParse(elevCtl.text.trim()) ?? 0;
    await ref.read(activityRepositoryProvider).saveRide(
          name: nameCtl.text.trim().isEmpty ? '补记骑行' : nameCtl.text.trim(),
          type: type,
          startAt: when,
          durationS: (min * 60).round(),
          movingS: (min * 60).round(),
          distanceM: km * 1000,
          elevGainM: elev,
          elevLossM: 0,
          hrAvg: null,
          hrMax: null,
          kcal: (km * 24).round(),
          source: '手动',
        );
    nameCtl.dispose();
    kmCtl.dispose();
    minCtl.dispose();
    elevCtl.dispose();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已补记一条骑行', textAlign: TextAlign.center)));
  }
}
