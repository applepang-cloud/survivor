import 'package:flame_audio/flame_audio.dart';

/// 효과음/BGM 관리 — 원작엔 사운드가 없어 직접 합성한 WAV(assets/audio) 재생.
/// 자주 울리는 소리는 쓰로틀, 음소거 토글 지원. BGM은 루프 재생.
class GameAudio {
  bool enabled = true;
  final Stopwatch _sw = Stopwatch()..start();
  final Map<String, int> _last = {};

  bool _bgmWanted = false; // 게임 진행 중인가 (재생되어야 하는 상태)
  bool _bgmHeld = false; // 일시정지로 잠시 멈춘 상태

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

  // ---- BGM ----
  void startBgm() {
    _bgmWanted = true;
    _bgmHeld = false;
    if (!enabled) return;
    try {
      FlameAudio.bgm.play('bgm.wav', volume: 0.35).catchError((_) {});
    } catch (_) {}
  }

  void stopBgm() {
    _bgmWanted = false;
    try {
      FlameAudio.bgm.stop().catchError((_) {});
    } catch (_) {}
  }

  void pauseBgm() {
    _bgmHeld = true;
    try {
      FlameAudio.bgm.pause().catchError((_) {});
    } catch (_) {}
  }

  void resumeBgm() {
    _bgmHeld = false;
    if (!enabled || !_bgmWanted) return;
    try {
      FlameAudio.bgm.resume().catchError((_) {});
    } catch (_) {}
  }

  /// 음소거 토글 — BGM도 함께 멈추고 다시 켜면 이어 재생
  void setEnabled(bool v) {
    enabled = v;
    try {
      if (!v) {
        FlameAudio.bgm.pause().catchError((_) {});
      } else if (_bgmWanted && !_bgmHeld) {
        // resume이 안 먹는 상태(음소거 중 시작)면 새로 재생
        FlameAudio.bgm.play('bgm.wav', volume: 0.35).catchError((_) {});
      }
    } catch (_) {}
  }

  // ---- SFX ----
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
