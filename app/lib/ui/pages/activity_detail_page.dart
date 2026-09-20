import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../../data/activity_repository.dart';
import '../../data/gpx.dart';
import '../../data/providers.dart';
import '../../data/route_planner.dart';
import '../../domain/stats/aggregate.dart' as k;
import '../../theme/app_theme.dart';
import '../widgets/amap_native_view.dart';
import '../widgets/ele_speed_chart.dart';
import '../widgets/track_share_card.dart';

/// 活动详情：指标 + **真实轨迹（高德地图显示）** + 删除。
class ActivityDetailPage extends ConsumerStatefulWidget {
  const ActivityDetailPage({super.key, required this.rideId});

  final int rideId;

  @override
  ConsumerState<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends ConsumerState<ActivityDetailPage> {
  final GlobalKey<AmapNativeViewState> _mapKey = GlobalKey<AmapNativeViewState>();
  List<SimpleTrack> _tracks = const [];
  List<LapRecord> _laps = const [];
  bool _loading = true;
  bool _chartByDistance = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(activityRepositoryProvider);
    final pts = await repo.trackPointsFor(widget.rideId);
    final laps = await repo.lapsFor(widget.rideId);
    if (!mounted) return;
    setState(() {
      _tracks = pts;
      _laps = laps;
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

  /// 生成轨迹分享图（轨迹形状 + 数据面板 → PNG 分享）
  Future<void> _openShareCard(k.RideLite r) async {
    final u = ref.read(unitPrefsProvider);
    final path = _gcjPath();
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ShareCardPage(
        title: r.name,
        subtitle: '${r.startAt.year}-${r.startAt.month.toString().padLeft(2, '0')}-'
            '${r.startAt.day.toString().padLeft(2, '0')} · ${r.type}',
        path: path,
        stats: buildShareStats(
          distanceKm: r.distanceKm,
          durationMin: r.durationMin,
          elevGainM: r.elevGainM,
          u: u,
        ),
      ),
    ));
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
    final u = ref.watch(unitPrefsProvider);
    k.RideLite? r;
    for (final x in rides) {
      if (x.id == widget.rideId) r = x;
    }
    if (r == null) {
      return const Scaffold(
        body: Center(child: Text('活动不存在', style: TextStyle(color: AppTheme.txt3))),
      );
    }
    final speed = r.durationMin > 0 ? (r.distanceKm / (r.durationMin / 60)) : 0.0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('骑行详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.image_outlined),
            tooltip: '生成分享图',
            onPressed: () => _openShareCard(r!),
          ),
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: '导出 GPX',
            onPressed: () async {
              final n = await GpxIo.exportActivity(
                repo: ref.read(activityRepositoryProvider),
                rideId: widget.rideId,
                name: '跋涉-${r!.name}',
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                  n < 2 ? '该活动没有轨迹可导出' : '已生成 GPX（$n 个轨迹点）',
                  textAlign: TextAlign.center,
                ),
              ));
            },
          ),
          TextButton(
            onPressed: () => _editActivity(r!),
            child: const Text('编辑', style: TextStyle(fontSize: 12)),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, r!.id),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _item('类型', r.type),
          _item('日期时间',
              '${r.startAt.year}-${r.startAt.month}-${r.startAt.day} ${r.startAt.hour}:${r.startAt.minute.toString().padLeft(2, '0')}'),
          _item('距离', u.dist(r.distanceKm)),
          _item('时长(移动)', _fmtSec(r.durationMin * 60)),
          _item('均速', u.speed(speed)),
          _item('累计爬升', u.elev(r.elevGainM)),
          const SizedBox(height: 16),
          _chartSection(),
          const SizedBox(height: 12),
          _lapsSection(),
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
            child: AmapNativeView(
              key: _mapKey,
              initialZoom: 15,
              myLocationEnabled: false,
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

  /// 编辑活动：名称 / 类型 / 备注（ACT-05）
  Future<void> _editActivity(k.RideLite r) async {
    final nameCtl = TextEditingController(text: r.name);
    var type = r.type;
    String note = '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setD) => AlertDialog(
          title: const Text('编辑活动'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtl,
                decoration: const InputDecoration(labelText: '名称'),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                children: [
                  for (final t in const ['公路', '山地', '通勤', '训练', '导入'])
                    ChoiceChip(
                      label: Text(t, style: const TextStyle(fontSize: 12)),
                      selected: type == t,
                      onSelected: (_) => setD(() => type = t),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(labelText: '备注（可选）'),
                onChanged: (v) => note = v,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('取消')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('保存')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    await ref.read(activityRepositoryProvider).updateMeta(
          widget.rideId,
          name: nameCtl.text.trim().isEmpty ? r.name : nameCtl.text.trim(),
          type: type,
          note: note,
        );
    nameCtl.dispose();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('已保存修改', textAlign: TextAlign.center)));
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

  /// 海拔 / 速度曲线（原型 AD-04）
  Widget _chartSection() {
    if (_tracks.length < 2) {
      return _placeholderSection('海拔 / 速度曲线', '本次记录没有轨迹点，无法绘制曲线');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('海拔 / 速度',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('时间轴', style: TextStyle(fontSize: 11.5)),
                  selected: !_chartByDistance,
                  onSelected: (_) => setState(() => _chartByDistance = false),
                ),
                const SizedBox(width: 4),
                ChoiceChip(
                  label: const Text('距离轴', style: TextStyle(fontSize: 11.5)),
                  selected: _chartByDistance,
                  onSelected: (_) => setState(() => _chartByDistance = true),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        EleSpeedChart(points: _tracks, byDistance: _chartByDistance),
      ],
    );
  }

  /// 分段 / 计圈列表（原型 laps 区块）
  Widget _lapsSection() {
    if (_laps.isEmpty) {
      return _placeholderSection('分段 / 计圈', '本次记录没有分段（未开启自动计圈且未手动计圈）');
    }
    final u = ref.watch(unitPrefsProvider);
    var bestIdx = _laps.first.idx;
    for (final l in _laps) {
      if (l.avgKmh > (_laps.firstWhere((x) => x.idx == bestIdx).avgKmh)) bestIdx = l.idx;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('分段 / 计圈 · ${_laps.length} 圈',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.line),
          ),
          child: Column(
            children: [
              for (var i = 0; i < _laps.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                ListTile(
                  dense: true,
                  leading: Text('L${_laps[i].idx}',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.accentInk)),
                  title: Text(
                      '${u.dist(_laps[i].km, digits: 2)} · ${_fmtSec(_laps[i].seconds.toDouble())}',
                      style: const TextStyle(fontSize: 13)),
                  subtitle: Text('均速 ${u.speed(_laps[i].avgKmh)}'
                      '${_laps[i].idx == bestIdx && _laps.length > 1 ? ' · 最快圈' : ''}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.txt3)),
                  trailing: const Icon(Icons.chevron_right, size: 18, color: AppTheme.txt3),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// 未完成区块占位（原型有、功能待做）
  Widget _placeholderSection(String title, String hint) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.card2,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 13, color: AppTheme.txt2)),
            const SizedBox(height: 4),
            Text(hint, style: const TextStyle(fontSize: 11, color: AppTheme.txt3)),
          ],
        ),
      );

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
