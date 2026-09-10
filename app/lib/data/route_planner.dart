import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' show LatLng;

/// 高德 Web 服务 key（可选）：如需用高德骑行路径规划，把"Web服务"类型的 key 填这里。
/// 留空则使用 OSRM（免 key，返回 WGS84，与天地图/OSM 坐标一致无需纠偏）。
const String kAmapWebServiceKey = '579bd0817cbc0a1f642508947879682d';

/// 路径规划：把 A→B 两点之间按道路生成折线点（用于手绘路线的"沿道路"效果）。
class RoutePlanner {
  RoutePlanner({http.Client? client}) : _c = client ?? http.Client();

  final http.Client _c;

  /// 最近一次规划实际使用的引擎（amap / brouter / osrm / none）
  String lastEngine = 'none';

  /// 骑行路径规划（真骑行 profile）。失败返回 null（调用方回退为直线）。
  /// 优先级：高德骑行(配了 Web服务 key) → BRouter 骑行(免 key) → OSRM 兜底。
  Future<List<LatLng>?> planRiding(LatLng a, LatLng b) async {
    lastEngine = 'none';
    if (kAmapWebServiceKey.trim().isNotEmpty) {
      final r = await _amapRiding(a, b);
      if (r != null && r.length > 1) {
        lastEngine = 'amap';
        return r;
      }
    }
    final br = await _brouterBike(a, b);
    if (br != null && br.length > 1) {
      lastEngine = 'brouter';
      return br;
    }
    final os = await _osrmFallback(a, b);
    if (os != null && os.length > 1) {
      lastEngine = 'osrm';
      return os;
    }
    return null;
  }

  /// BRouter 骑行规划（免 key；profile=trekking 为骑行/碎石路取向，fastbike 为公路车）
  Future<List<LatLng>?> _brouterBike(LatLng a, LatLng b) async {
    try {
      final uri = Uri.https('brouter.de', '/brouter', {
        'lonlats': '${a.longitude},${a.latitude}|${b.longitude},${b.latitude}',
        'profile': 'trekking',
        'alternativeidx': '0',
        'format': 'geojson',
      });
      final res = await _c.get(uri).timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final feats = (json['features'] as List?) ?? const [];
      if (feats.isEmpty) return null;
      final coords = (feats.first['geometry']?['coordinates'] as List?) ?? const [];
      final pts = <LatLng>[];
      for (final c in coords) {
        if (c is List && c.length >= 2) {
          pts.add(LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()));
        }
      }
      return pts.isEmpty ? null : pts;
    } catch (_) {
      return null;
    }
  }

  /// 高德骑行规划 v4（bicycling 接口；v3 无骑行）。返回 GCJ-02 → 转 WGS84 对齐天地图/OSM
  Future<List<LatLng>?> _amapRiding(LatLng a, LatLng b) async {
    try {
      final uri = Uri.https('restapi.amap.com', '/v4/direction/bicycling', {
        'origin': '${a.longitude},${a.latitude}',
        'destination': '${b.longitude},${b.latitude}',
        'key': kAmapWebServiceKey,
      });
      final res = await _c.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final paths = (json['data']?['paths'] as List?) ?? const [];
      if (paths.isEmpty) return null;
      final steps = (paths.first['steps'] as List?) ?? const [];
      final pts = <LatLng>[];
      for (final st in steps) {
        final poly = (st['polyline'] as String?) ?? '';
        for (final pair in poly.split(';')) {
          final xy = pair.split(',');
          if (xy.length == 2) {
            final lng = double.tryParse(xy[0]);
            final lat = double.tryParse(xy[1]);
            if (lat != null && lng != null) {
              pts.add(gcj02ToWgs84(LatLng(lat, lng)));
            }
          }
        }
      }
      return pts.isEmpty ? null : pts;
    } catch (_) {
      return null;
    }
  }

  /// OSRM 公共实例兜底（注意：公共 demo 只跑汽车 profile，仅作最后兜底）
  Future<List<LatLng>?> _osrmFallback(LatLng a, LatLng b) async {
    try {
      final path =
          '/route/v1/driving/${a.longitude},${a.latitude};${b.longitude},${b.latitude}';
      final uri = Uri.https('router.project-osrm.org', path, {
        'overview': 'full',
        'geometries': 'geojson',
      });
      final res = await _c.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final routes = (json['routes'] as List?) ?? const [];
      if (routes.isEmpty) return null;
      final coords = (routes.first['geometry']?['coordinates'] as List?) ?? const [];
      final pts = <LatLng>[];
      for (final c in coords) {
        if (c is List && c.length >= 2) {
          final lng = (c[0] as num).toDouble();
          final lat = (c[1] as num).toDouble();
          pts.add(LatLng(lat, lng));
        }
      }
      return pts.isEmpty ? null : pts;
    } catch (_) {
      return null;
    }
  }

  void dispose() => _c.close();
}

// ---------- GCJ-02 → WGS-84 坐标纠偏（高德 → 天地图/OSM） ----------

const double _a = 6378245.0;
const double _ee = 0.00669342162296594323;
const double _pi = math.pi;

bool _outOfChina(double lat, double lng) =>
    lng < 72.004 || lng > 137.8347 || lat < 0.8293 || lat > 55.8271;

double _transformLat(double x, double y) {
  var ret = -100.0 +
      2.0 * x +
      3.0 * y +
      0.2 * y * y +
      0.1 * x * y +
      0.2 * math.sqrt(x.abs());
  ret += (20.0 * math.sin(6.0 * x) + 20.0 * math.sin(2.0 * x)) * 2.0 / 3.0;
  ret += (20.0 * math.sin(y) + 40.0 * math.sin(y / 3.0)) * 2.0 / 3.0;
  ret += (160.0 * math.sin(y / 12.0) + 320 * math.sin(y * _pi / 30.0)) * 2.0 / 3.0;
  return ret;
}

double _transformLng(double x, double y) {
  var ret = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * math.sqrt(x.abs());
  ret += (20.0 * math.sin(x) + 20.0 * math.sin(2.0 * x)) * 2.0 / 3.0;
  ret += (20.0 * math.sin(y) + 40.0 * math.sin(y / 3.0)) * 2.0 / 3.0;
  ret += (150.0 * math.sin(x / 12.0) + 300.0 * math.sin(x / 30.0)) * 2.0 / 3.0;
  return ret;
}

LatLng gcj02ToWgs84(LatLng g) {
  if (_outOfChina(g.latitude, g.longitude)) return g;
  final dLat0 = _transformLat(g.longitude - 105.0, g.latitude - 35.0);
  final dLng0 = _transformLng(g.longitude - 105.0, g.latitude - 35.0);
  final radLat = g.latitude / 180.0 * _pi;
  var magic = math.sin(radLat);
  magic = 1 - _ee * magic * magic;
  final sqrtMagic = math.sqrt(magic);
  final dLat = (dLat0 * 180.0) / ((_a * (1 - _ee)) / (magic * sqrtMagic) * _pi);
  final dLng = (dLng0 * 180.0) / (_a / sqrtMagic * math.cos(radLat) * _pi);
  return LatLng(g.latitude - dLat, g.longitude - dLng);
}
