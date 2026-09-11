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

}
