import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart' show LatLng, Distance, LengthUnit;

import 'package:basho/data/route_planner.dart';

void main() {
  const d = Distance();

  test('WGS84 → GCJ-02 有明显偏移（说明纠偏生效）', () {
    const wgs = LatLng(22.5310, 113.9300); // 深圳前海附近
    final gcj = wgs84ToGcj02(wgs);
    final off = d.as(LengthUnit.Meter, wgs, gcj);
    expect(off, greaterThan(100));
    expect(off, lessThan(1200));
  });

  test('WGS84 → GCJ-02 → WGS84 往返误差很小（<5m）', () {
    const wgs = LatLng(22.5310, 113.9300);
    final back = gcj02ToWgs84(wgs84ToGcj02(wgs));
    expect(d.as(LengthUnit.Meter, wgs, back), lessThan(5));
  });

  test('境外坐标不做偏移', () {
    const tokyo = LatLng(35.6812, 139.7671);
    final out = wgs84ToGcj02(tokyo);
    expect(out.latitude, closeTo(tokyo.latitude, 1e-9));
    expect(out.longitude, closeTo(tokyo.longitude, 1e-9));
  });
}
