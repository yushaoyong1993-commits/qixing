import 'dart:async';

import 'package:flutter/services.dart';

/// 一个离线地图城市包
class OfflineCity {
  const OfflineCity({
    required this.name,
    required this.adcode,
    required this.sizeKb,
    required this.state,
    required this.percent,
    required this.version,
  });

  final String name;
  final String adcode;

  /// 包大小（KB，0 表示未知）
  final int sizeKb;

  /// 高德离线状态码（0 未下载；4 已完成；其余为下载/暂停等中间态）
  final int state;

  /// 完成百分比 0~100
  final int percent;
  final String version;

  bool get downloaded => state == 4 || percent >= 100;

  /// 是否处于下载中（有进度但未完成）
  bool get downloading => !downloaded && percent > 0;

  String get sizeText {
    if (sizeKb <= 0) return '未知大小';
    final mb = sizeKb / 1024;
    return mb >= 1024 ? '${(mb / 1024).toStringAsFixed(1)} GB' : '${mb.toStringAsFixed(1)} MB';
  }

  String get statusText {
    if (downloaded) return '已下载';
    if (downloading) return '下载中 $percent%';
    if (percent >= 100) return '已下载';
    return '未下载';
  }
}

/// 离线地图服务（对接 Android 原生高德 OfflineMapManager）
class OfflineMapService {
  static const MethodChannel _m = MethodChannel('basho/offline');
  static const EventChannel _e = EventChannel('basho/offline_events');

  /// 原生离线地图能力是否可用
  Future<bool> available() async {
    try {
      return (await _m.invokeMethod<bool>('available')) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<List<OfflineCity>> cities() async {
    try {
      final raw = await _m.invokeMethod<List<dynamic>>('cities');
      if (raw == null) return const [];
      final out = <OfflineCity>[];
      for (final item in raw) {
        if (item is! Map) continue;
        final name = '${item['name'] ?? ''}'.trim();
        if (name.isEmpty) continue;
        out.add(OfflineCity(
          name: name,
          adcode: '${item['adcode'] ?? ''}',
          sizeKb: (item['size'] as num?)?.toInt() ?? 0,
          state: (item['state'] as num?)?.toInt() ?? 0,
          percent: (item['percent'] as num?)?.toInt() ?? 0,
          version: '${item['version'] ?? ''}',
        ));
      }
      // 已下载 / 下载中 排在前面
      out.sort((a, b) {
        int rank(OfflineCity c) => c.downloaded
            ? 0
            : c.downloading
                ? 1
                : 2;
        final r = rank(a).compareTo(rank(b));
        return r != 0 ? r : a.name.compareTo(b.name);
      });
      return out;
    } catch (_) {
      return const [];
    }
  }

  /// 下载指定城市（名称需与高德城市列表一致，如「深圳市」）
  Future<bool> download(String name) async {
    try {
      return (await _m.invokeMethod<bool>('download', {'name': name})) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> pause() async {
    try {
      return (await _m.invokeMethod<bool>('pause')) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> remove(String name) async {
    try {
      return (await _m.invokeMethod<bool>('remove', {'name': name})) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// 下载进度事件流（每次事件后建议再调用 [cities] 刷新列表）
  Stream<Map<dynamic, dynamic>> progressStream() {
    return _e.receiveBroadcastStream().where((e) => e is Map).cast<Map<dynamic, dynamic>>();
  }
}
