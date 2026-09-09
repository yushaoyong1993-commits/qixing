import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/activity_repository.dart';
import '../../data/providers.dart';
import '../../domain/stats/aggregate.dart' as k;
import '../../theme/app_theme.dart';

/// 活动详情（M1）：指标 + 真实轨迹折线（读 track_points）+ 删除。
class ActivityDetailPage extends ConsumerWidget {
  const ActivityDetailPage({super.key, required this.rideId});

  final int rideId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rides = ref.watch(ridesProvider).valueOrNull ?? const <k.RideLite>[];
    k.RideLite? r;
    for (final x in rides) {
      if (x.id == rideId) r = x;
    }
    if (r == null) {
      return const Scaffold(
        body: Center(child: Text('活动不存在', style: TextStyle(color: AppTheme.txt3))),
      );
    }
    final speed = r.durationMin > 0 ? (r.distanceKm / (r.durationMin / 60)) : 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('骑行详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref, r.id),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _item('日期时间',
              '${r.startAt.year}-${r.startAt.month}-${r.startAt.day} ${r.startAt.hour}:${r.startAt.minute.toString().padLeft(2, '0')}'),
          _item('距离', '${r.distanceKm.toStringAsFixed(1)} km'),
          _item('时长(移动)', _fmtSec(r.durationMin * 60)),
          _item('均速', '${speed.toStringAsFixed(1)} km/h'),
          _item('累计爬升', '${r.elevGainM.round()} m'),
          const SizedBox(height: 12),
          _trackSection(context, ref, r.id),
        ],
      ),
    );
  }

  Widget _trackSection(BuildContext context, WidgetRef ref, int id) {
    return FutureBuilder<List<SimpleTrack>>(
      future: ref.read(activityRepositoryProvider).trackPointsFor(id),
      builder: (context, snap) {
        final pts = snap.data ?? const <SimpleTrack>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('轨迹', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (pts.isEmpty)
              const Text('暂无轨迹点（记录时未采集到 GPS 数据）',
                  style: TextStyle(fontSize: 12, color: AppTheme.txt3))
            else ...[
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.card2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.line),
                ),
                child: CustomPaint(painter: _TrackPathPainter(pts, accent: AppTheme.accent)),
              ),
              const SizedBox(height: 4),
              Text('真实轨迹 · ${pts.length} 点', style: const TextStyle(fontSize: 11.5, color: AppTheme.txt3)),
            ],
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('删除该活动？'),
        content: const Text('删除后不可恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('删除')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(activityRepositoryProvider).deleteRide(id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已删除 · 列表已刷新')));
      Navigator.pop(context);
    }
  }

  Widget _item(String label, String value, {String? sub}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(color: AppTheme.txt2))),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (sub != null)
                  Text(sub, style: const TextStyle(fontSize: 11, color: AppTheme.txt3)),
              ],
            ),
          ],
        ),
      );

  String _fmtSec(double seconds) {
    final total = seconds.round();
    final h = total ~/ 3600, m = (total % 3600) ~/ 60, s = total % 60;
    String p(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '${p(h)}:${p(m)}:${p(s)}' : '${p(m)}:${p(s)}';
  }
}

/// 把真实经纬度轨迹点按 bbox 归一化画到画布（保持比例）。
class _TrackPathPainter extends CustomPainter {
  _TrackPathPainter(this.points, {required this.accent});
  final List<SimpleTrack> points;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    double minLat = points.first.lat, maxLat = minLat;
    double minLon = points.first.lon, maxLon = minLon;
    for (final p in points) {
      if (p.lat < minLat) minLat = p.lat;
      if (p.lat > maxLat) maxLat = p.lat;
      if (p.lon < minLon) minLon = p.lon;
      if (p.lon > maxLon) maxLon = p.lon;
    }
    final spanLat = (maxLat - minLat).abs() < 1e-9 ? 1.0 : (maxLat - minLat).abs();
    final spanLon = (maxLon - minLon).abs() < 1e-9 ? 1.0 : (maxLon - minLon).abs();
    const pad = 12.0;
    final availW = size.width - pad * 2, availH = size.height - pad * 2;
    final scale = (availW / spanLon) < (availH / spanLat) ? availW / spanLon : availH / spanLat;

    Offset toCanvas(double lat, double lon) => Offset(
          pad + (lon - minLon) * scale + (availW - spanLon * scale) / 2,
          pad + (maxLat - lat) * scale + (availH - spanLat * scale) / 2,
        );

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final o = toCanvas(points[i].lat, points[i].lon);
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
        ..strokeWidth = 2.4
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(toCanvas(points.first.lat, points.first.lon), 4,
        Paint()..color = Colors.white);
    canvas.drawCircle(toCanvas(points.last.lat, points.last.lon), 4,
        Paint()..color = accent);
  }

  @override
  bool shouldRepaint(covariant _TrackPathPainter old) => old.points != points;
}
