import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/activity_repository.dart';
import '../../data/providers.dart';
import '../../domain/record/session_machine.dart';
import '../../theme/app_theme.dart';

/// 记录页（M1）：类型/自动暂停/自动计圈 + 会话状态机计时 + 草稿恢复 + 保存闭环。
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

  Timer? _t;
  final Random _r = Random();
  double _speed = 0;
  DraftData? _draft;

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
    _t?.cancel();
    _persistDraftIfActive();
    super.dispose();
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
    _t?.cancel();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_m.phase == SessionPhase.recording) {
        _speed = 22 + _r.nextDouble() * 12;
        _m.advance(dtSec: 1, speedKmh: _speed, stopped: _autoPause && _speed < 0.5);
        if (_autoLap && _m.distanceKm - _lapBase >= 5) {
          _lapBase = _m.distanceKm;
          _m.lap();
        }
      }
      setState(() {});
    });
    setState(() {});
  }

  void _pauseOrResume() {
    if (_m.phase == SessionPhase.recording) {
      _m.pause();
    } else if (_m.phase == SessionPhase.paused) {
      _m.resume();
    }
    setState(() {});
  }

  Future<void> _stop() async {
    _t?.cancel();
    _m.finish();
    setState(() {});
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('骑行完成 🎉'),
        content: Text(
          '类型 $_type\n'
          '距离 ${_m.distanceKm.toStringAsFixed(1)} km\n'
          '时长 ${_fmtSec(_m.movingSec)}\n'
          '圈数 ${_m.lapCount}',
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
    _speed = 0;
    setState(() {});
  }

  Future<void> _save() async {
    final repo = ref.read(activityRepositoryProvider);
    await repo.saveRide(
      name: '$_type骑行',
      type: _type,
      startAt: _startedAt,
      durationS: _m.movingSec,
      movingS: _m.movingSec,
      distanceM: _m.distanceKm * 1000,
      elevGainM: _m.distanceKm * 1.6,
      elevLossM: _m.distanceKm * 1.4,
      hrAvg: null,
      hrMax: null,
      kcal: (_m.distanceKm * 24).round(),
    );
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
          const SizedBox(height: 18),
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
          const SizedBox(height: 12),
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
    return Column(
      children: [
        Text(_fmtSec(_m.movingSec), style: _h1.copyWith(fontSize: 54)),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _stat('距离 km', _m.distanceKm.toStringAsFixed(1)),
            _stat('均速 km/h', _m.distanceKm > 0 ? (_m.distanceKm / (_m.movingSec / 3600)).toStringAsFixed(1) : '0.0'),
            _stat('圈数', '${_m.lapCount}'),
          ],
        ),
        const SizedBox(height: 24),
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
        Text('$_type · 记录中${paused ? '（已暂停）' : ''} · 切走不中断',
            style: const TextStyle(fontSize: 12.5, color: AppTheme.txt3)),
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
