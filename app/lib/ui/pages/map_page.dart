import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' show LatLng, Distance, LengthUnit;

import '../../data/providers.dart';
import '../../data/route_repository.dart';
import '../../theme/app_theme.dart';
import '../widgets/map_tiles.dart';

/// 地图 · 路线：真实瓦片地图（天地图/Esri/OSM/高德可切换）+ 实时定位 + 我的路线。
class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  static const _fallbackCenter = LatLng(39.908, 116.397); // 无定位时的默认视野
  final MapController _mapController = MapController();
  LatLng? _myLoc;
  bool _mapReady = false;
  bool _locating = false;
  LatLng? _pendingMove;
  int _tileErrors = 0;
  bool _fellBack = false;

  void _onTileError() {
    _tileErrors++;
    if (_fellBack) return;
    if (_tileErrors < 3) return;
    _fellBack = true;
    if (ref.read(mapTileSourceProvider) == MapTileSource.tianditu) {
      ref.read(mapTileSourceProvider.notifier).state = MapTileSource.esri;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('天地图瓦片加载失败（key 类型/权限），已自动切换 Esri',
              textAlign: TextAlign.center),
        ));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _locate(silent: true));
  }

  void _moveTo(LatLng loc) {
    if (_mapReady) {
      try {
        _mapController.move(loc, 16);
      } catch (_) {}
    } else {
      _pendingMove = loc;
    }
  }

  Future<void> _locate({bool silent = false}) async {
    if (mounted) setState(() => _locating = true);
    void tip(String msg) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg, textAlign: TextAlign.center)),
        );
      }
    }

    try {
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      if (!serviceOn) {
        tip('系统定位服务未开启，请在设置中打开"位置信息"');
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
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      final loc = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() => _myLoc = loc);
      _moveTo(loc);
      if (!silent) tip('已定位到当前位置');
    } catch (e) {
      tip('定位失败：$e');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final routes = ref.watch(routesProvider).valueOrNull ?? const <RouteModel>[];
    final src = ref.watch(mapTileSourceProvider);
    final needToken = src == MapTileSource.tianditu && kTiandituToken.trim().isEmpty;
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
            onPressed: _locating ? null : () => _locate(),
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                for (final s in MapTileSource.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(tileSourceLabel(s), style: const TextStyle(fontSize: 12)),
                      selected: src == s,
                      onSelected: (_) => ref.read(mapTileSourceProvider.notifier).state = s,
                    ),
                  ),
              ],
            ),
          ),
          if (needToken)
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text('未配置天地图 tk，暂用 Esri 显示',
                  style: TextStyle(fontSize: 11, color: AppTheme.warn)),
            ),
          SizedBox(
            height: 230,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _fallbackCenter,
                initialZoom: 12,
                onMapReady: () {
                  _mapReady = true;
                  final p = _pendingMove;
                  if (p != null) {
                    try {
                      _mapController.move(p, 16);
                    } catch (_) {}
                  }
                },
              ),
              children: [
                ...tileLayersFor(src, onError: _onTileError),
                if (_myLoc != null)
                  MarkerLayer(markers: [
                    Marker(
                      point: _myLoc!,
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF2F80ED),
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                  ]),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 8, left: 4),
            child: Text('可拖动/双指缩放 · 右上角图标定位到当前位置',
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

/// 手绘路线：在真实地图上点按打点，可定位到当前位置，保存真实经纬度。
class RouteEditorPage extends ConsumerStatefulWidget {
  const RouteEditorPage({super.key});

  @override
  ConsumerState<RouteEditorPage> createState() => _RouteEditorPageState();
}

class _RouteEditorPageState extends ConsumerState<RouteEditorPage> {
  final List<LatLng> _pts = [];
  final _name = TextEditingController(text: '我的路线');
  final MapController _mapController = MapController();
  static const _fallbackCenter = LatLng(39.908, 116.397);
  LatLng? _myLoc;
  bool _mapReady = false;
  LatLng? _pendingMove;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  double _distKm() {
    var m = 0.0;
    const d = Distance();
    for (var i = 1; i < _pts.length; i++) {
      m += d.as(LengthUnit.Meter, _pts[i - 1], _pts[i]);
    }
    return m / 1000;
  }

  Future<void> _goMyLocation() async {
    void tip(String msg) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg, textAlign: TextAlign.center)),
        );
      }
    }

    try {
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      if (!serviceOn) {
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
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      final loc = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() => _myLoc = loc);
      if (_mapReady) {
        try {
          _mapController.move(loc, 16);
        } catch (_) {}
      } else {
        _pendingMove = loc;
      }
      tip('已定位到当前位置');
    } catch (e) {
      tip('定位失败：$e');
    }
  }

  Future<void> _save() async {
    if (_pts.length < 2) return;
    final pts = _pts.map((p) => [p.latitude, p.longitude]).toList();
    await ref.read(routeRepositoryProvider).addRoute(
          name: _name.text.trim().isEmpty ? '我的路线' : _name.text.trim(),
          points: pts,
          distKm: _distKm(),
        );
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final src = ref.watch(mapTileSourceProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('手绘路线（真地图）'),
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
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _fallbackCenter,
                initialZoom: 14,
                onTap: (tapPos, latlng) => setState(() => _pts.add(latlng)),
                onMapReady: () {
                  _mapReady = true;
                  final p = _pendingMove;
                  if (p != null) {
                    try {
                      _mapController.move(p, 16);
                    } catch (_) {}
                  }
                },
              ),
              children: [
                ...tileLayersFor(src),
                if (_myLoc != null)
                  MarkerLayer(markers: [
                    Marker(
                      point: _myLoc!,
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF2F80ED),
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                  ]),
                if (_pts.length > 1)
                  PolylineLayer(polylines: [
                    Polyline(points: _pts, strokeWidth: 4, color: AppTheme.accent),
                  ]),
                MarkerLayer(markers: [
                  for (var i = 0; i < _pts.length; i++)
                    Marker(
                      point: _pts[i],
                      width: 18,
                      height: 18,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == 0 ? Colors.white : AppTheme.accent,
                          border: Border.all(color: AppTheme.accent, width: 2),
                        ),
                      ),
                    ),
                ]),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: () => setState(_pts.clear), child: const Text('清空')),
                Text('${_pts.length} 点 · 约 ${_distKm().toStringAsFixed(2)} km',
                    style: const TextStyle(fontSize: 12, color: AppTheme.txt3)),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text('在地图上点按打点，连成路线后保存 · 右上角可定位',
                style: TextStyle(fontSize: 11.5, color: AppTheme.txt3)),
          ),
        ],
      ),
    );
  }
}
