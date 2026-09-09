
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../data/route_repository.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../../theme/app_theme.dart';

/// 地图 · 路线（M1 纯数据版）：我的路线列表 + 新建手绘 + 删除。
/// 说明：真实地图渲染依赖地图引擎（M1 内 POC），本期先用画布手绘并用归一化点存库，重绘/渲染已解耦（MapEngine 抽象见 domain/maps）。
class MapPage extends ConsumerWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routes = ref.watch(routesProvider).valueOrNull ?? const <RouteModel>[];
    return Scaffold(
      appBar: AppBar(
        title: const Text('地图 · 路线'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '新建手绘路线',
            onPressed: () =>
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RouteEditorPage())),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 240,
            child: FlutterMap(
              options: const MapOptions(initialCenter: LatLng(39.908, 116.397), initialZoom: 12),
              children: [
                TileLayer(
                  urlTemplate: 'https://webrd0{s}.is.autonavi.com/appmaptile?style=7&x={x}&y={y}&z={z}',
                  subdomains: const ['1', '2', '3', '4'],
                  userAgentPackageName: 'com.basho.basho',
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 8, left: 4),
            child: Text('高德路网瓦片 · 可拖动缩放',
                style: TextStyle(fontSize: 11, color: AppTheme.txt3)),
          ),
          Expanded(
            child: routes.isEmpty
                ? const Center(child: Text('还没有路线，点右上角 ＋ 手绘一条',
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

/// 路线缩略图（归一化点 → 小画布折线）。
class _RouteThumb extends StatelessWidget {
  const _RouteThumb({required this.points});
  final List<List<double>> points;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 42,
      decoration: BoxDecoration(
        color: AppTheme.card2,
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomPaint(painter: _LinePainter(points, accent: AppTheme.accent)),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.points, {required this.accent});
  final List<List<double>> points;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final paint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final p = Offset(points[i][0] / 100 * size.width, points[i][1] / 100 * size.height);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(path, paint);
    canvas.drawCircle(
        Offset(points.first[0] / 100 * size.width, points.first[1] / 100 * size.height), 3,
        Paint()..color = Colors.white);
    canvas.drawCircle(
        Offset(points.last[0] / 100 * size.width, points.last[1] / 100 * size.height), 3,
        Paint()..color = accent);
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) => old.points != points;
}

/// 手绘路线编辑器：点击画布打点，折线预览，命名保存。
class RouteEditorPage extends ConsumerStatefulWidget {
  const RouteEditorPage({super.key});

  @override
  ConsumerState<RouteEditorPage> createState() => _RouteEditorPageState();
}

class _RouteEditorPageState extends ConsumerState<RouteEditorPage> {
  final List<Offset> _raw = []; // 0..1 归一化坐标
  final _name = TextEditingController(text: '我的路线');

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  double _distKm() {
    var d = 0.0;
    for (var i = 1; i < _raw.length; i++) {
      d += (_raw[i] - _raw[i - 1]).distance;
    }
    return d * 8.0; // 归一化单位 → 公里（演示换算：满幅 ≈ 8 km）
  }

  Future<void> _save() async {
    if (_raw.length < 2) return;
    final pts = _raw.map((o) => [o.dx * 100, o.dy * 100]).toList();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('手绘路线'),
        actions: [
          TextButton(onPressed: _save, child: const Text('保存')),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: '路线名称'),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) => GestureDetector(
                  onTapDown: (d) => setState(() {
                    _raw.add(Offset(
                      (d.localPosition.dx / box.maxWidth).clamp(0.0, 1.0),
                      (d.localPosition.dy / box.maxHeight).clamp(0.0, 1.0),
                    ));
                  }),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.card2,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CustomPaint(
                      painter: _LinePainter(
                        _raw.map((o) => [o.dx * 100, o.dy * 100]).toList(),
                        accent: AppTheme.accent,
                      ),
                      child: const Align(
                        alignment: Alignment.center,
                        child: Text('点按地图打点，连成路线', style: TextStyle(color: AppTheme.txt3)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => setState(_raw.clear),
                  child: const Text('清空'),
                ),
                Text('${_raw.length} 点 · 约 ${_distKm().toStringAsFixed(1)} km',
                    style: const TextStyle(fontSize: 12, color: AppTheme.txt3)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
