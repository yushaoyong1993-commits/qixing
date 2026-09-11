/// 记录会话状态机（纯 Dart，无 IO/无 Flutter 依赖）。
/// 对应《骑行App_记录PRD_v1.1.md》§2：准备页 → 记录中 ↔ 已暂停 → 摘要 → 保存/丢弃。
/// 规则：全 App 同一时刻最多一个进行中会话；暂停不计移动时长；**暂停不封圈**。
library;

enum SessionPhase { idle, recording, paused, summary }

/// 一圈（分段）的统计快照。时间均为"会话开始起的 elapsed 秒"。
class LapSplit {
  const LapSplit({
    required this.index,
    required this.startSec,
    required this.endSec,
    required this.distanceKm,
    required this.movingSec,
    required this.elevGainM,
  });

  final int index;
  final int startSec;
  final int endSec;
  final double distanceKm;
  final int movingSec;
  final double elevGainM;

  /// 圈均速（只按移动时长算）
  double get avgKmh => movingSec > 0 ? distanceKm / (movingSec / 3600) : 0;
}

class SessionMachine {
  /// 误触过滤：手动计圈时若该圈"距离 < 100m 且时长 < 10s"则忽略。
  static const double minLapKm = 0.1;
  static const int minLapSec = 10;

  SessionPhase _phase = SessionPhase.idle;
  double _distanceKm = 0;
  double _elevGainM = 0;
  int _movingSec = 0;
  int _elapsedSec = 0; // 含暂停的总时长
  bool _autoPause = true;
  double _autoLapKm = 0; // 0 = 关闭自动计圈

  final List<LapSplit> _laps = [];

  // 当前圈（进行中）的起点基线
  int _lapStartSec = 0;
  double _lapStartDist = 0;
  int _lapStartMoving = 0;
  double _lapStartElev = 0;

  /// 草稿恢复时保留的"历史圈数"（无明细）
  int _restoredLaps = 0;

  SessionPhase get phase => _phase;
  double get distanceKm => _distanceKm;
  double get elevGainM => _elevGainM;
  int get movingSec => _movingSec;
  int get elapsedSec => _elapsedSec;
  bool get autoPause => _autoPause;
  double get autoLapKm => _autoLapKm;
  bool get isActive =>
      _phase == SessionPhase.recording || _phase == SessionPhase.paused;

  /// 已完成圈数
  int get lapCount => _restoredLaps + _laps.length;

  /// 当前（进行中）圈号，从 1 起
  int get currentLap => lapCount + 1;

  /// 已完成圈明细
  List<LapSplit> get laps => List.unmodifiable(_laps);

  /// 当前圈已骑距离
  double get currentLapDistanceKm => _distanceKm - _lapStartDist;

  /// 当前圈移动时长
  int get currentLapMovingSec => _movingSec - _lapStartMoving;

  /// 当前圈均速
  double get currentLapAvgKmh => currentLapMovingSec > 0
      ? currentLapDistanceKm / (currentLapMovingSec / 3600)
      : 0;

  /// 尝试开始记录；会话中返回 false（防双会话，UI 据此提示）。
  /// [autoLapKm] > 0 时按移动距离自动计圈（默认 0 关闭）。
  bool start({bool autoPause = true, double autoLapKm = 0}) {
    if (isActive || _phase == SessionPhase.summary) return false;
    _phase = SessionPhase.recording;
    _autoPause = autoPause;
    _autoLapKm = autoLapKm;
    _resetLapAnchor();
    return true;
  }

  /// 草稿恢复：跳过 idle 继续记录（圈明细不可恢复，只保留圈数）。
  void restore({
    required double distanceKm,
    required int movingSec,
    int laps = 0,
    bool autoPause = true,
    double autoLapKm = 0,
  }) {
    _phase = SessionPhase.recording;
    _distanceKm = distanceKm;
    _movingSec = movingSec;
    _elapsedSec = movingSec;
    _restoredLaps = laps;
    _autoPause = autoPause;
    _autoLapKm = autoLapKm;
    _resetLapAnchor();
  }

  bool pause() {
    if (_phase != SessionPhase.recording) return false;
    _phase = SessionPhase.paused;
    return true;
  }

  bool resume() {
    if (_phase != SessionPhase.paused) return false;
    _phase = SessionPhase.recording;
    return true;
  }

  /// 手动计圈：封口当前圈并开新圈。
  /// 若当前圈过短（<100m 且 <10s）视为误触 → 返回 false 且不封圈。
  bool lap() {
    if (!isActive) return false;
    return _sealLap(force: false);
  }

  /// 进入结束摘要（可由 recording/paused）：封口最后一圈。
  bool finish() {
    if (!isActive) return false;
    _sealLap(force: false, allowTiny: true); // 最后一圈即使很短也保留
    _phase = SessionPhase.summary;
    return true;
  }

  /// 摘要阶段选择"再骑一段"：回到记录中，已录数据保留。
  bool resumeFromSummary() {
    if (_phase != SessionPhase.summary) return false;
    _phase = SessionPhase.recording;
    _resetLapAnchor();
    return true;
  }

  void discard() {
    _phase = SessionPhase.idle;
    _distanceKm = 0;
    _elevGainM = 0;
    _movingSec = 0;
    _elapsedSec = 0;
    _restoredLaps = 0;
    _laps.clear();
    _resetLapAnchor();
  }

  /// 秒表推进（由 UI 的每秒计时器驱动，**与 GPS 无关**）：
  /// 记录中：总时长与移动时长都走；暂停中：只有总时长走（暂停不封圈）。
  void tickSec([int seconds = 1]) {
    if (_phase == SessionPhase.idle || _phase == SessionPhase.summary) return;
    _elapsedSec += seconds;
    if (_phase == SessionPhase.recording) _movingSec += seconds;
  }

  /// 采纳一个"真实采样"（由位置流驱动）：只累加距离与正爬升；顺带判断自动计圈。
  void addSample({required double distKm, double elevM = 0}) {
    if (_phase != SessionPhase.recording) return;
    _distanceKm += distKm;
    if (elevM > 0) _elevGainM += elevM;
    if (_autoLapKm > 0 && (_distanceKm - _lapStartDist) >= _autoLapKm) {
      _sealLap(force: true);
    }
  }

  /// 周期性推进（模拟用：无真实定位时按速度估算）。真实定位请用 [addSample]。
  void advance({required double dtSec, required double speedKmh, bool stopped = false}) {
    if (_phase != SessionPhase.recording) return;
    if (_autoPause && stopped) {
      _phase = SessionPhase.paused;
      return;
    }
    _movingSec += dtSec.round();
    _elapsedSec += dtSec.round();
    _distanceKm += speedKmh * dtSec / 3600;
    if (_autoLapKm > 0 && (_distanceKm - _lapStartDist) >= _autoLapKm) {
      _sealLap(force: true);
    }
  }

  // ---------- 内部 ----------

  void _resetLapAnchor() {
    _lapStartSec = _elapsedSec;
    _lapStartDist = _distanceKm;
    _lapStartMoving = _movingSec;
    _lapStartElev = _elevGainM;
  }

  bool _sealLap({required bool force, bool allowTiny = false}) {
    final dist = _distanceKm - _lapStartDist;
    final mov = _movingSec - _lapStartMoving;
    final elev = _elevGainM - _lapStartElev;
    if (!force && !allowTiny && dist < minLapKm && mov < minLapSec) {
      return false; // 误触过滤：不封圈
    }
    if (allowTiny && dist <= 0 && mov <= 0) return false; // 空圈不留
    _laps.add(LapSplit(
      index: _laps.length + 1,
      startSec: _lapStartSec,
      endSec: _elapsedSec,
      distanceKm: dist,
      movingSec: mov,
      elevGainM: elev,
    ));
    _resetLapAnchor();
    return true;
  }
}
