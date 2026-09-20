import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/units.dart';

/// 轨迹分享卡：把一个活动的轨迹形状 + 关键数据渲染成一张可直接分享的图片。
///
/// 导出方式：把本组件放进 [RepaintBoundary]，用 [GlobalKey] 抓取渲染结果转 PNG
/// （见 [ShareCardPage]），再交给 share_plus 分享。
class TrackShareCard extends StatelessWidget {
  const TrackShareCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.path,
    required this.stats,
    this.size = const Size(360, 450),
  });

  final String title;
  final String subtitle;

  /// 轨迹点：[[lng, lat], ...]（GCJ-02/WGS84 均可，画形状不需要坐标系）
  final List<List<double>> path;

  /// 底部数据条目：[(标签, 值), ...]
  final List<(String, String)> stats;
  final Size size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B1D23), Color(0xFF2A2D36), Color(0xFF15171C)],
        ),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.directions_bike, size: 18, color: Color(0xFFFC4C02)),
              SizedBox(width: 6),
              Text('跋涉 · 骑行记录',
                  style: TextStyle(fontSize: 12, color: Color(0xFFB9BCC6), letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(subtitle,
              style: const TextStyle(fontSize: 12, color: Color(0xFF9AA0AC))),
          const SizedBox(height: 14),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                color: const Color(0xFF11131A),
                padding: const EdgeInsets.all(10),
                child: CustomPaint(
                  painter: _TrackPainter(path),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < stats.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stats[i].$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      const SizedBox(height: 2),
                      Text(stats[i].$1,
                          style: const TextStyle(
                              fontSize: 10.5, color: Color(0xFF8E94A0))),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _TrackPainter extends CustomPainter {
  _TrackPainter(this.path);

  final List<List<double>> path;

  @override
  void paint(Canvas canvas, Size size) {
    if (path.length < 2) {
      final tp = TextPainter(
        text: const TextSpan(
          text: '本次没有轨迹点',
          style: TextStyle(color: Color(0xFF666C78), fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2));
      return;
    }

    // 归一化到画布（保持长宽比，居中）
    var minLng = path.first[0], maxLng = minLng;
    var minLat = path.first[1], maxLat = minLat;
    for (final p in path) {
      minLng = math.min(minLng, p[0]);
      maxLng = math.max(maxLng, p[0]);
      minLat = math.min(minLat, p[1]);
      maxLat = math.max(maxLat, p[1]);
    }
    final spanLng = math.max(maxLng - minLng, 1e-6);
    final spanLat = math.max(maxLat - minLat, 1e-6);
    const pad = 16.0;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;
    final scale = math.min(w / spanLng, h / spanLat);
    final dx = pad + (w - spanLng * scale) / 2;
    final dy = pad + (h - spanLat * scale) / 2;

    Offset toPx(List<double> p) => Offset(
          dx + (p[0] - minLng) * scale,
          // 纬度向上增大 → 屏幕 y 反向
          dy + (maxLat - p[1]) * scale,
        );

    final line = Path()..moveTo(toPx(path.first).dx, toPx(path.first).dy);
    for (final p in path.skip(1)) {
      final o = toPx(p);
      line.lineTo(o.dx, o.dy);
    }

    // 轨迹主体（带外发光，视觉更醒目）
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0x33FC4C02),
    );
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFFFC4C02),
    );

    // 起点 / 终点
    final start = toPx(path.first);
    final end = toPx(path.last);
    canvas.drawCircle(start, 6, Paint()..color = const Color(0xFF2ECC71));
    canvas.drawCircle(start, 3, Paint()..color = Colors.white);
    canvas.drawCircle(end, 7, Paint()..color = const Color(0xFFFC4C02));
    canvas.drawCircle(end, 3.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _TrackPainter old) => old.path != path;
}

/// 分享图预览页：卡片预览 + 一键导出 PNG 并分享
class ShareCardPage extends StatefulWidget {
  const ShareCardPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.path,
    required this.stats,
    this.shareText = '用「跋涉」记录的骑行',
  });

  final String title;
  final String subtitle;
  final List<List<double>> path;
  final List<(String, String)> stats;
  final String shareText;

  @override
  State<ShareCardPage> createState() => _ShareCardPageState();
}

class _ShareCardPageState extends State<ShareCardPage> {
  final GlobalKey _cardKey = GlobalKey();
  bool _busy = false;

  Future<void> _share() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final file = await renderAndShare(
        cardKey: _cardKey,
        fileName: 'basho-share',
        shareText: widget.shareText,
      );
      if (!mounted) return;
      if (file == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('生成分享图失败，请重试', textAlign: TextAlign.center),
        ));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1015),
      appBar: AppBar(
        title: const Text('分享骑行'),
        backgroundColor: const Color(0xFF0E1015),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: FittedBox(
                child: RepaintBoundary(
                  key: _cardKey,
                  child: TrackShareCard(
                    title: widget.title,
                    subtitle: widget.subtitle,
                    path: widget.path,
                    stats: widget.stats,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _share,
                  icon: _busy
                      ? const SizedBox(
                          width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.ios_share),
                  label: Text(_busy ? '生成中…' : '分享图片'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 把 RepaintBoundary 渲染成 PNG 文件并调起分享；返回生成的文件（失败返回 null）。
Future<File?> renderAndShare({
  required GlobalKey cardKey,
  required String fileName,
  required String shareText,
  double pixelRatio = 3,
}) async {
  try {
    final obj = cardKey.currentContext?.findRenderObject();
    if (obj is! RenderRepaintBoundary) return null;
    final ui.Image image = await obj.toImage(pixelRatio: pixelRatio);
    final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) return null;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName-${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        text: shareText,
      ),
    );
    return file;
  } catch (_) {
    return null;
  }
}

/// 便捷构造：从活动数据生成分享卡所需的数据条目（按单位偏好格式化）
List<(String, String)> buildShareStats({
  required double distanceKm,
  required double durationMin,
  required double elevGainM,
  required UnitPrefs u,
}) {
  final avgSpeed = durationMin > 0 ? distanceKm / (durationMin / 60) : 0.0;
  return [
    ('距离', u.dist(distanceKm)),
    ('时长', _fmtMin(durationMin)),
    ('均速', u.speed(avgSpeed)),
    ('爬升', u.elev(elevGainM)),
  ];
}

String _fmtMin(double minutes) {
  final total = minutes.round();
  final h = total ~/ 60;
  final m = total % 60;
  if (h == 0) return '$m分';
  return '$h小时${m.toString().padLeft(2, '0')}分';
}
