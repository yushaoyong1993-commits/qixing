import '../../core/periods.dart';
import '../../data/activity_repository.dart';
import 'aggregate.dart' as k;

/// 聚合服务：唯一数据出口。
/// 首页概览(HP-04)、统计页(ST-02/04/05/11)、我的总览(ME-01) 都从这里取数，
/// 内部把 DB 的 Activity 映射为 [k.RideLite] 后复用纯计算内核 [aggregate.dart]。
class AggregateService {
  AggregateService(this._repo);

  final ActivityRepository _repo;

  Stream<List<k.RideLite>> watchRides() => _repo.watchRides();

  Future<k.PeriodStats> sumPeriod(DateTime now, PeriodKind kind) async {
    final rides = await _repo.rides();
    return k.sumPeriod(rides, now, kind);
  }

  Future<List<double>> last7DaysKms(DateTime now) async {
    final rides = await _repo.rides();
    return k.last7Days(rides, now);
  }

  Future<List<k.Bucket>> trend(DateTime now, {required bool byMonth}) async {
    final rides = await _repo.rides();
    return k.trendBuckets(rides, now, byMonth: byMonth);
  }

  Future<Map<int, double>> heatmap(DateTime month) async {
    final rides = await _repo.rides();
    return k.heatmap(rides, month);
  }

  Future<List<k.RecordItem>> personalRecords() async {
    final rides = await _repo.rides();
    return k.personalRecords(rides);
  }
}
