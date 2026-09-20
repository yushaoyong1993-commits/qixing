import 'dart:convert';

import 'package:http/http.dart' as http;

import 'route_planner.dart' show kAmapWebServiceKey;

/// 高德输入提示返回的一个地点候选（坐标已为 GCJ-02，与原生地图一致）
class PoiTip {
  const PoiTip({
    required this.name,
    required this.district,
    required this.lng,
    required this.lat,
  });

  final String name;
  final String district;
  final double lng;
  final double lat;

  String get subtitle => district.isEmpty ? '地图位置' : district;
}

/// 地点搜索（高德 Web 服务「输入提示」）
///
/// 使用 Web 服务 key（与骑行路线规划同一个 key），免费额度足够个人使用。
class PoiService {
  PoiService({http.Client? client}) : _c = client ?? http.Client();

  final http.Client _c;

  /// 关键字输入提示；返回结果已过滤掉没有坐标的条目
  Future<List<PoiTip>> inputTips(String keywords, {String city = ''}) async {
    final kw = keywords.trim();
    if (kw.isEmpty) return const [];
    try {
      final uri = Uri.https('restapi.amap.com', '/v3/assistant/inputtips', {
        'keywords': kw,
        if (city.isNotEmpty) 'city': city,
        'datatype': 'all',
        'key': kAmapWebServiceKey,
      });
      final res = await _c.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return const [];
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final tips = (json['tips'] as List?) ?? const [];
      final out = <PoiTip>[];
      for (final t in tips) {
        if (t is! Map) continue;
        final loc = t['location'];
        if (loc is! String || !loc.contains(',')) continue; // 无坐标（如公交线路）
        final xy = loc.split(',');
        final lng = double.tryParse(xy[0]);
        final lat = double.tryParse(xy[1]);
        if (lng == null || lat == null) continue;
        final name = '${t['name'] ?? ''}'.trim();
        if (name.isEmpty) continue;
        out.add(PoiTip(
          name: name,
          district: '${t['district'] ?? ''}'.trim(),
          lng: lng,
          lat: lat,
        ));
      }
      return out;
    } catch (_) {
      return const [];
    }
  }


  /// 周边搜索（骑行途中找便利店/卫生间/补给点等）
  Future<List<PoiPlace>> around({
    required double lng,
    required double lat,
    String keywords = '',
    int radius = 3000,
    int offset = 25,
  }) async {
    try {
      final uri = Uri.https('restapi.amap.com', '/v3/place/around', {
        'location': '$lng,$lat',
        'keywords': keywords,
        'radius': '$radius',
        'offset': '$offset',
        'sortrule': 'distance',
        'key': kAmapWebServiceKey,
      });
      return _parsePlaces(await _get(uri));
    } catch (_) {
      return const [];
    }
  }

  /// 关键字搜索（全城范围）
  Future<List<PoiPlace>> text(String keywords, {String city = '', int offset = 25}) async {
    final kw = keywords.trim();
    if (kw.isEmpty) return const [];
    try {
      final uri = Uri.https('restapi.amap.com', '/v3/place/text', {
        'keywords': kw,
        if (city.isNotEmpty) 'city': city,
        'offset': '$offset',
        'key': kAmapWebServiceKey,
      });
      return _parsePlaces(await _get(uri));
    } catch (_) {
      return const [];
    }
  }

  Future<String> _get(Uri uri) async {
    final res = await _c.get(uri).timeout(const Duration(seconds: 6));
    if (res.statusCode != 200) return '';
    return res.body;
  }

  List<PoiPlace> _parsePlaces(String body) {
    if (body.isEmpty) return const [];
    final json = jsonDecode(body) as Map<String, dynamic>;
    final pois = (json['pois'] as List?) ?? const [];
    final out = <PoiPlace>[];
    for (final p in pois) {
      if (p is! Map) continue;
      final loc = p['location'];
      if (loc is! String || !loc.contains(',')) continue;
      final xy = loc.split(',');
      final lng = double.tryParse(xy[0]);
      final lat = double.tryParse(xy[1]);
      if (lng == null || lat == null) continue;
      final name = '${p['name'] ?? ''}'.trim();
      if (name.isEmpty) continue;
      out.add(PoiPlace(
        name: name,
        address: '${p['address'] ?? ''}'.trim() == '[]' ? '' : '${p['address'] ?? ''}'.trim(),
        district: '${p['adname'] ?? ''}'.trim(),
        lng: lng,
        lat: lat,
        distanceM: int.tryParse('${p['distance'] ?? 0}') ?? 0,
        typeName: '${p['type'] ?? ''}'.split(';').last,
      ));
    }
    return out;
  }

  void dispose() => _c.close();
}

/// 周边/关键字搜索返回的一个地点（坐标 GCJ-02）
class PoiPlace {
  const PoiPlace({
    required this.name,
    required this.address,
    required this.district,
    required this.lng,
    required this.lat,
    required this.distanceM,
    required this.typeName,
  });

  final String name;
  final String address;
  final String district;
  final double lng;
  final double lat;

  /// 距离（米）；关键字搜索时为 0
  final int distanceM;
  final String typeName;

  String get distanceText => distanceM <= 0
      ? ''
      : distanceM < 1000
          ? '${distanceM}m'
          : '${(distanceM / 1000).toStringAsFixed(1)}km';

  String get subtitle {
    final parts = <String>[
      if (distanceText.isNotEmpty) distanceText,
      if (address.isNotEmpty) address else district,
    ];
    return parts.join(' · ');
  }
}

/// 沿途/周边常用类别（用关键字检索，兼容性最好）
class PoiCategory {
  const PoiCategory(this.label, this.keyword);
  final String label;
  final String keyword;

  static const List<PoiCategory> all = [
    PoiCategory('便利店', '便利店'),
    PoiCategory('超市', '超市'),
    PoiCategory('卫生间', '公共厕所'),
    PoiCategory('餐饮', '餐厅'),
    PoiCategory('药店', '药店'),
    PoiCategory('医院', '医院'),
    PoiCategory('修车', '自行车维修'),
    PoiCategory('充电站', '充电站'),
  ];
}
