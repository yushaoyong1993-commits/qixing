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
