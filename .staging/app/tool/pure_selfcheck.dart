// 纯逻辑自检（无 Flutter 依赖）：供无 Flutter 工具环境运行 `dart tool/pure_selfcheck.dart`
import '../lib/core/periods.dart';
import '../lib/domain/stats/aggregate.dart';
import '../lib/domain/record/session_machine.dart';

int _failed = 0;
void check(bool cond, String msg) {
  if (cond) {
    print('PASS  $msg');
  } else {
    print('FAIL  $msg');
    _failed++;
  }
}

void main() {
  final now = DateTime(2026, 9, 7, 10, 30);
  RideLite ride(DateTime start, double km, {double min = 60}) =>
      RideLite(id: 0, startAt: start, distanceKm: km, durationMin: min, elevGainM: 100);
  final rides = [
    ride(DateTime(2026, 9, 7, 8), 12.5, min: 40),
    ride(DateTime(2026, 9, 6, 18), 30.0, min: 90),
    ride(DateTime(2026, 8, 31, 7), 50.0, min: 150),
    ride(DateTime(2026, 8, 30, 9), 8.0, min: 25),
    ride(DateTime(2026, 9, 1, 8), 20.0, min: 70),
    ride(DateTime(2026, 8, 1, 8), 99.0, min: 300),
  ];

  check(periodStart(now, PeriodKind.week) == DateTime(2026, 9, 7), '周起点=周一 9/7');
  final wk = sumPeriod(rides, now, PeriodKind.week);
  check(wk.count == 1 && (wk.km - 12.5).abs() < 1e-6, '本周(9/7起)=1次 12.5km');
  final d7 = last7Days(rides, now);
  check((d7[6] - 12.5).abs() < 1e-6, '近7天今天=12.5km');
  final heat = heatmap(rides, DateTime(2026, 9, 1));
  check((heat[6]! - 30.0).abs() < 1e-6, '热力图 9/6=30km');
  final tb = trendBuckets(rides, now, byMonth: true, n: 6);
  check((tb[5].km - 62.5).abs() < 1e-6, '9月桶=62.5km');
  final rec = personalRecords(rides);
  check(rec[0].value == '99.0 km', '纪录-最远 99km');
  check(rec[3].value == '20.0 km/h', '纪录-最快均速 20.0');

  final m = SessionMachine();
  check(m.start() && !m.start(), '防双会话');
  m.advance(dtSec: 10, speedKmh: 30);
  check(m.movingSec == 10, '计时推进');
  m.pause();
  m.advance(dtSec: 999, speedKmh: 30);
  check(m.movingSec == 10 && m.phase == SessionPhase.paused, '暂停不计时');
  m.resume();
  check(m.lap() && m.currentLap == 2, '计圈 L2');
  check(m.finish() && m.phase == SessionPhase.summary, '进入摘要');
  m.discard();
  check(m.phase == SessionPhase.idle, '丢弃回 idle');

  // 自动暂停
  final a = SessionMachine();
  a.start();
  a.advance(dtSec: 5, speedKmh: 20, stopped: true);
  check(a.phase == SessionPhase.paused && a.movingSec == 0, '自动暂停生效');

  print(_failed == 0 ? '\nALL PASS (${13} checks, 聚合8+状态机5)' : '\n$_failed FAILED');
  if (_failed > 0) throw StateError('selfcheck failed');
}
