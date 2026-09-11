import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' show LatLng, Distance, LengthUnit;

import '../../data/activity_repository.dart';
import '../../theme/app_theme.dart';

/// 海拔 / 速度曲线（原型 AD-04）：可切"时间轴 / 距离轴"。
/// 海拔画成浅色面积，速度画成折线；缺速度信息时用相邻点距离/时间推算。
class EleSpeedChart extends StatelessWidget {
  const EleSpeedChart({
    super.key,
    required this.points,
    required this.byDistance,
    this.height = 170,
  });

  final List<SimpleTrack> points;
  final bool byDistance;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return const SizedBox.shrink();
    }
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.line),
      ),
      child: CustomPaint(
        painter: _ChartPainter(points: points, byDistance: byDistance),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({required this.points, required this.byDistance});

  final List<SimpleTrack> points;
  final bool byDistance;

  @override
  void paint(Canvas canvas, Size size) {
    const padL = 8.0, padR = 8.0, padT = 22.0, padB = 20.0;
    final w = size.width - padL - padR;
    final h = size.height - padT - padB;
    if (w <= 0 || h <= 0) return;

    // ---- 计算 X（时间秒 或 累计距离米）与两条曲线 ----
    const d = Distance();
    final xs = <double>[0];
    final speeds = <double>[0];
    final eles = <double>[points.first.altM ?? 0];
    var accM = 0.0;
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1], cur = points[i];
      final segM = d.as(LengthUnit.Meter, LatLng(prev.lat, prev.lon), LatLng(cur.lat, cur.lon));
      accM += segM;
      xs.add(byDistance
          ? accM
          : (cur.tMs - points.first.tMs) / 1000.0);
      final dtSec = (cur.tMs - prev.tMs) / 1000.0;
      final spd = cur.speedMps != null
          ? cur.speedMps!
          : (dtSec > 0 ? segM / dtSec : 0.0);
      speeds.add(spd * 3.6); // km/h
      eles.add(cur.altM ?? eles.last);
    }
    final xMax = xs.last <= 0 ? 1.0 : xs.last;

    double maxEle = eles.reduce(math.max);
    double minEle = eles.reduce(math.min);
    if (maxEle - minEle < 1) {
      maxEle += 1;
      minEle -= 1;
    }
    final maxSpd = math.max(speeds.reduce(math.max), 1.0);

    double xp(double x) => padL + (x / xMax) * w;
    double yp(double v, double lo, double hi) =>
        padT + h - ((v - lo) / (hi - lo)) * h;

    // ---- 网格 ----
    final grid = Paint()
      ..color = AppTheme.line
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = padT + h * i / 3;
      canvas.drawLine(Offset(padL, y), Offset(size.width - padR, y), grid);
    }

    // ---- 海拔面积 ----
    final elePath = Path()..moveTo(xp(xs[0]), yp(eles[0], minEle, maxEle));
    for (var i = 1; i < points.length; i++) {
      elePath.lineTo(xp(xs[i]), yp(eles[i], minEle, maxEle));
    }
    final eleFill = Path.from(elePath)
      ..lineTo(xp(xs.last), padT + h)
      ..lineTo(xp(xs[0]), padT + h)
      ..close();
    canvas.drawPath(eleFill, Paint()..color = AppTheme.accent.withValues(alpha: 0.14));
    canvas.drawPath(
      elePath,
      Paint()
        ..color = AppTheme.accent.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // ---- 速度折线 ----
    final spdPath = Path()..moveTo(xp(xs[0]), yp(speeds[0], 0, maxSpd));
    for (var i = 1; i < points.length; i++) {
      spdPath.lineTo(xp(xs[i]), yp(speeds[i], 0, maxSpd));
    }
    canvas.drawPath(
      spdPath,
      Paint()
        ..color = AppTheme.accentInk
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeJoin = StrokeJoin.round,
    );

    // ---- 标注 ----
    void label(String text, Offset at, {TextAlign align = TextAlign.left, Color? color}) {
      final tp = TextPainter(
        text: TextSpan(
            text: text,
            style: TextStyle(fontSize: 10, color: color ?? AppTheme.txt3)),
        textDirection: TextDirection.ltr,
        textAlign: align,
      )..layout();
      tp.paint(canvas, at);
    }

    label('海拔 ${minEle.round()}~${maxEle.round()} m', const Offset(padL, 4));
    label('速度峰值 ${maxSpd.toStringAsFixed(1)} km/h',
        Offset(size.width - padR - 100, 4), color: AppTheme.accentInk);
    label(byDistance
        ? '0 km'
        : '0:00', Offset(padL, size.height - padB + 4));
    label(
      byDistance
          ? '${(xMax / 1000).toStringAsFixed(1)} km'
          : _fmtSec(xMax.toInt()),
      Offset(size.width - padR - 44, size.height - padB + 4),
    );
  }

  static String _fmtSec(int s) {
    final h = s ~/ 3600, m = (s % 3600) ~/ 60, sec = s % 60;
    String p(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '${p(h)}:${p(m)}:${p(sec)}' : '${p(m)}:${p(sec)}';
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.points != points || old.byDistance != byDistance;
}
