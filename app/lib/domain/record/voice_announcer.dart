import 'package:flutter_tts/flutter_tts.dart';

/// 语音播报（系统 TTS，离线可用）。用于骑行中每公里播报与结束总结。
class VoiceAnnouncer {
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  bool get ready => _ready;

  Future<void> init() async {
    if (_ready) return;
    try {
      await _tts.setLanguage('zh-CN');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _ready = true;
    } catch (_) {
      // 系统无 TTS 引擎/中文语音包时静默降级
      _ready = false;
    }
  }

  Future<void> say(String text) async {
    if (!_ready) return;
    try {
      await _tts.speak(text);
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
