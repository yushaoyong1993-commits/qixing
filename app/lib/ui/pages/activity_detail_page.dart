import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../../data/activity_repository.dart';
import '../../data/providers.dart';
import '../../data/route_planner.dart';
import '../../domain/stats/aggregate.dart' as k;
import '../../theme/app_theme.dart';
import '../widgets/amap_map_view.dart';

/// 活动详情：指标 + **真实轨迹（高德地图显示）** + 删除。
class ActivityDetailPage extends ConsumerStatefulWidget {
  const ActivityDetailPage({super.key, required this.rideId});

  final int rideId;

  @override
  ConsumerState<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends ConsumerState<ActivityDetailPage> {
  final GlobalKey<AmapMapViewState> _mapKey = GlobalKey<AmapMapViewState>();
  List<SimpleTrack> _tracks = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pts = await ref.read(activityRepositoryProvider).trackPointsFor(widget.rideId);
    if (!mounted) return;
    setState(() {
      _tracks = pts;
      _loading = false;
    });
  }

  /// 轨迹（WGS84 GPS）→ GCJ-02 才能对齐高德底图；抽稀到 ≤400 点
  List<List<double>> _gcjPath() {
    final pts = _tracks;
    final stride = pts.length > 400 ? (pts.length / 400).ceil() : 1;
    final out = <List<double>>[];
    for (var i = 0; i < pts.length; i += stride) {
      final g = wgs84ToGcj02(LatLng(pts[i].lat, pts[i].lon));
      out.add([g.longitude, g.latitude]);
    }
    return out;
  }

  void _drawTrack() {
    final st = _mapKey.currentState;
    if (st == null) return;
    st.render(path: _gcjPath());
    st.fitRoute();
  }

  @override
  Widget build(BuildContext context) {
    final rides = ref.watch(ridesProvider).valueOrNull ?? const <k.RideLite>[];
    k.RideLite? r;
    for (final x in rides) {
      if (x.id == widget.rideId) r = x;
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
            onPressed: () => _confirmDelete(context, r!.id),
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
          const Text('轨迹', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _trackSection(),
        ],
      ),
    );
  }

  Widget _trackSection() {
    if (_loading) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_tracks.length < 2) {
      return const Text('暂无轨迹点（记录时未采集到 GPS 数据）',
          style: TextStyle(fontSize: 12, color: AppTheme.txt3));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 260,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AmapMapView(
              key: _mapKey,
              initialZoom: 15,
              onTapLngLat: (lng, lat) {},
              onError: (msg) {},
              onReady: _drawTrack,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text('真实轨迹 · ${_tracks.length} 点（高德地图）',
            style: const TextStyle(fontSize: 11.5, color: AppTheme.txt3)),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, int id) async {
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
