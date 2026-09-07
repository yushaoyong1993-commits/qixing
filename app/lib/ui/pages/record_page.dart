import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../domain/record/session_machine.dart';
import '../../theme/app_theme.dart';

/// 记录页（M1）：会话状态机 + 计时 + 保存到数据库。
/// 保存后首页/统计通过 Drift watch 自动刷新（闭环）。
class RecordPage extends ConsumerStatefulWidget {
  const RecordPage({super.key});

  @override
  ConsumerState<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends ConsumerState<RecordPage> {
  final SessionMachine _m = SessionMachine();
  Timer? _t;
  final Random _r = Random();
  double _speed = 0;

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  void _start() {
    if (!_m.start()) return;
    _t?.cancel();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_m.phase == SessionPhase.recording) {
        _speed = 22 + _r.nextDouble() * 12;
        _m.advance(dtSec: 1, speedKmh: _speed);
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
          '距离 ${_m.distanceKm.toStringAsFixed(1)} km\n'
          '时长 ${_fmtSec(_m.movingSec)}\n'
          '圈数 ${_m.lapCount}',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false), child: const Text('丢弃')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true), child: const Text('保存')),
        ],
      ),
    );
    if (ok == true) await _save();
    _m.discard();
    _speed = 0;
    setState(() {});
  }

  Future<void> _save() async {
    final repo = ref.read(activityRepositoryProvider);
    await repo.saveRide(
      name: '手动记录',
      type: '公路',
      startAt: DateTime.now().subtract(Duration(seconds: _m.movingSec)),
      durationS: _m.movingSec,
      movingS: _m.movingSec,
      distanceM: _m.distanceKm * 1000,
      elevGainM: _m.distanceKm * 1.6, // 演示：按里程粗略估算爬升
      elevLossM: _m.distanceKm * 1.4,
      hrAvg: null,
      hrMax: null,
      kcal: (_m.distanceKm * 24).round(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已保存 · 首页概览已自动刷新', textAlign: TextAlign.center)),
    );
  }

  String _fmtSec(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$m:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final live = _m.isActive || _m.phase == SessionPhase.summary;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!live) _prepare() else _live(),
          ],
        ),
      ),
    );
  }

  Widget _prepare() {
    return Column(
      children: [
        const Icon(Icons.directions_bike, size: 48, color: AppTheme.accent),
        const SizedBox(height: 12),
        Text('开始骑行', style: _h1),
        const SizedBox(height: 6),
        const Text('本地记录 · 保存后首页自动更新',
            style: TextStyle(fontSize: 12.5, color: AppTheme.txt3)),
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: _start,
          icon: const Icon(Icons.play_arrow),
          label: const Text('开始记录'),
          style: FilledButton.styleFrom(backgroundColor: AppTheme.accent, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
        ),
      ],
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
        Text(paused ? '已暂停' : '记录中，切走不中断',
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
