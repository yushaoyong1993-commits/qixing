import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:latlong2/latlong.dart' show LatLng, Distance, LengthUnit;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:xml/xml.dart';

import 'activity_repository.dart';

/// GPX 读写（纯 Dart，便于单测）：导出轨迹为 .gpx、解析 .gpx 为轨迹点。
class Gpx {
  /// 生成 GPX 文本（轨迹点坐标为 WGS84，与 GPX/码表一致）。
  static String build({
    required String name,
    required List<SimpleTrack> points,
    String creator = 'basho',
  }) {
    final b = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln('<gpx version="1.1" creator="$creator" '
          'xmlns="http://www.topografix.com/GPX/1/1">')
      ..writeln('  <trk>')
      ..writeln('    <name>${_esc(name)}</name>')
      ..writeln('    <trkseg>');
    for (final p in points) {
      b.write('      <trkpt lat="${p.lat.toStringAsFixed(7)}" '
          'lon="${p.lon.toStringAsFixed(7)}">');
      if (p.altM != null && p.altM!.isFinite) {
        b.write('<ele>${p.altM!.toStringAsFixed(1)}</ele>');
      }
      b.write('<time>${_iso(p.tMs)}</time>');
      b.write('</trkpt>\n');
    }
    b
      ..writeln('    </trkseg>')
      ..writeln('  </trk>')
      ..writeln('</gpx>');
    return b.toString();
  }

  /// 解析 GPX 文本 → 轨迹点（按时间排序；缺失时间时按顺序自增 1 秒）。
  static List<SimpleTrack> parse(String xmlText) {
    final doc = XmlDocument.parse(xmlText);
    final nodes = doc.findAllElements('trkpt').toList();
    final out = <SimpleTrack>[];
    var fallbackMs = DateTime.now().millisecondsSinceEpoch;
    for (final n in nodes) {
      final lat = double.tryParse(n.getAttribute('lat') ?? '');
      final lon = double.tryParse(n.getAttribute('lon') ?? '');
      if (lat == null || lon == null) continue;
      double? ele;
      final eleNode = n.getElement('ele');
      if (eleNode != null) ele = double.tryParse(eleNode.innerText.trim());
      int tMs = fallbackMs;
      final timeNode = n.getElement('time');
      if (timeNode != null) {
        final parsed = DateTime.tryParse(timeNode.innerText.trim());
        if (parsed != null) tMs = parsed.millisecondsSinceEpoch;
      } else {
        fallbackMs += 1000;
        tMs = fallbackMs;
      }
      out.add(SimpleTrack(
        tMs: tMs,
        lat: lat,
        lon: lon,
        altM: ele,
        speedMps: null,
      ));
    }
    out.sort((a, b) => a.tMs.compareTo(b.tMs));
    return out;
  }

  /// 轨迹点累计距离（km）与正爬升（m）。
  static (double km, double elevM) stats(List<SimpleTrack> pts) {
    const d = Distance();
    var m = 0.0, up = 0.0;
    for (var i = 1; i < pts.length; i++) {
      m += d.as(LengthUnit.Meter, LatLng(pts[i - 1].lat, pts[i - 1].lon),
          LatLng(pts[i].lat, pts[i].lon));
      final a = pts[i - 1].altM, b = pts[i].altM;
      if (a != null && b != null && b > a) up += b - a;
    }
    return (m / 1000, up);
  }

  static String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  static String _iso(int ms) =>
      DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toIso8601String();
}

/// 文件级别的导入/导出（依赖插件，无法单测的部分隔离在这里）。
class GpxIo {
  /// 把轨迹导出为 .gpx 并调起系统分享
  static Future<void> exportAndShare({
    required String fileName,
    required List<SimpleTrack> points,
    String? text,
  }) async {
    final gpx = Gpx.build(name: fileName, points: points);
    final dir = await getApplicationDocumentsDirectory();
    final outDir = Directory('${dir.path}/exports');
    if (!await outDir.exists()) await outDir.create(recursive: true);
    final safe = fileName.replaceAll(RegExp(r'[^\w\u4e00-\u9fa5\-]+'), '_');
    final file = File('${outDir.path}/$safe.gpx');
    await file.writeAsString(gpx, encoding: utf8);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path, mimeType: 'application/gpx+xml')], text: text),
    );
  }

  /// 导出单个活动的轨迹
  static Future<int> exportActivity({
    required ActivityRepository repo,
    required int rideId,
    required String name,
  }) async {
    final pts = await repo.trackPointsFor(rideId);
    await exportAndShare(
      fileName: name,
      points: pts,
      text: '$name · 跋涉导出',
    );
    return pts.length;
  }

  /// 导出全部有轨迹的活动
  static Future<int> exportAllActivityIds({
    required ActivityRepository repo,
    required List<(int id, String name)> items,
  }) async {
    final files = <XFile>[];
    final dir = await getApplicationDocumentsDirectory();
    final outDir = Directory('${dir.path}/exports');
    if (!await outDir.exists()) await outDir.create(recursive: true);
    for (final it in items) {
      final pts = await repo.trackPointsFor(it.$1);
      if (pts.length < 2) continue;
      final safe = it.$2.replaceAll(RegExp(r'[^\w\u4e00-\u9fa5\-]+'), '_');
      final f = File('${outDir.path}/$safe.gpx');
      await f.writeAsString(Gpx.build(name: it.$2, points: pts), encoding: utf8);
      files.add(XFile(f.path, mimeType: 'application/gpx+xml'));
    }
    if (files.isEmpty) return 0;
    await SharePlus.instance.share(
      ShareParams(files: files, text: '跋涉导出的 GPX（共 ${files.length} 个）'),
    );
    return files.length;
  }

  /// 选择并导入一个 .gpx（新建活动 + 轨迹点）
  static Future<(int id, String name, int points)?> importGpx(
      ActivityRepository repo) async {
    final picked = await pickGpx();
    if (picked == null) return null;
    final pts = Gpx.parse(picked.$2);
    if (pts.length < 2) return null;
    final (km, elev) = Gpx.stats(pts);
    final startAt = DateTime.fromMillisecondsSinceEpoch(pts.first.tMs);
    final endAt = DateTime.fromMillisecondsSinceEpoch(pts.last.tMs);
    var movingS = endAt.difference(startAt).inSeconds;
    if (movingS <= 0) movingS = pts.length; // 无时间信息时按每秒 1 点估算
    final baseName = picked.$1.replaceAll(RegExp(r'\.gpx\$', caseSensitive: false), '');
    final id = await repo.saveRide(
      name: baseName.isEmpty ? '导入骑行' : baseName,
      type: '导入',
      startAt: startAt,
      durationS: movingS,
      movingS: movingS,
      distanceM: km * 1000,
      elevGainM: elev,
      elevLossM: 0,
      hrAvg: null,
      hrMax: null,
      kcal: (km * 24).round(),
    );
    await repo.saveTrackPoints(id, pts);
    return (id, baseName, pts.length);
  }

  /// 选择一个 .gpx 文件并返回其内容
  static Future<(String name, String content)?> pickGpx() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['gpx'],
    );
    if (files.isEmpty) return null;
    final f = files.first;
    final content = utf8.decode(await f.readAsBytes(), allowMalformed: true);
    return (f.name, content);
  }
}
