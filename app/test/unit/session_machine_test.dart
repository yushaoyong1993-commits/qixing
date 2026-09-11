import 'package:flutter_test/flutter_test.dart';

import 'package:basho/domain/record/session_machine.dart';

void main() {
  test('防双会话：进行中再次 start 返回 false', () {
    final m = SessionMachine();
    expect(m.start(), isTrue);
    expect(m.start(), isFalse);
    expect(m.phase, SessionPhase.recording);
  });

  test('暂停不计时，恢复后继续累计', () {
    final m = SessionMachine();
    m.start();
    m.advance(dtSec: 10, speedKmh: 30); // 83.3 m
    expect(m.movingSec, 10);
    m.pause();
    m.advance(dtSec: 999, speedKmh: 30); // 暂停中不累计
    expect(m.movingSec, 10);
    expect(m.phase, SessionPhase.paused);
    m.resume();
    m.advance(dtSec: 10, speedKmh: 30);
    expect(m.movingSec, 20);
    expect(m.distanceKm, closeTo(0.1667, 1e-3));
  });

  test('自动暂停：速度≈0 自动进入 paused，恢复继续', () {
    final m = SessionMachine();
    m.start();
    m.advance(dtSec: 5, speedKmh: 25, stopped: true);
    expect(m.phase, SessionPhase.paused);
    expect(m.movingSec, 0);
    m.resume();
    m.advance(dtSec: 5, speedKmh: 20);
    expect(m.movingSec, 5);
  });

  test('计圈与结束摘要流转', () {
    final m = SessionMachine();
    m.start();
    m.tickSec(60); // 满足"最短圈"要求（否则会被误触过滤）
    m.addSample(distKm: 1.0);
    expect(m.lap(), isTrue);
    expect(m.currentLap, 2);
    expect(m.finish(), isTrue);
    expect(m.phase, SessionPhase.summary);
    expect(m.pause(), isFalse); // summary 下不可暂停
    m.discard();
    expect(m.phase, SessionPhase.idle);
    expect(m.distanceKm, 0);
  });

  test('真实采样 addSample：累加距离/时长/正爬升，暂停不累计', () {
    final m = SessionMachine();
    m.start();
    m.tickSec(10);
    m.addSample(distKm: 0.1, elevM: 5);
    m.tickSec(10);
    m.addSample(distKm: 0.2, elevM: 3);
    expect(m.distanceKm, closeTo(0.3, 1e-9));
    expect(m.movingSec, 20); // 时长只由 tickSec 累加
    expect(m.elevGainM, closeTo(8, 1e-9));
    m.pause();
    m.tickSec(99);
    m.addSample(distKm: 99, elevM: 99);
    expect(m.distanceKm, closeTo(0.3, 1e-9));
    expect(m.movingSec, 20); // 暂停后秒表与采样都不累计
  });


  test('自动计圈：每满 5km 自动封一圈', () {
    final m = SessionMachine();
    m.start(autoLapKm: 5);
    for (var i = 0; i < 10; i++) {
      m.addSample(distKm: 0.6); // 累计 6.0km，跨过 5km
    }
    expect(m.laps.length, 1);
    // 自动计圈在"跨过阈值那一刻"封口：0.6×9 = 5.4km
    expect(m.laps.first.distanceKm, closeTo(5.4, 1e-9));
    expect(m.lapCount, 1);
    expect(m.currentLap, 2);
  });

  test('手动计圈：误触过滤（<100m 且 <10s 不封圈）', () {
    final m = SessionMachine();
    m.start();
    m.tickSec(5);
    m.addSample(distKm: 0.05); // 太短
    expect(m.lap(), isFalse);
    expect(m.laps, isEmpty);

    m.tickSec(30);
    m.addSample(distKm: 0.5);
    expect(m.lap(), isTrue);
    expect(m.laps.length, 1);
    expect(m.laps.first.distanceKm, closeTo(0.55, 1e-9));
  });

  test('暂停不封圈：总时长走、移动时长与圈不变；结束时封最后一圈', () {
    final m = SessionMachine();
    m.start();
    m.tickSec(60);
    m.addSample(distKm: 1.0);
    m.pause();
    m.tickSec(120); // 暂停 2 分钟
    expect(m.elapsedSec, 180);
    expect(m.movingSec, 60); // 暂停不计移动
    expect(m.laps, isEmpty); // 暂停不封圈
    m.resume();
    m.tickSec(30);
    m.addSample(distKm: 0.5);
    m.finish();
    expect(m.laps.length, 1);
    expect(m.laps.first.distanceKm, closeTo(1.5, 1e-9));
    expect(m.laps.first.movingSec, 90);
    expect(m.laps.first.endSec, 210);
  });

  test('圈均速按移动时长计算', () {
    final m = SessionMachine();
    m.start();
    m.tickSec(1800); // 30 分钟
    m.addSample(distKm: 10);
    m.finish();
    expect(m.laps.first.avgKmh, closeTo(20, 1e-6));
  });
}
