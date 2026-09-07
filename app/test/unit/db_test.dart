import 'package:flutter_test/flutter_test.dart';

import 'package:basho/core/periods.dart';
import 'package:basho/data/activity_repository.dart';
import 'package:basho/domain/stats/aggregate_service.dart';

void main() {
  test('DB 集成：保存一次骑行 → 读回并聚合（今日概览/纪录）一致', () async {
    final db = await openInMemoryDatabase();
    addTearDown(db.close);
    final repo = ActivityRepository(db);

    final now = DateTime.now();
    final id = await repo.saveRide(
      name: '晚间骑行',
      type: '公路',
      startAt: now.subtract(const Duration(hours: 1)),
      durationS: 1800,
      movingS: 1700,
      distanceM: 12500,
      elevGainM: 120,
      elevLossM: 110,
      hrAvg: 148,
      hrMax: 178,
    );
    expect(id, greaterThan(0));

    final svc = AggregateService(repo);
    final rides = await repo.rides();
    expect(rides.length, 1);
    expect(rides.first.distanceKm, closeTo(12.5, 1e-9));
    expect(rides.first.durationMin, closeTo(1700 / 60, 1e-9));

    final s = await svc.sumPeriod(now, PeriodKind.today);
    expect(s.count, 1);
    expect(s.km, closeTo(12.5, 1e-9));

    final rec = await svc.personalRecords();
    expect(rec[0].value, '12.5 km');
    expect(rec[3].value, '26.5 km/h'); // 12.5km / (1700/60 min → 28.33min) => 26.47
  });
}
