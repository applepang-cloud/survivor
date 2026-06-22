import 'package:flame_audio/flame_audio.dart';

/// 효과음 관리 — 원작엔 없어 직접 합성한 WAV(assets/audio) 재생.
/// 자주 울리는 소리는 쓰로틀, 음소거 토글 지원.
class GameAudio {
  bool enabled = true;
  final Stopwatch _sw = Stopwatch()..start();
  final Map<String, int> _last = {};

  static const _files = [
    'levelup.wav',
    'hit.wav',
    'gameover.wav',
    'item.wav',
    'pickup.wav',
    'shoot.wav',
  ];

  Future<void> preload() async {
    try {
      await FlameAudio.audioCache.loadAll(_files);
    } catch (_) {
      // 로드 실패해도 게임 진행에는 지장 없음
    }
  }

  void _play(String file, double volume, {int throttleMs = 0}) {
    if (!enabled) return;
    if (throttleMs > 0) {
      final now = _sw.elapsedMilliseconds;
      if ((_last[file] ?? -99999) + throttleMs > now) return;
      _last[file] = now;
    }
    try {
      FlameAudio.play(file, volume: volume);
    } catch (_) {}
  }

  void levelup() => _play('levelup.wav', 0.6);
  void hit() => _play('hit.wav', 0.5, throttleMs: 120);
  void gameover() => _play('gameover.wav', 0.7);
  void item() => _play('item.wav', 0.6);
  void pickup() => _play('pickup.wav', 0.22, throttleMs: 55);
  void shoot() => _play('shoot.wav', 0.16, throttleMs: 110);
}
