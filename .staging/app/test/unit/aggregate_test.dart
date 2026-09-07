import 'package:flutter_test/flutter_test.dart';

import 'package:basho/core/periods.dart';
import 'package:basho/domain/stats/aggregate.dart';

void main() {
  // 固定"今天"：2026-09-07（周一）—— 本周起点即 9/7。
  final now = DateTime(2026, 9, 7, 10, 30);

  RideLite ride(DateTime start, double km, {double min = 60, double elev = 100}) =>
      RideLite(id: start.millisecondsSinceEpoch, startAt: start, distanceKm: km, durationMin: min, elevGainM: elev);

  final rides = [
    ride(DateTime(2026, 9, 7, 8), 12.5, min: 40, elev: 120), // 今日（本周一起点当日）
    ride(DateTime(2026, 9, 6, 18), 30.0, min: 90, elev: 300), // 上周日：本周外
    ride(DateTime(2026, 8, 31, 7), 50.0, min: 150, elev: 500), // 8 月（上个月）
    ride(DateTime(2026, 8, 30, 9), 8.0, min: 25), // 8 月
    ride(DateTime(2026, 9, 1, 8), 20.0, min: 70), // 9月 / 近7天首日
    ride(DateTime(2026, 8, 1, 8), 99.0, min: 300), // 8 月
  ];

  test('periodStart：2026-09-07 为周一，本周起点即当天', () {
    expect(periodStart(now, PeriodKind.week), DateTime(2026, 9, 7));
    expect(periodStart(now, PeriodKind.today), DateTime(2026, 9, 7));
    expect(periodStart(now, PeriodKind.month), DateTime(2026, 9, 1));
  });

  test('今日统计只含 9/7 的一次', () {
    final s = sumPeriod(rides, now, PeriodKind.today);
    expect(s.count, 1);
    expect(s.km, closeTo(12.5, 1e-9));
  });

  test('本周统计（9/7 起）：仅含当日骑行，上周日 9/6 不计', () {
    final s = sumPeriod(rides, now, PeriodKind.week);
    expect(s.count, 1);
    expect(s.km, closeTo(12.5, 1e-9));
  });

  test('本月统计：9/1 起 3 次（9/7、9/6、9/1），不含 8/31', () {
    final s = sumPeriod(rides, now, PeriodKind.month);
    expect(s.count, 3);
    expect(s.km, closeTo(62.5, 1e-9));
  });

  test('近7天与热力图桶正确', () {
    final d7 = last7Days(rides, now);
    expect(d7[6], closeTo(12.5, 1e-9)); // 今天 9/7
    expect(d7[0], closeTo(20.0, 1e-9)); // 9/1
    final heat = heatmap(rides, DateTime(2026, 9, 1));
    expect(heat[7], closeTo(12.5, 1e-9));
    expect(heat[6], closeTo(30.0, 1e-9));
    expect(heat[1], closeTo(20.0, 1e-9));
    expect(heat.containsKey(5), isFalse);
    final heatAug = heatmap(rides, DateTime(2026, 8, 1));
    expect(heatAug[31], closeTo(50.0, 1e-9));
  });

  test('近6月桶：9月=62.5、8月=99+50=149、末桶累积=219.5', () {
    final b = trendBuckets(rides, now, byMonth: true, n: 6);
    expect(b.length, 6);
    expect(b[5].km, closeTo(62.5, 1e-9)); // 2026-09
    expect(b[4].km, closeTo(149.0, 1e-9)); // 2026-08 含 8/31
    expect(b[5].cumKm, closeTo(219.5, 1e-9));
  });

  test('个人纪录：最远 99km，最快均速 20.0 km/h', () {
    final rec = personalRecords(rides);
    expect(rec[0].value, '99.0 km');
    expect(rec[3].value, '20.0 km/h');
  });
}
