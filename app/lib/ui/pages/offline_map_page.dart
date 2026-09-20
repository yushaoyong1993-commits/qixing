import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/offline_map_service.dart';
import '../../theme/app_theme.dart';

/// 离线地图页：下载城市地图包，无网络时也能看地图。
///
/// 数据来自 Android 原生高德 OfflineMapManager（反射封装）；进度通过原生事件流 + 轮询双保险。
class OfflineMapPage extends StatefulWidget {
  const OfflineMapPage({super.key});

  @override
  State<OfflineMapPage> createState() => _OfflineMapPageState();
}

class _OfflineMapPageState extends State<OfflineMapPage> {
  final OfflineMapService _svc = OfflineMapService();
  final TextEditingController _kw = TextEditingController();

  List<OfflineCity> _all = const [];
  bool _loading = true;
  bool _available = true;
  String? _busyCity;
  StreamSubscription<Map<dynamic, dynamic>>? _sub;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final ok = await _svc.available();
    if (!mounted) return;
    setState(() => _available = ok);
    if (!ok) {
      setState(() => _loading = false);
      return;
    }
    _sub = _svc.progressStream().listen((e) {
      if (!mounted) return;
      final type = '${e['type']}';
      if (type == 'progress') {
        final name = '${e['name']}';
        final percent = (e['percent'] as num?)?.toInt() ?? 0;
        setState(() {
          _all = [
            for (final c in _all)
              if (c.name == name)
                OfflineCity(
                  name: c.name,
                  adcode: c.adcode,
                  sizeKb: c.sizeKb,
                  state: percent >= 100 ? 4 : c.state,
                  percent: percent,
                  version: c.version,
                )
              else
                c
          ];
        });
      } else {
        _refresh();
      }
    });
    await _refresh();
    // 轮询兜底：原生回调在部分机型/版本可能不触发
    _poll = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_busyCity != null) _refresh();
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _sub?.cancel();
    _kw.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final list = await _svc.cities();
    if (!mounted) return;
    setState(() {
      _all = list;
      _loading = false;
    });
  }

  Future<void> _download(OfflineCity c) async {
    setState(() => _busyCity = c.name);
    final ok = await _svc.download(c.name);
    if (!mounted) return;
    if (!ok) {
      setState(() => _busyCity = null);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('无法开始下载「${c.name}」，请稍后重试', textAlign: TextAlign.center),
      ));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('已开始下载「${c.name}」离线地图', textAlign: TextAlign.center),
      duration: const Duration(seconds: 1),
    ));
    await Future.delayed(const Duration(milliseconds: 800));
    await _refresh();
  }

  Future<void> _pause() async {
    await _svc.pause();
    setState(() => _busyCity = null);
    await _refresh();
  }

  Future<void> _remove(OfflineCity c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c2) => AlertDialog(
        title: Text('删除「${c.name}」离线地图？'),
        content: Text('将释放 ${c.sizeText} 存储空间，下次需要时可重新下载。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c2, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(c2, true), child: const Text('删除')),
        ],
      ),
    );
    if (ok != true) return;
    await _svc.remove(c.name);
    if (!mounted) return;
    setState(() => _busyCity = null);
    await _refresh();
  }

  List<OfflineCity> get _filtered {
    final kw = _kw.text.trim();
    if (kw.isEmpty) return _all;
    return _all
        .where((c) => c.name.contains(kw) || c.adcode.contains(kw))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final downloaded = _all.where((c) => c.downloaded).toList();
    final totalMb = downloaded.fold<int>(0, (s, c) => s + c.sizeKb) / 1024;

    return Scaffold(
      appBar: AppBar(
        title: const Text('离线地图'),
        actions: [
          if (_busyCity != null)
            IconButton(
              icon: const Icon(Icons.pause_circle_outline),
              tooltip: '暂停下载',
              onPressed: _pause,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: _refresh,
          ),
        ],
      ),
      body: !_available
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  '当前设备不支持离线地图（仅 Android 端可用）',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppTheme.txt3),
                ),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          downloaded.isEmpty
                              ? '还没有下载任何城市地图'
                              : '已下载 ${downloaded.length} 个城市 · 约 ${totalMb.toStringAsFixed(0)} MB',
                          style: const TextStyle(fontSize: 12.5, color: AppTheme.txt3),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: TextField(
                    controller: _kw,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: '搜索城市（如：深圳、杭州）',
                      hintStyle: const TextStyle(fontSize: 12.5, color: AppTheme.txt3),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      filled: true,
                      fillColor: AppTheme.card2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                if (_loading) const LinearProgressIndicator(minHeight: 2),
                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                          child: Text(_loading ? '' : '没有匹配的城市',
                              style: const TextStyle(fontSize: 12.5, color: AppTheme.txt3)),
                        )
                      : ListView.separated(
                          itemCount: _filtered.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (c, i) {
                            final city = _filtered[i];
                            return ListTile(
                              dense: true,
                              title: Text(city.name, style: const TextStyle(fontSize: 14)),
                              subtitle: Text('${city.statusText} · ${city.sizeText}',
                                  style: const TextStyle(fontSize: 11.5, color: AppTheme.txt3)),
                              trailing: city.downloaded
                                  ? IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 20),
                                      tooltip: '删除离线包',
                                      onPressed: () => _remove(city),
                                    )
                                  : city.downloading
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              width: 44,
                                              child: LinearProgressIndicator(
                                                value: city.percent / 100,
                                                minHeight: 4,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.close, size: 18),
                                              tooltip: '暂停',
                                              onPressed: _pause,
                                            ),
                                          ],
                                        )
                                      : IconButton(
                                          icon: const Icon(Icons.download_outlined, size: 20),
                                          tooltip: '下载离线地图',
                                          onPressed:
                                              _busyCity == null ? () => _download(city) : null,
                                        ),
                            );
                          },
                        ),
                ),
                const SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      '离线地图由高德 SDK 提供，下载后无网络也能查看该城市路网；'
                      '建议只下载常住城市以节省空间。',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: AppTheme.txt3),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
