import 'package:flutter_test/flutter_test.dart';

import 'package:basho/data/activity_repository.dart';
import 'package:basho/data/gpx.dart';

void main() {
  final pts = <SimpleTrack>[
    SimpleTrack(tMs: 1700000000000, lat: 22.5310, lon: 113.9300, altM: 10, speedMps: 5),
    SimpleTrack(tMs: 1700000010000, lat: 22.5320, lon: 113.9310, altM: 25, speedMps: 6),
    SimpleTrack(tMs: 1700000020000, lat: 22.5335, lon: 113.9325, altM: 20, speedMps: 4),
  ];

  test('GPX 序列化包含轨迹点/海拔/时间', () {
    final xml = Gpx.build(name: '晨骑 & 测试', points: pts);
    expect(xml.contains('<gpx'), isTrue);
    expect(xml.contains('lat="22.5310000"'), isTrue);
    expect(xml.contains('<ele>10.0</ele>'), isTrue);
    expect(xml.contains('<time>2023-11-14T22:13:20.000Z</time>'), isTrue);
    expect(xml.contains('晨骑 &amp; 测试'), isTrue); // 名称转义
  });

  test('GPX 往返：导出后再解析，坐标/海拔/时间一致', () {
    final xml = Gpx.build(name: '往返', points: pts);
    final back = Gpx.parse(xml);
    expect(back.length, pts.length);
    for (var i = 0; i < pts.length; i++) {
      expect(back[i].lat, closeTo(pts[i].lat, 1e-6));
      expect(back[i].lon, closeTo(pts[i].lon, 1e-6));
      expect(back[i].altM, closeTo(pts[i].altM!, 0.2));
      expect(back[i].tMs, pts[i].tMs);
    }
  });

  test('统计：累计距离与正爬升', () {
    final (km, elev) = Gpx.stats(pts);
    expect(km, greaterThan(0.3)); // 约 0.35km
    expect(km, lessThan(0.45));
    expect(elev, closeTo(15, 0.01)); // 10→25 计 15，25→20 不计
  });

  test('解析缺少时间的 GPX：按顺序补 1 秒且排序', () {
    const xml = '''
<gpx version="1.1" creator="t"><trk><trkseg>
<trkpt lat="22.5" lon="113.9"><ele>5</ele></trkpt>
<trkpt lat="22.6" lon="114.0"><ele>8</ele></trkpt>
</trkseg></trk></gpx>''';
    final out = Gpx.parse(xml);
    expect(out.length, 2);
    expect(out[1].tMs - out[0].tMs, 1000);
  });
}
