import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../../data/providers.dart';
import '../../data/route_planner.dart';
import '../../data/route_repository.dart';
import '../../domain/nav/route_navigator.dart';
import '../../domain/record/voice_announcer.dart';
import '../../theme/app_theme.dart';
import '../widgets/amap_native_view.dart';

/// 沿路线骑行导航（RT-06）：实时进度 / 剩余距离 / 转向提示 / 偏航提醒 / 到达播报。
/// 说明：路线点存的是 GCJ-02（高德），GPS 为 WGS84，进入导航前统一转到 GCJ-02 计算与显示。
class NavigationPage extends ConsumerStatefulWidget {
  const NavigationPage({super.key, required this.route});

  final RouteModel route;

  @override
  ConsumerState<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends ConsumerState<NavigationPage> {
  final GlobalKey<AmapNativeViewState> _mapKey = GlobalKey<AmapNativeViewState>();
  final VoiceAnnouncer _voice = VoiceAnnouncer();

  late final RouteNavigator _nav;
  late final List<LatLng> _routeGcj;
  StreamSubscription<Position>? _sub;

  NavProgress? _p;
  bool _voiceOn = true;
  bool _locating = false;
  bool _arrivedShown = false;
  bool _wasOffRoute = false;
  double _lastTurnAnnounceTurnIn = double.infinity;
  DateTime _lastMapDraw = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _routeGcj = [
      for (final p in widget.route.points) LatLng(p[0], p[1]),
    ];
    _nav = RouteNavigator(_routeGcj);
    _voice.init();
    _start();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _voice.stop();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _locating = true);
    try {
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() => _locating = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('未授予定位权限，无法导航', textAlign: TextAlign.center)));
        return;
      }
      final settings = AndroidSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 2,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: '跋涉 · 导航中',
          notificationText: '正在沿路线导航（请勿划掉通知）',
          notificationChannelName: '骑行导航',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
      _sub = Geolocator.getPositionStream(locationSettings: settings).listen(_onPos,
          onError: (_) {});
      setState(() => _locating = false);
    } catch (_) {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _onPos(Position pos) {
    // GPS(WGS84) → GCJ-02，与路线/底图同坐标系
    final g = wgs84ToGcj02(LatLng(pos.latitude, pos.longitude));
    final prog = _nav.update(g);
    if (!mounted) return;
    setState(() => _p = prog);

    // 地图：已骑（灰）/ 未骑（橙）+ 当前位置，约 1 秒重绘一次
    final now = DateTime.now();
    if (now.difference(_lastMapDraw).inMilliseconds > 1000) {
      _lastMapDraw = now;
      final done = _nav.donePoints(prog.alongM);
      final todo = _nav.todoPoints(prog.alongM);
      _mapKey.currentState?.renderNav(
        done: [
          for (final p in done) [p.longitude, p.latitude],
        ],
        todo: [
          for (final p in todo) [p.longitude, p.latitude],
        ],
        me: [g.longitude, g.latitude],
      );
    }

    // 偏航提醒
    if (prog.offRoute && !_wasOffRoute) {
      _wasOffRoute = true;
      _speak('已偏离路线 ${prog.offRouteM.round()} 米，请返回路线');
    } else if (!prog.offRoute) {
      _wasOffRoute = false;
    }

    // 转向提示：进入 200m / 80m 各播报一次
    if (prog.turnDir != TurnDir.straight && prog.turnInM > 5) {
      final dir = prog.turnDir == TurnDir.right ? '右转' : '左转';
      if (prog.turnInM <= 200 && _lastTurnAnnounceTurnIn > 200) {
        _speak('前方 ${_roundTo50(prog.turnInM)} 米 $dir');
      } else if (prog.turnInM <= 80 && _lastTurnAnnounceTurnIn > 80) {
        _speak('前方 ${prog.turnInM.round()} 米 $dir');
      }
      _lastTurnAnnounceTurnIn = prog.turnInM;
    } else if (prog.turnInM > 250) {
      _lastTurnAnnounceTurnIn = double.infinity; // 进入下一段，重置
    }

    // 到达
    if (prog.arrived && !_arrivedShown) {
      _arrivedShown = true;
      _speak('已到达终点');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('已到达终点 🎉', textAlign: TextAlign.center),
        action: SnackBarAction(label: '结束导航', onPressed: () => Navigator.pop(context)),
      ));
    }
  }

  int _roundTo50(double m) => (m / 50).round() * 50;

  void _speak(String text) {
    if (_voiceOn) _voice.say(text);
  }

  @override
  Widget build(BuildContext context) {
    final u = ref.watch(unitPrefsProvider);
    final p = _p;
    return Scaffold(
      appBar: AppBar(
        title: Text('导航 · ${widget.route.name}'),
        actions: [
          IconButton(
            icon: Icon(_voiceOn ? Icons.volume_up : Icons.volume_off),
            tooltip: '语音播报',
            onPressed: () => setState(() => _voiceOn = !_voiceOn),
          ),
        ],
      ),
      body: Column(
        children: [
          _headCard(p, u),
          Expanded(
            child: AmapNativeView(
              key: _mapKey,
              initialZoom: 16,
              myLocationEnabled: false,
              onTapLngLat: (lng, lat) {},
              onError: (msg) {},
              onReady: () {
                final prog = _p;
                if (prog == null) return;
                final done = _nav.donePoints(prog.alongM);
                final todo = _nav.todoPoints(prog.alongM);
                _mapKey.currentState?.renderNav(
                  done: [
                    for (final q in done) [q.longitude, q.latitude],
                  ],
                  todo: [
                    for (final q in todo) [q.longitude, q.latitude],
                  ],
                );
              },
            ),
          ),
          Container(
            color: AppTheme.bg,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _locating ? null : _start,
                      icon: const Icon(Icons.my_location, size: 18),
                      label: Text(_locating ? '定位中…' : '重新定位'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: AppTheme.accent),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('结束导航'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headCard(NavProgress? p, dynamic u) {
    final remain = p == null ? widget.route.distKm : p.remainingM / 1000;
    final along = p == null ? 0.0 : p.alongM / 1000;
    final total = widget.route.distKm;
    final pct = total <= 0 ? 0 : ((along / total) * 100).clamp(0, 100);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: AppTheme.card2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('剩余 ${u.dist(remain)}',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.txt)),
                    Text('已骑 ${u.dist(along)} / 共 ${u.dist(total)} · ${pct.round()}%',
                        style: const TextStyle(fontSize: 11.5, color: AppTheme.txt3)),
                  ],
                ),
              ),
              _turnBadge(p),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 7,
              backgroundColor: AppTheme.bg,
              valueColor: const AlwaysStoppedAnimation(AppTheme.accent),
            ),
          ),
          if (p != null && p.offRoute)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 16, color: AppTheme.warn),
                  const SizedBox(width: 6),
                  Text('已偏离路线 ${p.offRouteM.round()} 米，请返回',
                      style: const TextStyle(fontSize: 12, color: AppTheme.warn)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _turnBadge(NavProgress? p) {
    if (p == null) {
      return const Text('等待定位…', style: TextStyle(fontSize: 12, color: AppTheme.txt3));
    }
    if (p.arrived) {
      return const Text('已到达 🎉',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.accentInk));
    }
    switch (p.turnDir) {
      case TurnDir.left:
        return _badge(Icons.turn_left, '${p.turnInM.round()} m 左转');
      case TurnDir.right:
        return _badge(Icons.turn_right, '${p.turnInM.round()} m 右转');
      case TurnDir.straight:
        return _badge(Icons.straight, '沿路线直行');
    }
  }

  Widget _badge(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 26, color: AppTheme.accentInk),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.accentInk)),
        ],
      );
}
