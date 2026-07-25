import 'dart:math' as math;
import 'package:flame/components.dart';

import 'data.dart';
import 'survivor_game.dart';
import 'mob.dart';

class SpawnRule {
  final String mobKey;
  final double gap; // 초
  final double expDrop;
  final double itemDrop;
  double timer = 0;
  SpawnRule(this.mobKey, this.gap, this.expDrop, this.itemDrop,
      {bool immediate = false}) {
    if (immediate) timer = gap; // 페이즈 진입 즉시 1회 스폰 (분보스용)
  }
}

/// VS_BALANCE.md의 10분 런 각본:
/// 계단식 커트라인(3분 스파이크) → 소강(5~7분) → 최대 물량(8분~) → 10분 사신.
/// + 스웜 러시(2분~, 35초 주기), 6분 포위 이벤트, 사신 예고·1분마다 추가.
class MobSpawner extends Component with HasGameReference<SurvivorGame> {
  List<SpawnRule> _rules = [];
  int _phase = -1;
  int reaperCount = 0;
  bool ringDone = false;
  double _swarmTimer = 0;

  bool get reaperSpawned => reaperCount > 0;

  late final double spawnRadius;

  MobSpawner() {
    // 고정 해상도 대각선 절반 (원작 getRandomPosition)
    spawnRadius = math.sqrt(1280 * 1280 + 720 * 720) / 2;
  }

  void reset() {
    _phase = -1;
    _rules = [];
    reaperCount = 0;
    ringDone = false;
    _swarmTimer = 0;
    _applyPhase(0);
    // 시작 시 즉시 한 마리 (원작 create()의 new Mob(...mob1...))
    _spawn('mob1', 0.9, 0.01);
  }

  /// 10분 각본. 페이즈 경계는 _phaseForTime 과 쌍.
  List<SpawnRule> _rulesForPhase(int phase) {
    switch (phase) {
      case 0: // 0:00~0:30 워밍업
        return [SpawnRule('mob1', 0.5, 0.9, 0.01)];
      case 1: // 0:30~2:00 램프업
        return [
          SpawnRule('mob1', 0.30, 0.9, 0.01),
          SpawnRule('mob2', 0.60, 0.8, 0.01),
        ];
      case 2: // 2:00~3:00 (스웜 러시 시작 구간)
        return [
          SpawnRule('mob2', 0.35, 0.8, 0.01),
          SpawnRule('mob3', 0.70, 0.7, 0.01),
        ];
      case 3: // 3:00~3:40 ★1차 커트라인: 약졸 대량 스파이크
        return [
          SpawnRule('mob1', 0.07, 0.8, 0.01),
          SpawnRule('mob2', 0.12, 0.7, 0.01),
        ];
      case 4: // 3:40~4:00 숨고르기
        return [SpawnRule('mob3', 0.40, 0.7, 0.01)];
      case 5: // 4:00~5:00 진화 게이트 개방 — 첫 분보스 즉시 등장
        return [
          SpawnRule('mob3', 0.30, 0.7, 0.01),
          SpawnRule('mob4', 0.60, 0.6, 0.01),
          SpawnRule('mobBoss', 60, 0.5, 0.01, immediate: true),
        ];
      case 6: // 5:00~7:00 ★소강: 느리고 튼튼한 몹 위주 (빌드 완성 구간)
        return [
          SpawnRule('mob4', 0.80, 0.6, 0.02),
          SpawnRule('mob5', 1.20, 0.5, 0.02),
        ];
      case 7: // 7:00~8:00 재상승 + 분보스
        return [
          SpawnRule('mob4', 0.35, 0.6, 0.01),
          SpawnRule('mob5', 0.50, 0.5, 0.01),
          SpawnRule('mobBoss', 60, 0.5, 0.01, immediate: true),
        ];
      case 8: // 8:00~9:30 ★최대 물량 (완성된 빌드의 불꽃놀이)
        return [
          SpawnRule('mob1', 0.15, 0.9, 0.01),
          SpawnRule('mob3', 0.18, 0.7, 0.01),
          SpawnRule('mob4', 0.20, 0.6, 0.01),
          SpawnRule('mob5', 0.25, 0.5, 0.01),
          SpawnRule('mobBoss', 45, 0.5, 0.01, immediate: true),
        ];
      default: // 9:30~ 피날레
        return [
          SpawnRule('mob5', 0.18, 0.5, 0.01),
          SpawnRule('mobBoss', 30, 0.5, 0.01, immediate: true),
        ];
    }
  }

  void _applyPhase(int phase) {
    if (phase == _phase) return;
    _phase = phase;
    _rules = _rulesForPhase(phase);
  }

  int _phaseForTime(double sec) {
    if (sec < 30) return 0;
    if (sec < 120) return 1;
    if (sec < 180) return 2;
    if (sec < 220) return 3;
    if (sec < 240) return 4;
    if (sec < 300) return 5;
    if (sec < 420) return 6;
    if (sec < 480) return 7;
    if (sec < 570) return 8;
    return 9;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isRunning) return;
    final t = game.elapsed;
    _applyPhase(_phaseForTime(t));
    for (final r in _rules) {
      r.timer += dt;
      if (r.timer >= r.gap) {
        r.timer = 0;
        _spawn(r.mobKey, r.expDrop, r.itemDrop);
      }
    }

    // ── 스웜 러시: 2:00부터 35초마다, 사신 직전(9:50)까지
    if (t >= 120 && t < 590) {
      _swarmTimer += dt;
      if (_swarmTimer >= 35) {
        _swarmTimer = 0;
        spawnSwarm();
      }
    }

    // ── 포위 이벤트: 6:00 1회 (소강 한복판의 동선 검사)
    if (!ringDone && t >= 360) {
      ringDone = true;
      spawnRing();
    }

    // ── 사신 예고: 9:50
    if (!game.reaperWarned && t >= 590) {
      game.reaperWarned = true;
      game.showBanner('☠ 무언가 무시무시한 것이 다가온다...', 5);
    }

    // ── 사신: 10:00 등장, 이후 1분마다 1마리 추가 (VS 규칙)
    while (t >= 600 + reaperCount * 60) {
      _spawnReaper();
      reaperCount++;
      if (reaperCount > 60) break; // 안전장치
    }
  }

  /// 떼 러시 — 체력 1짜리 60마리가 한 방향으로 화면을 관통 (경험치 사탕)
  void spawnSwarm() {
    final rng = game.rng;
    final a = rng.nextDouble() * math.pi * 2;
    final dir = Vector2(math.cos(a), math.sin(a)); // 진행 방향
    final origin = game.player.position - dir * spawnRadius;
    final perp = Vector2(-dir.y, dir.x);
    const cols = 20, rows = 3;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final off = perp * ((c - (cols - 1) / 2) * 55.0) - dir * (r * 70.0);
        game.world.add(Mob(
          config: kMobs['mob1']!,
          position: origin + off,
          expDropRate: 0.3,
          itemDropRate: 0,
          hpOverride: 1,
          speedOverride: 175 + rng.nextDouble() * 30,
          damageOverride: 3,
          chargeDir: dir.clone(),
          lifespan: (spawnRadius * 2 + 400) / 175,
        ));
      }
    }
  }

  /// 포위 이벤트 — 고체력 저속 링이 조여온다 (화력이 아니라 동선 검사)
  void spawnRing() {
    const count = 26;
    final hp = kMobs['mob4']!.hp * game.waveHpMult * 5;
    for (var i = 0; i < count; i++) {
      final a = math.pi * 2 * i / count;
      game.world.add(Mob(
        config: kMobs['mob4']!,
        position:
            game.player.position + Vector2(math.cos(a), math.sin(a)) * 560,
        expDropRate: 0.6,
        itemDropRate: 0.02,
        hpOverride: hp,
        speedOverride: 16,
        damageOverride: 6,
        lifespan: 55,
      ));
    }
    game.showBanner('⚠ 포위당했다! 틈을 찾아 빠져나가라!', 4);
  }

  void _spawnReaper() {
    final a = game.rng.nextDouble() * math.pi * 2;
    game.world.add(Mob(
      config: kMobs['mobBoss']!,
      position: game.player.position +
          Vector2(math.cos(a), math.sin(a)) * spawnRadius,
      expDropRate: 0,
      itemDropRate: 0,
      isReaper: true,
    ));
  }

  void _spawn(String key, double expDrop, double itemDrop) {
    final a = game.rng.nextDouble() * math.pi * 2;
    final pos = game.player.position +
        Vector2(math.cos(a), math.sin(a)) * spawnRadius;
    game.world.add(Mob(
      config: kMobs[key]!,
      position: pos,
      expDropRate: expDrop,
      itemDropRate: itemDrop,
      hpMult: game.waveHpMult,
    ));
  }
}
