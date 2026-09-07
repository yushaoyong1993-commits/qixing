/// 地图引擎抽象（纯接口，禁止业务代码 import 厂商实现）。
/// 对应《骑行App_地图路线PRD_v1.1.md》MP-01~04 与《M0M1技术方案》§8。
library;

enum MapStyle { standard, satellite }

/// 轨迹点（业务层使用的经纬度，单位：度）。
class TrackPoint {
  const TrackPoint({required this.lat, required this.lng, this.speedKmh});
  final double lat;
  final double lng;
  final double? speedKmh;
}

/// 起/终点标记。
enum MarkerKind { start, end, position }

abstract interface class MapEngine {
  Future<void> init({required MapStyle style});
  Future<void> setStyle(MapStyle style);

  /// 以指定中心/缩放显示地图。
  Future<void> moveCamera({required double lat, required double lng, double zoom = 14});

  /// 绘制轨迹（首页缩略 / 地图页 / 活动详情 / 记录实时共用同一入口）。
  Future<void> addTrack(List<TrackPoint> points);

  Future<void> addMarker({required double lat, required double lng, required MarkerKind kind});

  Future<void> clearOverlays();
  Future<void> dispose();
}
