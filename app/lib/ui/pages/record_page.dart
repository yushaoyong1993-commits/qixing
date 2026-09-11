import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/activity_repository.dart';
import '../../data/providers.dart';
import '../../domain/record/session_machine.dart';
import '../../theme/app_theme.dart';

/// 记录页（M1）：真实 GPS 定位驱动（速度/距离/爬升都来自位置流）+ 会话状态机 + 草稿 + 保存。
class RecordPage extends ConsumerStatefulWidget {
  const RecordPage({super.key});

  @override
  ConsumerState<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends ConsumerState<RecordPage> {
  final SessionMachine _m = SessionMachine();
  static const _types = ['公路', '山地', '通勤', '训练'];

  String _type = '公路';
  bool _autoPause = true;
  bool _autoLap = false;
  double _lapBase = 0;

  DateTime _startedAt = DateTime.now();

  // 秒表（与 GPS 解耦：无定位时长照常走）
  Timer? _ticker;

  // 真实定位
  StreamSubscription<Position>? _posSub;
  Position? _last;
  double _spdKmph = 0;
  bool _gpsReady = false;
  bool _gpsDenied = false;

  DraftData? _draft;
  final List<SimpleTrack> _tracks = [];

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    final d = await ref.read(activityRepositoryProvider).loadDraft();
    if (mounted && d != null) setState(() => _draft = d);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _posSub?.cancel();
    _persistDraftIfActive();
    super.dispose();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_m.phase == SessionPhase.recording) {
        _m.tickSec();
        setState(() {});
      }
    });
  }

  void _persistDraftIfActive() {
    if (_m.isActive) {
      ref.read(activityRepositoryProvider).saveDraft(
            type: _type,
            startedAt: _startedAt,
            totalS: _m.movingSec,
            distanceKm: _m.distanceKm,
            laps: _m.lapCount,
          );
    }
  }

  Future<void> _initLoc() async {
    try {
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _gpsDenied = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('未授予定位权限：时长照常记录，但无距离/速度/轨迹', textAlign: TextAlign.center)),
          );
        }
        return;
      }
      _posSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 2,
        ),
      ).listen(_onPos, onError: (_) {});
      setState(() => _gpsReady = false);
    } catch (_) {
      // 无定位环境（如测试/模拟器无插件）时静默降级：距离为 0，仍可记录计时。
    }
  }

  void _onPos(Position pos) {
    if (_m.phase == SessionPhase.recording) {
      double distKm = 0;
      double elevDelta = 0;
      double meters = 0;
      if (_last != null) {
        meters = Geolocator.distanceBetween(
          _last!.latitude, _last!.longitude, pos.latitude, pos.longitude);
        distKm = meters / 1000;
        if (pos.altitude.isFinite && _last!.altitude.isFinite && pos.altitude > _last!.altitude) {
          elevDelta = pos.altitude - _last!.altitude;
        }
      }
      _last = pos;
      final spd = pos.speed.isFinite && pos.speed >= 0 ? pos.speed * 3.6 : 0.0;
      _spdKmph = spd;
      _m.addSample(distKm: distKm, elevM: elevDelta);
      if (meters >= 5 || _tracks.isEmpty) {
        _tracks.add(SimpleTrack(
          tMs: pos.timestamp.millisecondsSinceEpoch,
          lat: pos.latitude,
          lon: pos.longitude,
          altM: pos.altitude.isFinite ? pos.altitude : null,
          speedMps: (pos.speed.isFinite && pos.speed >= 0) ? pos.speed : null,
        ));
      }
      if (_autoLap && _m.distanceKm - _lapBase >= 5) {
        _lapBase = _m.distanceKm;
        _m.lap();
      }
      if (_autoPause && spd < 0.5) _pause(); // 速度≈0 自动暂停
      _gpsReady = true;
      if (mounted) setState(() {});
    } else {
      _last = pos;
    }
  }

  void _start({bool resume = false}) {
    if (!resume) {
      if (!_m.start(autoPause: _autoPause)) return;
      _startedAt = DateTime.now();
    } else {
      final d = _draft;
      if (d == null) return;
      _type = d.type;
      _m.restore(distanceKm: d.distanceKm, movingSec: d.totalS, laps: d.laps);
      _startedAt = d.startedAt;
      _draft = null;
    }
    _lapBase = _m.distanceKm;
    _last = null;
    _spdKmph = 0;
    _tracks.clear();
    _startTicker();
    setState(() {});
    _initLoc();
  }

  void _pause() {
    if (_m.phase != SessionPhase.recording) return;
    _m.pause();
    _posSub?.pause();
    setState(() {});
  }

  void _resume() {
    if (_m.phase != SessionPhase.paused) return;
    _m.resume();
    _posSub?.resume();
    setState(() {});
  }

  void _pauseOrResume() {
    if (_m.phase == SessionPhase.recording) {
      _pause();
    } else if (_m.phase == SessionPhase.paused) {
      _resume();
    }
  }

  Future<void> _stop() async {
    _posSub?.cancel();
    _posSub = null;
    _m.finish();
    setState(() {});
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('骑行完成 🎉'),
        content: Text(
          '类型 $_type\n距离 ${_m.distanceKm.toStringAsFixed(1)} km\n'
          '时长 ${_fmtSec(_m.movingSec)}\n'
          '爬升 ${_m.elevGainM.round()} m · 圈数 ${_m.lapCount}',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('丢弃')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('保存')),
        ],
      ),
    );
    await ref.read(activityRepositoryProvider).deleteDraft();
    if (ok == true) await _save();
    _m.discard();
    _spdKmph = 0;
    _last = null;
    setState(() {});
  }

  Future<void> _save() async {
    final repo = ref.read(activityRepositoryProvider);
    final id = await repo.saveRide(
      name: '$_type骑行',
      type: _type,
      startAt: _startedAt,
      durationS: _m.movingSec,
      movingS: _m.movingSec,
      distanceM: _m.distanceKm * 1000,
      elevGainM: _m.elevGainM,
      elevLossM: _m.elevGainM * 0.9,
      hrAvg: null,
      hrMax: null,
      kcal: (_m.distanceKm * 24).round(),
    );
    if (_tracks.isNotEmpty) await repo.saveTrackPoints(id, _tracks);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已保存 · 首页/统计已自动刷新', textAlign: TextAlign.center)),
    );
  }

  String _fmtSec(int s) {
    final h = s ~/ 3600, m = (s % 3600) ~/ 60, ss = s % 60;
    String p(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '${p(h)}:${p(m)}:${p(ss)}' : '${p(m)}:${p(ss)}';
  }

  @override
  Widget build(BuildContext context) {
    final live = _m.isActive || _m.phase == SessionPhase.summary;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (!live && _draft != null) _draftBanner(),
          if (!live) _prepare() else _live(),
        ]),
      ),
    );
  }

  Widget _draftBanner() {
    final d = _draft!;
    return Card(
      elevation: 0,
      color: const Color(0xFFFDEBDD),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppTheme.accent)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.history, color: AppTheme.accentInk),
        title: Text('未完成的草稿（${d.type}）', style: const TextStyle(fontSize: 13.5)),
        subtitle: Text('${d.distanceKm.toStringAsFixed(1)} km · ${_fmtSec(d.totalS)}'),
        trailing: ElevatedButton(
          onPressed: () => _start(resume: true),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, foregroundColor: Colors.white),
          child: const Text('继续'),
        ),
      ),
    );
  }

  Widget _prepare() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const Icon(Icons.directions_bike, size: 48, color: AppTheme.accent),
          const SizedBox(height: 10),
          Text('开始骑行', style: _h1),
          const SizedBox(height: 6),
          const Text('真实 GPS 定位 · 速度/距离/爬升均来自手机定位',
              style: TextStyle(fontSize: 12, color: AppTheme.txt3)),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final t in _types)
                Expanded(
                  child: ChoiceChip(
                    label: Center(child: Text(t, style: const TextStyle(fontSize: 12.5))),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            title: const Text('自动暂停', style: TextStyle(fontSize: 13.5)),
            subtitle: const Text('速度≈0 时暂停计时', style: TextStyle(fontSize: 11, color: AppTheme.txt3)),
            value: _autoPause,
            onChanged: (v) => setState(() => _autoPause = v),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('自动计圈（5km）', style: TextStyle(fontSize: 13.5)),
            subtitle: const Text('每 5 km 记一圈', style: TextStyle(fontSize: 11, color: AppTheme.txt3)),
            value: _autoLap,
            onChanged: (v) => setState(() => _autoLap = v),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _start,
            icon: const Icon(Icons.play_arrow),
            label: const Text('开始记录'),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.accent, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
          ),
        ],
      ),
    );
  }

  Widget _live() {
    final paused = _m.phase == SessionPhase.paused;
    final avg = _m.movingSec > 0 ? _m.distanceKm / (_m.movingSec / 3600) : 0.0;
    return Column(
      children: [
        Text(_fmtSec(_m.movingSec), style: _h1.copyWith(fontSize: 54)),
        const SizedBox(height: 6),
        Text(
            paused
                ? '已暂停'
                : _gpsDenied
                    ? '未获定位权限 · 仅记录时长'
                    : (_gpsReady ? '记录中 · GPS 正常' : '搜索卫星中… · 请到开阔处'),
            style: TextStyle(
                fontSize: 12.5,
                color: paused
                    ? AppTheme.warn
                    : (_gpsDenied ? AppTheme.warn : AppTheme.txt3))),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _stat('速度 km/h', _spdKmph.toStringAsFixed(1)),
            _stat('距离 km', _m.distanceKm.toStringAsFixed(1)),
            _stat('均速 km/h', avg.toStringAsFixed(1)),
          ],
        ),
        const SizedBox(height: 6),
        Text('爬升 ${_m.elevGainM.round()} m · 圈数 ${_m.lapCount}',
            style: const TextStyle(fontSize: 12, color: AppTheme.txt2)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filledTonal(
              onPressed: _pauseOrResume,
              icon: Icon(paused ? Icons.play_arrow : Icons.pause),
              tooltip: paused ? '继续' : '暂停',
            ),
            const SizedBox(width: 24),
            IconButton.filled(
              onPressed: _stop,
              icon: const Icon(Icons.stop),
              style: IconButton.styleFrom(backgroundColor: AppTheme.accent, iconSize: 32, padding: const EdgeInsets.all(14)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _stat(String label, String value) => Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.txt)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.txt3)),
        ],
      );

  static const _h1 = TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.txt);
}
