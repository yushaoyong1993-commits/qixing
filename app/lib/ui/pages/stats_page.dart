import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/periods.dart';
import '../../data/providers.dart';
import '../../domain/stats/aggregate.dart' as k;
import '../../theme/app_theme.dart';

/// 统计页（M1）：周期指标格 + 近 7 天柱状 + 近 6 月趋势 + 日历热力图 + 个人纪录(含 10/50/100km)。
class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});

  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  int _period = 1; // 默认本周
  int _heatOff = 0; // 热力图月份偏移（0=本月）

  @override
  Widget build(BuildContext context) {
    final rides = ref.watch(ridesProvider).valueOrNull ?? const <k.RideLite>[];
    final kinds = [PeriodKind.today, PeriodKind.week, PeriodKind.month];
    final now = DateTime.now();
    final s = k.sumPeriod(rides, now, kinds[_period]);
    final days = k.last7Days(rides, now);
    final months = k.trendBuckets(rides, now, byMonth: true);
    final recs = [...k.personalRecords(rides), ...k.windowRecords(rides)];

    return Scaffold(
      appBar: AppBar(title: const Text('统计')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _liveBanner(context),
          _periodSeg(kinds, now),
          _tiles(s),
          _deltaLine(rides, now, s),
          _section('近 7 天'),
          _bars(days, lastNDayStarts(now, 7)),
          _section('周·月趋势'),
          _trendSeg(),
          _monthBars(months),
          _section('日历热力图 · 点击有骑行日查看当天（未完成）'),
          _heatmap(context, rides, now),
          _section('累计'),
          _totals(rides),
          _section('个人纪录'),
          _records(recs),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// 骑行进行中横幅（原型 statLive）——需要跨页会话状态，暂为占位
  Widget _liveBanner(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.card2,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.fiber_manual_record, size: 12, color: AppTheme.txt3),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('骑行进行中横幅（未完成）',
                  style: TextStyle(fontSize: 12.5, color: AppTheme.txt2)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('回到记录', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );

  /// 较上期同期变化 + 目标占位
  Widget _deltaLine(List<k.RideLite> rides, DateTime now, k.PeriodStats cur) {
    final kind = [PeriodKind.today, PeriodKind.week, PeriodKind.month][_period];
    final prevDate = switch (kind) {
      PeriodKind.today => now.subtract(const Duration(days: 1)),
      PeriodKind.week => now.subtract(const Duration(days: 7)),
      PeriodKind.month => DateTime(now.year, now.month - 1, now.day),
    };
    final prev = k.sumPeriod(rides, prevDate, kind);
    final text = prev.km <= 0
        ? '较上期无可比数据'
        : '较上期同期 ${cur.km >= prev.km ? '+' : ''}${((cur.km - prev.km) / prev.km * 100).round()}%';
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text, style: const TextStyle(fontSize: 11.5, color: AppTheme.txt3)),
          const Text('目标待设（未完成）',
              style: TextStyle(fontSize: 11.5, color: AppTheme.txt3)),
        ],
      ),
    );
  }

  /// 趋势粒度切换（近 8 周 / 近 6 月）
  Widget _trendSeg() => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            ChoiceChip(
              label: const Text('近 8 周（未完成）', style: TextStyle(fontSize: 12)),
              selected: false,
              onSelected: (_) {},
            ),
            const SizedBox(width: 6),
            ChoiceChip(
              label: const Text('近 6 月', style: TextStyle(fontSize: 12)),
              selected: true,
              onSelected: (_) {},
            ),
          ],
        ),
      );

  /// 累计（原型 ctKm/ctDur/ctElev/ctCnt）
  Widget _totals(List<k.RideLite> rides) {
    final u = ref.watch(unitPrefsProvider);
    var km = 0.0, min = 0.0, elev = 0.0;
    for (final r in rides) {
      km += r.distanceKm;
      min += r.durationMin;
      elev += r.elevGainM;
    }
    return _card(
      Row(
        children: [
          _tile(u.distValue(km), '总里程 ${u.distUnit}'),
          _tile('${(min / 60).toStringAsFixed(1)} h', '总时长'),
          _tile(u.elevValue(elev), '总爬升 ${u.elevUnit}'),
          _tile('${rides.length}', '总次数'),
        ],
      ),
    );
  }

  Widget _periodSeg(List<PeriodKind> kinds, DateTime now) {
    final labels = ['今日', '本周', '本月'];
    return Row(
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
                child: Text(labels[i],
                    style: TextStyle(
                        fontWeight: _period == i ? FontWeight.w600 : FontWeight.w400,
                        color: _period == i ? AppTheme.txt : AppTheme.txt2)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _tiles(k.PeriodStats s) {
    final u = ref.watch(unitPrefsProvider);
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.line),
      ),
      child: Row(
        children: [
          _tile('${s.count}', '次数'),
          _tile(u.distValue(s.km), '距离 ${u.distUnit}'),
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

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      );

  Widget _bars(List<double> days, List<DateTime> starts) {
    final max = days.fold<double>(1, (a, b) => b > a ? b : a);
    return _card(Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < days.length; i++)
              Expanded(
                child: Container(
                  height: 8 + 90 * (days[i] / max),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: i == days.length - 1
                        ? AppTheme.accent
                        : Color.lerp(AppTheme.accent, Colors.white, 0.6),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
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
    ));
  }

  Widget _monthBars(List<k.Bucket> buckets) {
    final max = buckets.fold<double>(1, (a, b) => b.km > a ? b.km : a);
    return _card(Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final b in buckets)
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: 8 + 70 * (b.km / max),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: Color.lerp(AppTheme.accent, Colors.white, 0.5),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
                const SizedBox(height: 4),
                Text(b.label, style: const TextStyle(fontSize: 9, color: AppTheme.txt3)),
              ],
            ),
          ),
      ],
    ));
  }

  Widget _heatmap(BuildContext context, List<k.RideLite> rides, DateTime now) {
    final base = DateTime(now.year, now.month - _heatOff, 1);
    final map = k.heatmap(rides, base);
    final dim = DateTime(base.year, base.month + 1, 0).day;
    final lead = (DateTime(base.year, base.month, 1).weekday - DateTime.monday) % 7;
    final values = map.values;
    final max = values.isEmpty ? 1.0 : values.reduce((a, b) => b > a ? b : a);

    Widget cell(String? day, double? km) {
      final Color bg;
      if (km == null) {
        bg = AppTheme.bg2;
      } else {
        final t = (km / max).clamp(0.0, 1.0);
        bg = Color.lerp(const Color(0xFFFFE9DD), AppTheme.accent, t)!;
      }
      return Container(
        height: 26,
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        alignment: Alignment.center,
        child: day == null
            ? null
            : Text(day, style: TextStyle(fontSize: 10, color: (km != null && km / max > 0.55) ? Colors.white : AppTheme.txt2, fontWeight: km != null && km / max > 0.7 ? FontWeight.w700 : FontWeight.w400)),
      );
    }

    final cells = <Widget>[
      for (var i = 0; i < lead; i++) cell(null, null),
      for (var d = 1; d <= dim; d++) cell('$d', map[d]),
    ];

    return _card(Column(
      children: [
        Row(
          children: [
            IconButton(
                onPressed: () => setState(() => _heatOff++),
                icon: const Icon(Icons.chevron_left, size: 18),
                visualDensity: VisualDensity.compact),
            Expanded(
              child: Text('${base.year}年${base.month}月',
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            IconButton(
                onPressed: _heatOff > 0 ? () => setState(() => _heatOff--) : null,
                icon: const Icon(Icons.chevron_right, size: 18),
                visualDensity: VisualDensity.compact),
          ],
        ),
        Row(children: [for (final w in ['一', '二', '三', '四', '五', '六', '日']) Expanded(child: Center(child: Text(w, style: const TextStyle(fontSize: 10, color: AppTheme.txt3))))]),
        const SizedBox(height: 3),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: cells,
        ),
      ],
    ));
  }

  Widget _records(List<k.RecordItem> recs) {
    return _card(Column(
      children: [
        for (final r in recs)
          ListTile(
            dense: true,
            title: Text(r.label, style: const TextStyle(fontSize: 13.5)),
            trailing: Text(r.value, style: const TextStyle(fontSize: 13.5, color: AppTheme.accentInk)),
          ),
      ],
    ));
  }

  Widget _card(Widget child) => Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.line),
        ),
        child: child,
      );
}
