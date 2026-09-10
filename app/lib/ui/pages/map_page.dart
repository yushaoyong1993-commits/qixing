import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' show LatLng, Distance, LengthUnit;

import '../../data/providers.dart';
import '../../data/route_planner.dart';
import '../../data/route_repository.dart';
import '../../theme/app_theme.dart';
import '../widgets/amap_map_view.dart';

/// 定位（GPS WGS84 → 高德 GCJ-02），供地图页与路线页共用。
/// 返回 GCJ-02 的 [lng, lat]；失败返回 null（silent=true 时不弹提示）。
Future<List<double>?> acquireGcjLocation(BuildContext context, {bool quiet = false}) async {
  void tip(String msg) {
    if (quiet) return; // 自动定位静默，避免打扰
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, textAlign: TextAlign.center)),
    );
  }

  try {
    final on = await Geolocator.isLocationServiceEnabled();
    if (!on) {
      tip('系统定位服务未开启');
      await Geolocator.openLocationSettings();
      return null;
    }
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
    if (p == LocationPermission.denied || p == LocationPermission.deniedForever) {
      tip('未授予定位权限，请在系统设置中允许"跋涉"使用位置');
      await Geolocator.openAppSettings();
      return null;
    }
    // 优先用"上次已知位置"（30 分钟内有效）→ 秒级定位
    Position? pos = await Geolocator.getLastKnownPosition();
    if (pos != null &&
        DateTime.now().difference(pos.timestamp).inMinutes > 30) {
      pos = null; // 太旧，视为无效
    }
    if (pos == null) {
      for (final acc in [LocationAccuracy.high, LocationAccuracy.medium]) {
        try {
          pos = await Geolocator.getCurrentPosition(
            locationSettings:
                LocationSettings(accuracy: acc, timeLimit: const Duration(seconds: 20)),
          );
          break;
        } catch (_) {}
      }
    }
    if (pos == null) {
      tip('定位超时：请到室外/窗边，或允许"精确位置"');
      return null;
    }
    final g = wgs84ToGcj02(LatLng(pos.latitude, pos.longitude));
    return [g.longitude, g.latitude];
  } catch (e) {
    tip('定位失败：$e');
    return null;
  }
}

/// 地图 · 路线：全高德（WebView 高德 JS 地图 + 高德骑行规划，坐标全程 GCJ-02）
class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  final GlobalKey<AmapMapViewState> _mapKey = GlobalKey<AmapMapViewState>();
  List<double>? _myLoc;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    // ① 进入地图页自动定位一次
    WidgetsBinding.instance.addPostFrameCallback((_) => _locate(silent: true));
  }

  int _autoTries = 0;

  Future<void> _locate({bool silent = false}) async {
    if (mounted) setState(() => _locating = true);
    final loc = await acquireGcjLocation(context, quiet: silent);
    if (!mounted) return;
    setState(() => _locating = false);
    if (loc == null) {
      // 自动定位失败 → 稍后自动重试一次（首次权限弹窗/取点超时常导致）
      if (silent && _autoTries < 2) {
        _autoTries++;
        Future.delayed(const Duration(seconds: 6), () {
          if (mounted && _myLoc == null) _locate(silent: true);
        });
      } else if (silent) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('自动定位未成功，可点右上角图标手动定位', textAlign: TextAlign.center),
        ));
      }
      return;
    }
    setState(() => _myLoc = loc);
    _mapKey.currentState?.moveTo(loc[0], loc[1]);
    _mapKey.currentState?.render(myLoc: loc);
    if (!silent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已定位到当前位置', textAlign: TextAlign.center)),
      );
    }
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
            onPressed: _locating ? null : () => _locate(),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '定制路线',
            onPressed: () => _openEditor(),
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
              onReady: () {
                // WebView 就绪后再应用定位与刷新，避免瓦片因尺寸/时序问题不显示
                _mapKey.currentState?.refresh();
                _mapKey.currentState?.render(myLoc: _myLoc);
                final l = _myLoc;
                if (l != null) _mapKey.currentState?.moveTo(l[0], l[1]);
              },
              onTapLngLat: (lng, lat) {},
              onError: (msg) {
                if (!mounted) return;
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(msg, textAlign: TextAlign.center)));
              },
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
                    child: Text('还没有路线，点右上角 ＋ 定制一条',
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
                        subtitle: Text('${r.distKm.toStringAsFixed(1)} km'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppTheme.txt3),
                          onPressed: () => _confirmDelete(context, ref, r),
                        ),
                        // ⑤ 点击已保存路线 → 查看/编辑（改名、继续绘制）
                        onTap: () => _openEditor(route: r),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// 打开定制/编辑路线页；返回后主动刷新地图（Android WebView 被覆盖后需 resize 才会重绘）
  Future<void> _openEditor({RouteModel? route}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RouteEditorPage(editRoute: route)),
    );
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    _mapKey.currentState?.refresh();
    _mapKey.currentState?.render(myLoc: _myLoc);
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

/// 定制/编辑路线（全高德）：点按地图 → 高德骑行规划 → 路径画在高德底图上（同坐标系，绝对对齐）。
/// [editRoute] 非空时为"编辑已保存路线"（可改名、可继续在其后追加）。
class RouteEditorPage extends ConsumerStatefulWidget {
  const RouteEditorPage({super.key, this.editRoute});

  final RouteModel? editRoute;

  @override
  ConsumerState<RouteEditorPage> createState() => _RouteEditorPageState();
}

class _RouteEditorPageState extends ConsumerState<RouteEditorPage> {
  final GlobalKey<AmapMapViewState> _mapKey = GlobalKey<AmapMapViewState>();
  final RoutePlanner _planner = RoutePlanner();
  late final TextEditingController _name;

  /// 分段路径：每段为 GCJ-02 的 [[lng, lat], ...]，段首尾相接。
  final List<List<List<double>>> _segs = [];
  List<double>? _myLoc;
  bool _planning = false;
  double _distM = 0;
  /// 编辑已有路线时，原始段数量（不可被"撤销"删掉）
  int _baseSegs = 0;

  bool get _isEdit => widget.editRoute != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.editRoute?.name ?? '我的路线');
    final r = widget.editRoute;
    if (r != null && r.points.length >= 2) {
      // 已保存路线作为基础段：整条 path（GCJ-02），后续点击从末端继续规划
      _segs.add([for (final p in r.points) [p[1], p[0]]]);
      _baseSegs = 1;
      _distM = r.distKm * 1000;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _render();
      // ① 进入页面自动定位一次
      await _locate(silent: true);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _planner.dispose();
    super.dispose();
  }

  /// 由分段重建完整路径
  List<List<double>> _buildPath() {
    if (_segs.isEmpty) return [];
    final out = <List<double>>[..._segs.first];
    for (final seg in _segs.skip(1)) {
      out.addAll(seg.skip(1));
    }
    return out;
  }

  /// 锚点 = 每段起点 + 最后一段终点
  List<List<double>> _buildAnchors() {
    if (_segs.isEmpty) return [];
    final a = <List<double>>[
      for (final seg in _segs) seg.first,
    ];
    a.add(_segs.last.last);
    return a;
  }

  void _render() => _mapKey.currentState?.render(
        anchors: _buildAnchors(),
        path: _buildPath(),
        myLoc: _myLoc,
      );

  /// 中心定位到当前路线
  void _centerOnRoute() {
    final p = _buildPath();
    if (p.isEmpty) return;
    double minLat = p.first[1], maxLat = minLat, minLon = p.first[0], maxLon = minLon;
    for (final q in p) {
      if (q[1] < minLat) minLat = q[1];
      if (q[1] > maxLat) maxLat = q[1];
      if (q[0] < minLon) minLon = q[0];
      if (q[0] > maxLon) maxLon = q[0];
    }
    _mapKey.currentState?.moveTo((minLon + maxLon) / 2, (minLat + maxLat) / 2, zoom: 14);
  }

  int _autoTries = 0;

  Future<void> _locate({bool silent = false}) async {
    final loc = await acquireGcjLocation(context, quiet: silent);
    if (!mounted) return;
    if (loc == null) {
      if (silent && _autoTries < 2) {
        _autoTries++;
        Future.delayed(const Duration(seconds: 6), () {
          if (mounted && _myLoc == null) _locate(silent: true);
        });
      }
      return;
    }
    setState(() => _myLoc = loc);
    _mapKey.currentState?.moveTo(loc[0], loc[1]);
    _render();
    if (!silent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已定位到当前位置', textAlign: TextAlign.center)),
      );
    }
  }

  Future<void> _onTap(double lng, double lat) async {
    if (_planning) return;
    final p = [lng, lat];
    // 首个点（新建时）
    if (_segs.isEmpty) {
      setState(() => _segs.add([p]));
      _render();
      return;
    }
    final prev = _segs.last.last;
    setState(() => _planning = true);
    final r = await _planner.planRidingGcj(LatLng(prev[1], prev[0]), LatLng(lat, lng));
    if (!mounted) return;
    setState(() {
      if (r != null) {
        final seg = <List<double>>[prev];
        for (final q in r.points.skip(1)) {
          seg.add([q.longitude, q.latitude]);
        }
        _segs.add(seg);
        _distM += r.distanceM;
      } else {
        _segs.add([prev, p]); // 规划失败 → 直线
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

  /// ③ 撤销：只回退最后一段（保留已完成的道路轨迹），编辑模式下不动原始路径
  void _undo() {
    if (_planning || _segs.length <= _baseSegs) return;
    setState(() {
      _segs.removeLast();
      _distM = _recalcDist();
    });
    _render();
  }

  /// ④ 清空：编辑模式下清掉新增段（保留原始），新建模式全清
  void _clear() {
    if (_planning) return;
    setState(() {
      if (_baseSegs > 0) {
        while (_segs.length > _baseSegs) {
          _segs.removeLast();
        }
        _distM = _recalcDist();
      } else {
        _segs.clear();
        _distM = 0;
      }
    });
    _render();
  }

  double _recalcDist() {
    var m = 0.0;
    const d = Distance();
    for (final seg in _segs) {
      for (var i = 1; i < seg.length; i++) {
        m += d.as(LengthUnit.Meter,
            LatLng(seg[i - 1][1], seg[i - 1][0]), LatLng(seg[i][1], seg[i][0]));
      }
    }
    return m;
  }

  Future<void> _save() async {
    final path = _buildPath();
    if (path.length < 2) return;
    final pts = path.map((p) => [p[1], p[0]]).toList(); // → [lat, lng]（GCJ-02）
    final km = (_distM > 0 ? _distM : _recalcDist()) / 1000;
    final repo = ref.read(routeRepositoryProvider);
    final name = _name.text.trim().isEmpty ? '我的路线' : _name.text.trim();
    if (_isEdit) {
      await repo.updateRoute(id: widget.editRoute!.id, name: name, points: pts, distKm: km);
    } else {
      await repo.addRoute(name: name, points: pts, distKm: km);
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final path = _buildPath();
    final km = (_distM > 0 ? _distM : _recalcDist()) / 1000;
    return Scaffold(
      appBar: AppBar(
        // ② 标题：定制路线 / 编辑路线
        title: Text(_isEdit ? '编辑路线' : '定制路线'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: '定位到当前位置',
            onPressed: () => _locate(),
          ),
          if (path.length > 1)
            IconButton(
              icon: const Icon(Icons.center_focus_strong),
              tooltip: '居中显示整条路线',
              onPressed: _centerOnRoute,
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
              onReady: () {
                _render();
                _centerOnRoute();
              },
              onError: (msg) {
                if (!mounted) return;
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(msg, textAlign: TextAlign.center)));
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
                      onPressed: _segs.length <= _baseSegs || _planning ? null : _undo,
                      icon: const Icon(Icons.undo, size: 18),
                      label: const Text('撤销上一点'),
                    ),
                    TextButton(
                      onPressed: (_segs.length <= _baseSegs && _baseSegs > 0) || _planning
                          ? null
                          : _clear,
                      child: const Text('清空'),
                    ),
                  ],
                ),
                Text('${km.toStringAsFixed(2)} km',
                    style: const TextStyle(fontSize: 12, color: AppTheme.txt3)),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text('点两下：A→B 自动按高德骑行路线生成带拐弯的路径（与底图同坐标系）',
                style: TextStyle(fontSize: 11.5, color: AppTheme.txt3)),
          ),
        ],
      ),
    );
  }
}
