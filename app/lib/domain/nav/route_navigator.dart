import 'dart:math' as math;

import 'package:latlong2/latlong.dart' show LatLng;

/// 转向提示（左/直行/右）
enum TurnDir { left, straight, right }

/// 导航进度快照
class NavProgress {
  const NavProgress({
    required this.alongM,
    required this.totalM,
    required this.remainingM,
    required this.offRouteM,
    required this.turnInM,
    required this.turnDir,
    required this.arrived,
  });

  /// 已沿路线前进的距离（米）
  final double alongM;
  final double totalM;
  final double remainingM;

  /// 偏离路线的距离（米）
  final double offRouteM;

  /// 距下一个转向点的距离（米）
  final double turnInM;
  final TurnDir turnDir;
  final bool arrived;

  /// 进度百分比 0~1
  double get progress => totalM <= 0 ? 0 : (alongM / totalM).clamp(0.0, 1.0);

  bool get offRoute => offRouteM > 60; // 超过 60m 视为偏离
}

/// 沿路线导航的纯几何引擎：
/// 位置 → 最近点/已前进距离/剩余距离/偏航距离/下一个转向提示/是否到达。
/// 坐标与路线必须同一坐标系（本 App 内统一使用 GCJ-02）。
class RouteNavigator {
  RouteNavigator(List<LatLng> route)
      : _route = List.unmodifiable(route),
        _cum = _cumulative(route);

  final List<LatLng> _route;
  final List<double> _cum; // 每个顶点的累计距离（米）

  List<LatLng> get route => _route;
  double get totalM => _cum.isEmpty ? 0 : _cum.last;

  // ---- 公共 ----

  /// 用当前位置更新导航进度
  NavProgress update(LatLng pos) {
    final (alongM, offM) = _project(pos);
    final remaining = math.max(0.0, totalM - alongM);
    final (turnIn, turnDir) = _nextTurn(alongM);
    return NavProgress(
      alongM: alongM,
      totalM: totalM,
      remainingM: remaining,
      offRouteM: offM,
      turnInM: turnIn,
      turnDir: turnDir,
      arrived: remaining < 40,
    );
  }

  /// 已骑部分的坐标点（用于地图上区分已骑/未骑）
  List<LatLng> donePoints(double alongM) {
    final out = <LatLng>[];
    for (var i = 0; i < _route.length; i++) {
      if (_cum[i] <= alongM) {
        out.add(_route[i]);
      } else {
        out.add(_interpolateAt(alongM));
        break;
      }
    }
    return out;
  }

  /// 未骑部分的坐标点
  List<LatLng> todoPoints(double alongM) {
    final out = <LatLng>[_interpolateAt(alongM)];
    for (var i = 0; i < _route.length; i++) {
      if (_cum[i] > alongM) out.add(_route[i]);
    }
    return out;
  }

  // ---- 内部 ----

  static List<double> _cumulative(List<LatLng> pts) {
    final cum = <double>[0];
    for (var i = 1; i < pts.length; i++) {
      cum.add(cum[i - 1] + _meters(pts[i - 1], pts[i]));
    }
    return cum;
  }

  /// 等距圆柱近似：把经纬度差换成米（同一路线尺度内足够精确）
  static double _meters(LatLng a, LatLng b) {
    final latM = (b.latitude - a.latitude) * 111320.0;
    final lonM = (b.longitude - a.longitude) *
        111320.0 *
        math.cos((a.latitude + b.latitude) / 2 * math.pi / 180);
    return math.sqrt(latM * latM + lonM * lonM);
  }

  /// 位置在路线上的投影：返回（已前进距离, 偏离距离）
  (double, double) _project(LatLng pos) {
    if (_route.length < 2) return (0, 0);
    final lat0 = pos.latitude * math.pi / 180;
    final kx = 111320.0 * math.cos(lat0);
    const ky = 111320.0;

    double px(double lon, double refLon) => (lon - refLon) * kx;
    double py(double lat) => lat * ky;

    final refLon = pos.longitude;
    final pxPos = 0.0, pyPos = py(pos.latitude);

    var bestOff = double.infinity;
    var bestAlong = 0.0;
    for (var i = 1; i < _route.length; i++) {
      final ax = px(_route[i - 1].longitude, refLon), ay = py(_route[i - 1].latitude);
      final bx = px(_route[i].longitude, refLon), by = py(_route[i].latitude);
      final dx = bx - ax, dy = by - ay;
      final len2 = dx * dx + dy * dy;
      var t = len2 <= 0 ? 0.0 : ((pxPos - ax) * dx + (pyPos - ay) * dy) / len2;
      t = t.clamp(0.0, 1.0);
      final cx = ax + t * dx, cy = ay + t * dy;
      final off = math.sqrt(math.pow(pxPos - cx, 2) + math.pow(pyPos - cy, 2));
      if (off < bestOff) {
        bestOff = off;
        final segLen = _cum[i] - _cum[i - 1];
        bestAlong = _cum[i - 1] + segLen * t;
      }
    }
    return (bestAlong, bestOff);
  }

  LatLng _interpolateAt(double alongM) {
    if (_route.isEmpty) return const LatLng(0, 0);
    if (alongM <= 0) return _route.first;
    if (alongM >= totalM) return _route.last;
    for (var i = 1; i < _route.length; i++) {
      if (_cum[i] >= alongM) {
        final segLen = _cum[i] - _cum[i - 1];
        final t = segLen <= 0 ? 0.0 : (alongM - _cum[i - 1]) / segLen;
        return LatLng(
          _route[i - 1].latitude + (_route[i].latitude - _route[i - 1].latitude) * t,
          _route[i - 1].longitude + (_route[i].longitude - _route[i - 1].longitude) * t,
        );
      }
    }
    return _route.last;
  }

  /// 航向角（度，正北为 0，顺时针）
  double _bearing(LatLng a, LatLng b) {
    final lat1 = a.latitude * math.pi / 180, lat2 = b.latitude * math.pi / 180;
    final dLon = (b.longitude - a.longitude) * math.pi / 180;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final deg = math.atan2(y, x) * 180 / math.pi;
    return (deg + 360) % 360;
  }

  /// 找到前方第一个"明显转弯"的顶点（转向角 ≥ 30°）
  (double, TurnDir) _nextTurn(double alongM) {
    for (var i = 1; i < _route.length - 1; i++) {
      if (_cum[i] <= alongM + 5) continue; // 已经过的顶点跳过
      final b1 = _bearing(_route[i - 1], _route[i]);
      final b2 = _bearing(_route[i], _route[i + 1]);
      var d = b2 - b1;
      while (d > 180) {
        d -= 360;
      }
      while (d < -180) {
        d += 360;
      }
      if (d.abs() >= 30) {
        return (
          math.max(0.0, _cum[i] - alongM),
          d > 0 ? TurnDir.right : TurnDir.left,
        );
      }
    }
    return (math.max(0.0, totalM - alongM), TurnDir.straight);
  }
}
