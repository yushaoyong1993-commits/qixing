/// 记录会话状态机（纯 Dart，无 IO/无 Flutter 依赖）。
/// 对应《骑行App_记录PRD_v1.1.md》§2：准备页 → 记录中 ↔ 已暂停 → 摘要 → 保存/丢弃。
/// 规则：全 App 同一时刻最多一个进行中会话；暂停不计移动时长。
library;

enum SessionPhase { idle, recording, paused, summary }

class SessionMachine {
  SessionPhase _phase = SessionPhase.idle;
  double _distanceKm = 0;
  double _elevGainM = 0;
  int _movingSec = 0;
  int _lapCount = 0;
  bool _autoPause = true;

  SessionPhase get phase => _phase;
  double get distanceKm => _distanceKm;
  double get elevGainM => _elevGainM;
  int get movingSec => _movingSec;
  int get lapCount => _lapCount;
  bool get autoPause => _autoPause;
  bool get isActive =>
      _phase == SessionPhase.recording || _phase == SessionPhase.paused;
  /// 当前圈号（从 1 起）。
  int get currentLap => _lapCount + 1;

  /// 尝试开始记录；会话中返回 false（防双会话，UI 据此提示）。
  bool start({bool autoPause = true}) {
    if (isActive || _phase == SessionPhase.summary) return false;
    _phase = SessionPhase.recording;
    _autoPause = autoPause;
    return true;
  }

  /// 记录草稿恢复时使用：跳过 idle，恢复已录数据继续。
  void restore({required double distanceKm, required int movingSec, int laps = 0}) {
    _phase = SessionPhase.recording;
    _distanceKm = distanceKm;
    _movingSec = movingSec;
    _lapCount = laps;
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

  bool lap() {
    if (!isActive) return false;
    _lapCount++;
    return true;
  }

  /// 进入结束摘要（可由 recording/paused）。
  bool finish() {
    if (!isActive) return false;
    _phase = SessionPhase.summary;
    return true;
  }

  /// 摘要阶段选择"再骑一段"：回到记录中，已录数据保留。
  bool resumeFromSummary() {
    if (_phase != SessionPhase.summary) return false;
    _phase = SessionPhase.recording;
    return true;
  }

  void discard() {
    _phase = SessionPhase.idle;
    _distanceKm = 0;
    _elevGainM = 0;
    _movingSec = 0;
    _lapCount = 0;
  }

  /// 秒表推进（由 UI 的每秒计时器驱动，**与 GPS 无关**）：
  /// 这样即使没有定位/室内无信号，记录时长也正常走。
  void tickSec([int seconds = 1]) {
    if (_phase != SessionPhase.recording) return;
    _movingSec += seconds;
  }

  /// 采纳一个"真实采样"（由位置流驱动）：只累加距离与正爬升。
  /// 时长一律由 [tickSec] 负责，避免无 GPS 时时间不走、或有 GPS 时重复计时。
  void addSample({required double distKm, double elevM = 0}) {
    if (_phase != SessionPhase.recording) return;
    _distanceKm += distKm;
    if (elevM > 0) _elevGainM += elevM;
  }

  /// 周期性推进（模拟用：无真实定位时按速度估算）。真实定位请用 [addSample]。
  void advance({required double dtSec, required double speedKmh, bool stopped = false}) {
    if (_phase != SessionPhase.recording) return;
    if (_autoPause && stopped) {
      _phase = SessionPhase.paused;
      return;
    }
    _movingSec += dtSec.round();
    _distanceKm += speedKmh * dtSec / 3600;
  }
}
