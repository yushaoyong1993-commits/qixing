import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 高德**原生 SDK** 地图（Android PlatformView）。
///
/// 与 WebView 版 [AmapMapView] 保持同构 API（render / renderNav / moveTo / fitRoute / refresh），
/// 页面侧只需替换组件类型即可完成迁移，无需改动业务逻辑。
///
/// 非 Android 平台（含单元测试）自动降级为占位，避免平台通道缺失导致异常。
class AmapNativeView extends StatefulWidget {
  const AmapNativeView({
    super.key,
    required this.onTapLngLat,
    this.onReady,
    this.onError,
    this.initialZoom = 15,
    this.myLocationEnabled = true,
    this.initialCenter,
  });

  final void Function(double lng, double lat) onTapLngLat;
  final VoidCallback? onReady;
  final void Function(String msg)? onError;
  final double initialZoom;

  /// 是否开启「我的位置」蓝点（需要定位权限；原生 SDK 自身会读取系统定位）
  final bool myLocationEnabled;

  /// 初始中心 [lng, lat]
  final List<double>? initialCenter;

  /// 关闭后强制走占位（测试或排查原生问题时使用）
  static bool enabled = true;

  @override
  State<AmapNativeView> createState() => AmapNativeViewState();
}

class AmapNativeViewState extends State<AmapNativeView> {
  MethodChannel? _method;
  AppLifecycleListener? _lifecycle;
  StreamSubscription<dynamic>? _events;
  bool _ready = false;

  /// 最近一次渲染参数（原生就绪前调用会被缓存，就绪后重放）
  Map<String, dynamic>? _lastRender;
  Map<String, dynamic>? _lastRenderNav;
  bool _pendingFit = false;
  Map<String, dynamic>? _pendingMove;

  bool get _supported =>
      AmapNativeView.enabled &&
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    // 跟随 App 生命周期暂停/恢复原生地图，避免后台持续渲染耗电
    _lifecycle = AppLifecycleListener(
      onResume: () => _invoke('resume', const {}),
      onPause: () => _invoke('pause', const {}),
      onHide: () => _invoke('pause', const {}),
    );
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    _events?.cancel();
    super.dispose();
  }

  void _onPlatformViewCreated(int id) {
    _method = MethodChannel('basho/amap_$id');
    _events = EventChannel('basho/amap_events_$id').receiveBroadcastStream().listen(
      (event) {
        if (event is! Map) return;
        switch (event['type']) {
          case 'ready':
            _ready = true;
            widget.onReady?.call();
            _replayPending();
            break;
          case 'tap':
            final lng = (event['lng'] as num?)?.toDouble();
            final lat = (event['lat'] as num?)?.toDouble();
            if (lng != null && lat != null) widget.onTapLngLat(lng, lat);
            break;
          case 'error':
            widget.onError?.call('${event['msg']}');
            break;
        }
      },
      onError: (Object e) => widget.onError?.call('原生地图事件通道异常：$e'),
    );
  }

  void _replayPending() {
    final render = _lastRender;
    if (render != null) _invoke('render', render);
    final nav = _lastRenderNav;
    if (nav != null) _invoke('renderNav', nav);
    final move = _pendingMove;
    if (move != null) {
      _invoke('moveTo', move);
      _pendingMove = null;
    }
    if (_pendingFit) {
      _invoke('fitRoute', const {});
      _pendingFit = false;
    }
  }

  void _invoke(String method, Map<String, dynamic> args) {
    final ch = _method;
    if (ch == null || !_ready) return;
    ch.invokeMethod<void>(method, args).catchError((Object e) {
      widget.onError?.call('原生地图调用失败（$method）：$e');
    });
  }

  // ---------- 与 WebView 版同构的公开 API ----------

  /// 定制路线 / 轨迹：锚点 + 主路径；myLoc 为当前位置 [lng, lat]
  void render({
    List<List<double>> anchors = const [],
    List<List<double>> path = const [],
    List<double>? myLoc,
  }) {
    final args = <String, dynamic>{
      'anchors': anchors,
      'path': path,
      'myLoc': myLoc,
    };
    _lastRender = args;
    _invoke('render', args);
  }

  /// 导航：已骑 / 未骑 双色 + 当前位置
  void renderNav({
    required List<List<double>> done,
    required List<List<double>> todo,
    List<double>? me,
  }) {
    final args = <String, dynamic>{'done': done, 'todo': todo, 'me': me};
    _lastRenderNav = args;
    _invoke('renderNav', args);
  }

  void moveTo(double lng, double lat, {double zoom = 16}) {
    final args = <String, dynamic>{'lng': lng, 'lat': lat, 'zoom': zoom};
    if (!_ready) {
      _pendingMove = args;
      return;
    }
    _invoke('moveTo', args);
  }

  void fitRoute() {
    if (!_ready) {
      _pendingFit = true;
      return;
    }
    _invoke('fitRoute', const {});
  }

  void refresh() => _invoke('refresh', const {});

  /// 与 WebView 版保持同构：原生地图无需销毁重建，这里重放最近渲染内容并刷新即可
  /// （调用点无需感知两版差异）。
  void rebuild() {
    _invoke('refresh', const {});
    final render = _lastRender;
    if (render != null) _invoke('render', render);
    final nav = _lastRenderNav;
    if (nav != null) _invoke('renderNav', nav);
  }

  @override
  Widget build(BuildContext context) {
    if (!_supported) {
      return Container(
        color: const Color(0xFFF2F2F5),
        alignment: Alignment.center,
        child: const Text('地图不可用（仅 Android 原生地图）',
            style: TextStyle(fontSize: 12, color: Color(0xFF9898A3))),
      );
    }
    return AndroidView(
      viewType: 'basho/amap',
      creationParams: <String, dynamic>{
        'zoom': widget.initialZoom,
        'center': widget.initialCenter,
        'myLocationEnabled': widget.myLocationEnabled,
      },
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _onPlatformViewCreated,
    );
  }
}
