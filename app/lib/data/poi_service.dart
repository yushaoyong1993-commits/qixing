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

  void dispose() => _c.close();
}
