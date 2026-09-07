/// 日期周期工具：今日 / 本周(周一起始) / 本月，与统计 PRD ST-01 口径一致。
library;

enum PeriodKind { today, week, month }

/// 当前周期起点（本地时间 00:00）。
DateTime periodStart(DateTime now, PeriodKind kind) {
  final d = DateTime(now.year, now.month, now.day);
  switch (kind) {
    case PeriodKind.today:
      return d;
    case PeriodKind.week:
      final mondayOffset = (d.weekday - DateTime.monday) % 7;
      return d.subtract(Duration(days: mondayOffset));
    case PeriodKind.month:
      return DateTime(d.year, d.month, 1);
  }
}

/// 当前周期终点（开区间，[start, end)）。
DateTime periodEnd(DateTime now, PeriodKind kind) {
  switch (kind) {
    case PeriodKind.today:
      return periodStart(now, kind).add(const Duration(days: 1));
    case PeriodKind.week:
      return periodStart(now, kind).add(const Duration(days: 7));
    case PeriodKind.month:
      final s = periodStart(now, kind);
      return DateTime(s.year, s.month + 1, 1);
  }
}

/// 最近 N 天（含今天）起点列表，顺序为过去→今天。
List<DateTime> lastNDayStarts(DateTime now, int n) {
  return List.generate(n, (i) {
    final d = DateTime(now.year, now.month, now.day);
    return d.subtract(Duration(days: n - 1 - i));
  });
}

/// 最近 N 周（含本周）起点列表（周一起始），顺序为过去→本周。
List<DateTime> lastNWeekStarts(DateTime now, int n) {
  final thisWeek = periodStart(now, PeriodKind.week);
  return List.generate(n, (i) => thisWeek.subtract(Duration(days: 7 * (n - 1 - i))));
}

/// 最近 N 个月（含本月）第一天列表。
List<DateTime> lastNMonthStarts(DateTime now, int n) {
  return List.generate(n, (i) {
    final d = DateTime(now.year, now.month - (n - 1 - i), 1);
    return DateTime(d.year, d.month, 1);
  });
}

String shortDayLabel(DateTime d) => '${d.month}/${d.day}';
