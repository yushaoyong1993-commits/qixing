import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/periods.dart';
import '../../data/providers.dart';
import '../../domain/stats/aggregate.dart' as k;
import '../../theme/app_theme.dart';

/// 统计页（M1）：周期指标格 + 近 7 天柱状 + 个人纪录。
/// 数据源：ridesProvider（Drift watch），与首页/我的共用同一统计内核。
class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});

  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  int _period = 1; // 默认本周

  @override
  Widget build(BuildContext context) {
    final rides = ref.watch(ridesProvider).valueOrNull ?? const <k.RideLite>[];
    final kinds = [PeriodKind.today, PeriodKind.week, PeriodKind.month];
    final now = DateTime.now();
    final s = k.sumPeriod(rides, now, kinds[_period]);
    final days = k.last7Days(rides, now);
    final recs = k.personalRecords(rides);

    return Scaffold(
      appBar: AppBar(title: const Text('统计')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              for (var i = 0; i < 3; i++)
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _period = i),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _period == i ? AppTheme.card : AppTheme.card2,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(['今日', '本周', '本月'][i],
                          style: TextStyle(
                              fontWeight: _period == i ? FontWeight.w600 : FontWeight.w400,
                              color: _period == i ? AppTheme.txt : AppTheme.txt2)),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _tiles(s),
          const SizedBox(height: 20),
          const Text('近 7 天', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _bars(context, days, now),
          const SizedBox(height: 20),
          const Text('个人纪录', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _records(recs),
        ],
      ),
    );
  }

  Widget _tiles(k.PeriodStats s) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.line),
      ),
      child: Row(
        children: [
          _tile('${s.count}', '次数'),
          _tile(s.km.toStringAsFixed(1), '距离 km'),
          _tile('${s.min.round()}', '时长 min'),
          _tile('${s.elev.round()}', '爬升 m'),
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

  Widget _bars(BuildContext context, List<double> days, DateTime now) {
    final max = days.fold<double>(1, (a, b) => b > a ? b : a);
    final starts = lastNDayStarts(now, 7);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < days.length; i++)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: 8 + 90 * (days[i] / max),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: i == days.length - 1 ? AppTheme.accent : Color.lerp(AppTheme.accent, Colors.white, 0.6),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final d in starts)
                Expanded(
                  child: Text('${d.month}/${d.day}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 9.5, color: AppTheme.txt3)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _records(List<k.RecordItem> recs) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        children: [
          for (final r in recs)
            ListTile(
              dense: true,
              title: Text(r.label, style: const TextStyle(fontSize: 13.5)),
              trailing: Text(r.value, style: const TextStyle(fontSize: 13.5, color: AppTheme.accentInk)),
            ),
        ],
      ),
    );
  }
}
