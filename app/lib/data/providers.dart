import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/units.dart';
import '../domain/stats/aggregate.dart' as k;
import '../domain/stats/aggregate_service.dart';
import 'activity_repository.dart';
import 'route_repository.dart';
import 'settings_repository.dart';

/// 数据库连接。运行时在 main 中通过 override 注入（文件库）；
/// 测试用 override 注入内存库（openInMemoryDatabase）。
final databaseProvider = Provider<BashoDatabase>(
  (_) => throw UnimplementedError('databaseProvider must be overridden'),
);

final activityRepositoryProvider = Provider<ActivityRepository>(
  (ref) => ActivityRepository(ref.watch(databaseProvider)),
);

final aggregateServiceProvider = Provider<AggregateService>(
  (ref) => AggregateService(ref.watch(activityRepositoryProvider)),
);

/// 全部骑行（倒序）的反应式流：保存/删除后自动推新（Drift watch）。
final ridesProvider = StreamProvider<List<k.RideLite>>(
  (ref) => ref.watch(aggregateServiceProvider).watchRides(),
);

final routeRepositoryProvider = Provider<RouteRepository>(
  (ref) => RouteRepository(ref.watch(databaseProvider)),
);

final routesProvider = StreamProvider<List<RouteModel>>(
  (ref) => ref.watch(routeRepositoryProvider).watchRoutes(),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(databaseProvider)),
);

/// 全部设置项（反应式）
final settingsProvider = StreamProvider<Map<String, String>>(
  (ref) => ref.watch(settingsRepositoryProvider).watchAll(),
);

/// 单位偏好（由设置派生；设置页切换后全局立即生效）
final unitPrefsProvider = Provider<UnitPrefs>((ref) {
  final s = ref.watch(settingsProvider).valueOrNull ?? const <String, String>{};
  return UnitPrefs.fromSettings(s);
});
