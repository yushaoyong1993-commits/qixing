/// 统计聚合内核（纯 Dart，无 IO）：
/// 首页概览(HP-04)、统计页(ST-02/04/05/11)、我的总览(ME-01) 共用同一套口径。
/// 数据来源在运行时由 DAO/AggregateService 提供，这里只做纯计算，保证可单测。
library;

import '../../core/periods.dart';

/// 参与统计的轻量活动视图。
class RideLite {
  const RideLite({
    required this.id,
    required this.startAt,
    required this.distanceKm,
    required this.durationMin,
    required this.elevGainM,
  });

  final int id;
  final DateTime startAt;
  final double distanceKm;
  final double durationMin;
  final double elevGainM;
}

class PeriodStats {
  const PeriodStats({required this.count, required this.km, required this.min, required this.elev});
  final int count;
  final double km;
  final double min;
  final double elev;
}

/// 桶（天/周/月）聚合，用于柱状图与累积折线。
class Bucket {
  Bucket({required this.label, required this.km}) : cumKm = 0;
  final String label;
  final double km;
  double cumKm;
}

PeriodStats sumPeriod(Iterable<RideLite> rides, DateTime now, PeriodKind kind) {
  final from = periodStart(now, kind);
  final to = periodEnd(now, kind);
  return sumBetween(rides, from, to);
}

PeriodStats sumBetween(Iterable<RideLite> rides, DateTime from, DateTime to) {
  var km = 0.0, min = 0.0, elev = 0.0, count = 0;
  for (final r in rides) {
    if (!r.startAt.isBefore(from) && r.startAt.isBefore(to)) {
      km += r.distanceKm;
      min += r.durationMin;
      elev += r.elevGainM;
      count++;
    }
  }
  return PeriodStats(count: count, km: km, min: min, elev: elev);
}

/// 近 7 天（含今天）日距离，index 0 = 6 天前。
List<double> last7Days(Iterable<RideLite> rides, DateTime now) {
  final starts = lastNDayStarts(now, 7);
  return starts.map((s) => sumBetween(rides, s, s.add(const Duration(days: 1))).km).toList();
}

/// 近 N 周（默认 8）/ 近 N 月（默认 6）桶序列，附带累积折线所需的 cumKm。
List<Bucket> trendBuckets(Iterable<RideLite> rides, DateTime now,
    {required bool byMonth, int n = 0}) {
  final starts = byMonth
      ? lastNMonthStarts(now, n == 0 ? 6 : n)
      : lastNWeekStarts(now, n == 0 ? 8 : n);
  final periodLen = byMonth ? null : const Duration(days: 7);
  final out = <Bucket>[];
  for (var i = 0; i < starts.length; i++) {
    final s = starts[i];
    final to = byMonth
        ? DateTime(s.year, s.month + 1, 1)
        : s.add(periodLen!);
    final km = sumBetween(rides, s, to).km;
    out.add(Bucket(label: byMonth ? '${s.month}月' : shortDayLabel(s), km: km));
  }
  var cum = 0.0;
  for (final b in out) {
    cum += b.km;
    b.cumKm = cum;
  }
  return out;
}

/// 日历热力图：返回某月 [1..daysInMonth] 每日距离；可用 monthMaxKm 计算色阶。
Map<int, double> heatmap(Iterable<RideLite> rides, DateTime month) {
  final from = DateTime(month.year, month.month, 1);
  final to = DateTime(month.year, month.month + 1, 1);
  final map = <int, double>{};
  for (final r in rides) {
    if (!r.startAt.isBefore(from) && r.startAt.isBefore(to)) {
      map[r.startAt.day] = (map[r.startAt.day] ?? 0) + r.distanceKm;
    }
  }
  return map;
}

/// 个人纪录（单次维度）：最远 / 最长 / 最大爬升 / 最快均速。
class RecordItem {
  const RecordItem(this.label, this.value);
  final String label;
  final String value;
}

List<RecordItem> personalRecords(Iterable<RideLite> rides) {
  var maxKm = 0.0, maxMin = 0.0, maxElev = 0.0, bestSpd = 0.0;
  for (final r in rides) {
    if (r.distanceKm > maxKm) maxKm = r.distanceKm;
    if (r.durationMin > maxMin) maxMin = r.durationMin;
    if (r.elevGainM > maxElev) maxElev = r.elevGainM;
    if (r.durationMin > 0) {
      final spd = r.distanceKm / (r.durationMin / 60);
      if (spd > bestSpd) bestSpd = spd;
    }
  }
  return [
    RecordItem('最远单次', maxKm > 0 ? '${maxKm.toStringAsFixed(1)} km' : '—'),
    RecordItem('单次最长', maxMin > 0 ? _fmtMin(maxMin) : '—'),
    RecordItem('最大爬升', maxElev > 0 ? '${maxElev.round()} m' : '—'),
    RecordItem('最快均速', bestSpd > 0 ? '${bestSpd.toStringAsFixed(1)} km/h' : '—'),
  ];
}

String _fmtMin(double min) {
  final h = (min / 60).floor();
  if (h == 0) return '${min.round()} min';
  return '$h h ${(min % 60).round()} m';
}

/// 最快 10/50/100 km：按轨迹整体均速外推（正式实现按轨迹滚动窗口切片）。
/// 需要活动里程 >= 窗口才参与；返回"最快 X km"纪录。
List<RecordItem> windowRecords(Iterable<RideLite> rides, {List<int> windows = const [10, 50, 100]}) {
  final out = <RecordItem>[];
  for (final w in windows) {
    double? best;
    for (final r in rides) {
      if (r.distanceKm >= w && r.durationMin > 0) {
        final spd = r.distanceKm / (r.durationMin / 60);
        if (best == null || spd > best) best = spd;
      }
    }
    out.add(RecordItem('最快 $w km', best == null ? '—（距离不足）' : _fmtClock(w / best)));
  }
  return out;
}

String _fmtClock(double hours) {
  final total = (hours * 3600).round();
  final h = total ~/ 3600, m = (total % 3600) ~/ 60, s = total % 60;
  String p(int v) => v.toString().padLeft(2, '0');
  return h > 0 ? '${p(h)}:${p(m)}:${p(s)}' : '${p(m)}:${p(s)}';
}
