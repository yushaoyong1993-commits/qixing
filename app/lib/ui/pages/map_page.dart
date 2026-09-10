import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' show LatLng, Distance, LengthUnit;

import '../../data/providers.dart';
import '../../data/route_planner.dart';
import '../../data/route_repository.dart';
import '../../theme/app_theme.dart';
import '../widgets/amap_map_view.dart';

/// 地图 · 路线：**全高德**（WebView 高德 JS 地图底图 + 高德骑行规划，坐标全程 GCJ-02，零转换）
class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  final GlobalKey<AmapMapViewState> _mapKey = GlobalKey<AmapMapViewState>();
  List<double>? _myLoc; // GCJ-02 [lng, lat]
  bool _locating = false;

  Future<void> _locate() async {
    if (mounted) setState(() => _locating = true);
    void tip(String msg) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg, textAlign: TextAlign.center)),
        );
      }
    }

    try {
      final on = await Geolocator.isLocationServiceEnabled();
      if (!on) {
        tip('系统定位服务未开启');
        await Geolocator.openLocationSettings();
        return;
      }
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) {
        tip('未授予定位权限，请在系统设置中允许"跋涉"使用位置');
        await Geolocator.openAppSettings();
        return;
      }
      Position? pos = await Geolocator.getLastKnownPosition();
      pos ??= await _tryCurrent();
      if (pos == null) {
        tip('定位超时：请到室外/窗边，或允许"精确位置"');
        return;
      }
      // GPS(WGS84) → 高德(GCJ-02)，才能对齐高德底图
      final g = wgs84ToGcj02(LatLng(pos.latitude, pos.longitude));
      final loc = [g.longitude, g.latitude];
      if (!mounted) return;
      setState(() => _myLoc = loc);
      _mapKey.currentState?.moveTo(loc[0], loc[1]);
      _mapKey.currentState?.render(myLoc: loc);
      tip('已定位到当前位置');
    } catch (e) {
      tip('定位失败：$e');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<Position?> _tryCurrent() async {
    for (final acc in [LocationAccuracy.high, LocationAccuracy.medium]) {
      try {
        return await Geolocator.getCurrentPosition(
          locationSettings:
              LocationSettings(accuracy: acc, timeLimit: const Duration(seconds: 20)),
        );
      } catch (_) {}
    }
    return null;
  }

  void _onMapError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, textAlign: TextAlign.center)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final routes = ref.watch(routesProvider).valueOrNull ?? const <RouteModel>[];
    return Scaffold(
      appBar: AppBar(
        title: const Text('地图 · 路线'),
        actions: [
          IconButton(
            icon: _locating
                ? const SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.my_location),
            tooltip: '定位到当前位置',
            onPressed: _locating ? null : _locate,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '在地图上手绘路线',
            onPressed: () =>
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RouteEditorPage())),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 300,
            child: AmapMapView(
              key: _mapKey,
              initialZoom: 14,
              onReady: () => _mapKey.currentState?.render(myLoc: _myLoc),
              onTapLngLat: (lng, lat) {}, // 首页地图只看，不落点
              onError: _onMapError,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 8, left: 4),
            child: Text('高德地图 · 可拖动/双指缩放 · 右上角定位',
                style: TextStyle(fontSize: 11, color: AppTheme.txt3)),
          ),
          Expanded(
            child: routes.isEmpty
                ? const Center(
                    child: Text('还没有路线，点右上角 ＋ 在地图上手绘一条',
                        style: TextStyle(color: AppTheme.txt3)))
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: routes.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final r = routes[i];
                      return ListTile(
                        leading: _RouteThumb(points: r.points),
                        title: Text(r.name, style: const TextStyle(fontSize: 14)),
                        subtitle: Text(
                            '${r.distKm.toStringAsFixed(1)} km · ${r.points.length} 点'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppTheme.txt3),
                          onPressed: () => _confirmDelete(context, ref, r),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, RouteModel r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('删除路线？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('删除')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(routeRepositoryProvider).deleteRoute(r.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已删除路线')));
    }
  }
}

/// 路线缩略图：按经纬度 bbox 归一化画折线。
class _RouteThumb extends StatelessWidget {
  const _RouteThumb({required this.points});
  final List<List<double>> points; // [[lat, lng], ...]

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 42,
      decoration: BoxDecoration(color: AppTheme.card2, borderRadius: BorderRadius.circular(8)),
      child: CustomPaint(painter: _BoundsLinePainter(points, accent: AppTheme.accent)),
    );
  }
}

class _BoundsLinePainter extends CustomPainter {
  _BoundsLinePainter(this.points, {required this.accent});
  final List<List<double>> points;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    double minLat = points.first[0], maxLat = minLat;
    double minLon = points.first[1], maxLon = minLon;
    for (final p in points) {
      if (p[0] < minLat) minLat = p[0];
      if (p[0] > maxLat) maxLat = p[0];
      if (p[1] < minLon) minLon = p[1];
      if (p[1] > maxLon) maxLon = p[1];
    }
    final spanLat = (maxLat - minLat).abs() < 1e-9 ? 1.0 : (maxLat - minLat).abs();
    final spanLon = (maxLon - minLon).abs() < 1e-9 ? 1.0 : (maxLon - minLon).abs();
    const pad = 6.0;
    final availW = size.width - pad * 2, availH = size.height - pad * 2;
    final scale = (availW / spanLon) < (availH / spanLat) ? availW / spanLon : availH / spanLat;
    Offset toCanvas(double lat, double lon) => Offset(
          pad + (lon - minLon) * scale + (availW - spanLon * scale) / 2,
          pad + (maxLat - lat) * scale + (availH - spanLat * scale) / 2,
        );
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final o = toCanvas(points[i][0], points[i][1]);
      if (i == 0) {
        path.moveTo(o.dx, o.dy);
      } else {
        path.lineTo(o.dx, o.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _BoundsLinePainter old) => old.points != points;
}

/// 手绘路线（全高德）：点击地图 → 高德骑行规划 → 路径直接画在高德底图上（同坐标系，绝对对齐）。
class RouteEditorPage extends ConsumerStatefulWidget {
  const RouteEditorPage({super.key});

  @override
  ConsumerState<RouteEditorPage> createState() => _RouteEditorPageState();
}

class _RouteEditorPageState extends ConsumerState<RouteEditorPage> {
  final GlobalKey<AmapMapViewState> _mapKey = GlobalKey<AmapMapViewState>();
  final RoutePlanner _planner = RoutePlanner();
  final _name = TextEditingController(text: '我的路线');

  final List<List<double>> _anchors = []; // GCJ-02 [lng, lat]
  final List<List<double>> _path = []; // GCJ-02 路径点
  List<double>? _myLoc;
  bool _planning = false;
  double _distM = 0;

  @override
  void dispose() {
    _name.dispose();
    _planner.dispose();
    super.dispose();
  }

  void _render() =>
      _mapKey.currentState?.render(anchors: _anchors, path: _path, myLoc: _myLoc);

  Future<void> _onTap(double lng, double lat) async {
    if (_planning) return;
    final p = [lng, lat];
    if (_anchors.isEmpty) {
      setState(() {
        _anchors.add(p);
        _path.add(p);
      });
      _render();
      return;
    }
    final prev = _anchors.last;
    _anchors.add(p);
    setState(() => _planning = true);
    final r = await _planner.planRidingGcj(LatLng(prev[1], prev[0]), LatLng(lat, lng));
    if (!mounted) return;
    setState(() {
      if (r != null) {
        for (final q in r.points.skip(1)) {
          _path.add([q.longitude, q.latitude]);
        }
        _distM += r.distanceM;
      } else {
        _path.add(p); // 规划失败 → 直线
      }
      _planning = false;
    });
    _render();
    if (r == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('按道路规划失败（网络/服务/key 限制），本段用直线连接',
            textAlign: TextAlign.center),
      ));
    }
  }

  /// 撤销上一个锚点（连同该段路径）
  void _undo() {
    if (_anchors.isEmpty || _planning) return;
    setState(() {
      _anchors.removeLast();
      _path.clear();
      _distM = 0;
      for (var i = 0; i < _anchors.length; i++) {
        _path.add(_anchors[i]);
      }
    });
    _render();
  }

  Future<void> _goMyLocation() async {
    void tip(String m) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(m, textAlign: TextAlign.center)),
        );
      }
    }

    try {
      final on = await Geolocator.isLocationServiceEnabled();
      if (!on) {
        tip('系统定位服务未开启');
        await Geolocator.openLocationSettings();
        return;
      }
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) {
        tip('未授予定位权限');
        await Geolocator.openAppSettings();
        return;
      }
      Position? pos = await Geolocator.getLastKnownPosition();
      pos ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      final g = wgs84ToGcj02(LatLng(pos.latitude, pos.longitude));
      final loc = [g.longitude, g.latitude];
      if (!mounted) return;
      setState(() => _myLoc = loc);
      _mapKey.currentState?.moveTo(loc[0], loc[1]);
      _render();
      tip('已定位到当前位置');
    } catch (e) {
      tip('定位失败：$e');
    }
  }

  Future<void> _save() async {
    if (_path.length < 2) return;
    final pts = _path.map((p) => [p[1], p[0]]).toList(); // → [lat, lng]（GCJ-02）
    final km = _distM > 0 ? _distM / 1000 : _haversineKm(_path);
    await ref.read(routeRepositoryProvider).addRoute(
          name: _name.text.trim().isEmpty ? '我的路线' : _name.text.trim(),
          points: pts,
          distKm: km,
        );
    if (!mounted) return;
    Navigator.pop(context);
  }

  double _haversineKm(List<List<double>> pts) {
    var m = 0.0;
    const d = Distance();
    for (var i = 1; i < pts.length; i++) {
      m += d.as(LengthUnit.Meter,
          LatLng(pts[i - 1][1], pts[i - 1][0]), LatLng(pts[i][1], pts[i][0]));
    }
    return m / 1000;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('手绘路线（高德地图）'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: '定位到当前位置',
            onPressed: _goMyLocation,
          ),
          TextButton(onPressed: _save, child: const Text('保存')),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: '路线名称'),
            ),
          ),
          Expanded(
            child: AmapMapView(
              key: _mapKey,
              initialZoom: 15,
              onTapLngLat: _onTap,
              onReady: _render,
              onError: (msg) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(msg, textAlign: TextAlign.center)),
                );
              },
            ),
          ),
          if (_planning)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('正在按高德骑行路线规划…',
                  style: TextStyle(fontSize: 12, color: AppTheme.accentInk)),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _anchors.isEmpty || _planning ? null : _undo,
                      icon: const Icon(Icons.undo, size: 18),
                      label: const Text('撤销上一点'),
                    ),
                    TextButton(
                        onPressed: () => setState(() {
                              _anchors.clear();
                              _path.clear();
                              _distM = 0;
                            }),
                        child: const Text('清空')),
                  ],
                ),
                Text(
                    '锚点 ${_anchors.length} · ${(_distM > 0 ? _distM / 1000 : _haversineKm(_path)).toStringAsFixed(2)} km',
                    style: const TextStyle(fontSize: 12, color: AppTheme.txt3)),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text('点两下：A→B 自动按高德骑行路线生成带拐弯的路径（与高德底图同坐标系，绝对对齐）',
                style: TextStyle(fontSize: 11.5, color: AppTheme.txt3)),
          ),
        ],
      ),
    );
  }
}
