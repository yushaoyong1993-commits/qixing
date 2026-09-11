/// 单位换算——全局唯一换算入口（PRD：单位切换即时重算，不改存储原值）。
library;

const double metersPerKm = 1000;
const double metersPerMile = 1609.344;

enum DistanceUnit { km, mi }
enum MassUnit { kg, lb }

String formatDistanceKm(double km, DistanceUnit unit, {int digits = 1}) {
  final v = unit == DistanceUnit.km ? km : km / (metersPerMile / metersPerKm);
  return v.toStringAsFixed(digits);
}

String formatElevationM(double m, DistanceUnit unit) {
  final v = unit == DistanceUnit.km ? m : m / (metersPerMile / metersPerKm) * metersPerKm / metersPerMile;
  // 爬升一般以米/英尺展示
  return v.toStringAsFixed(0);
}


/// 单位制：公制（km / m / km/h）/ 英制（mi / ft / mph）。
enum UnitSystem { metric, imperial }

/// 全局单位偏好（设置页可切；只影响显示，不改存储原值）。
class UnitPrefs {
  const UnitPrefs(this.system);

  final UnitSystem system;

  static const String keyUnitSystem = 'unit_system';

  bool get metric => system == UnitSystem.metric;

  static UnitPrefs fromSettings(Map<String, String> s) => UnitPrefs(
      s[keyUnitSystem] == 'imperial' ? UnitSystem.imperial : UnitSystem.metric);

  double _kmToMi(double km) => km * 0.621371;
  double _mToFt(double m) => m * 3.28084;

  /// 距离数值（用于磁贴 + 单独单位标签）
  String distValue(double km, {int digits = 1}) =>
      (metric ? km : _kmToMi(km)).toStringAsFixed(digits);

  /// 距离单位标签：km / mi
  String get distUnit => metric ? 'km' : 'mi';

  /// 距离（带单位）
  String dist(double km, {int digits = 1}) => '${distValue(km, digits: digits)} $distUnit';

  /// 速度数值 / 速度（带单位）
  String speedValue(double kmh, {int digits = 1}) =>
      (metric ? kmh : _kmToMi(kmh)).toStringAsFixed(digits);

  String speed(double kmh, {int digits = 1}) =>
      '${speedValue(kmh, digits: digits)} ${metric ? 'km/h' : 'mph'}';

  /// 海拔/爬升
  String elev(double m) =>
      metric ? '${m.round()} m' : '${_mToFt(m).round()} ft';

  String get elevUnit => metric ? 'm' : 'ft';

  /// 爬升数值（配 elevUnit 使用）
  String elevValue(double m) => metric ? m.round().toString() : _mToFt(m).round().toString();
}
