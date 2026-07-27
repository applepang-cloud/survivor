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

/// VS 표준 30분 각본 (VS_BALANCE.md):
/// 워밍업 → 5분 스파이크 → 9분 커트라인 → 10분 진화 개방 → 16~20분 소강 →
/// 25분 스테이지 보스 → 28~30분 최대 물량 → 30분 사신.
/// + 스웜 러시(2분~, 45초), 포위(13분·21분), 무한 모드는 30분 루프+사이클 강화.
class MobSpawner extends Component with HasGameReference<SurvivorGame> {
  List<SpawnRule> _rules = [];
  int _phase = -1;
  int _cycle = 0;
  int reaperCount = 0;
  bool ring1Done = false, ring2Done = false;
  bool stageBossSpawned = false;
  double _swarmTimer = 0;

  bool get reaperSpawned => reaperCount > 0;

  late final double spawnRadius;

  MobSpawner() {
    // 고정 해상도 대각선 절반 (원작 getRandomPosition)
    spawnRadius = math.sqrt(1280 * 1280 + 720 * 720) / 2;
  }

  void reset() {
    _phase = -1;
    _cycle = 0;
    _rules = [];
    reaperCount = 0;
    ring1Done = ring2Done = false;
    stageBossSpawned = false;
    _swarmTimer = 0;
    _applyPhase(0);
    // 시작 시 즉시 한 마리 (원작 create()의 new Mob(...mob1...))
    _spawn('mob1', 0.9, 0.01);
  }

  /// 30분 각본. 경계는 _phaseForTime 과 쌍 (사이클 시간 기준).
  List<SpawnRule> _rulesForPhase(int phase) {
    switch (phase) {
      case 0: // 0:00~1:00 워밍업
        return [SpawnRule('mob1', 0.45, 0.9, 0.01)];
      case 1: // 1:00~3:00 첫 분보스 + 램프업
        return [
          SpawnRule('mob1', 0.30, 0.9, 0.01),
          SpawnRule('mob2', 0.60, 0.8, 0.01),
          SpawnRule('mobBoss', 9999, 0.5, 0.01, immediate: true),
        ];
      case 2: // 3:00~5:00
        return [
          SpawnRule('mob2', 0.35, 0.8, 0.01),
          SpawnRule('mob3', 0.70, 0.7, 0.01),
        ];
      case 3: // 5:00~5:40 ★1차 스파이크: 약졸 러시
        return [
          SpawnRule('mob1', 0.07, 0.8, 0.01),
          SpawnRule('mob2', 0.12, 0.7, 0.01),
        ];
      case 4: // 5:40~9:00 + 6:00 분보스
        return [
          SpawnRule('mob3', 0.35, 0.7, 0.01),
          SpawnRule('mob4', 0.70, 0.6, 0.01),
          SpawnRule('mobBoss', 9999, 0.5, 0.01, immediate: true),
        ];
      case 5: // 9:00~10:00 ★커트라인: 튼튼몹 (VS 9분 거대박쥐)
        return [SpawnRule('mob4', 0.45, 0.6, 0.01)];
      case 6: // 10:00~13:00 진화 개방 + 2분마다 분보스
        return [
          SpawnRule('mob3', 0.30, 0.7, 0.01),
          SpawnRule('mob4', 0.50, 0.6, 0.01),
          SpawnRule('mobBoss', 120, 0.5, 0.01, immediate: true),
        ];
      case 7: // 13:00~16:00 (13:00 포위 이벤트)
        return [
          SpawnRule('mob4', 0.35, 0.6, 0.01),
          SpawnRule('mob5', 0.55, 0.5, 0.01),
          SpawnRule('mobBoss', 120, 0.5, 0.01, immediate: true),
        ];
      case 8: // 16:00~20:00 ★소강: 느리고 튼튼 (빌드 완성 구간)
        return [
          SpawnRule('mob4', 0.85, 0.6, 0.02),
          SpawnRule('mob5', 1.10, 0.5, 0.02),
        ];
      case 9: // 20:00~24:00 재상승 (21:00 포위 이벤트)
        return [
          SpawnRule('mob4', 0.40, 0.6, 0.01),
          SpawnRule('mob5', 0.50, 0.5, 0.01),
          SpawnRule('mobBoss', 120, 0.5, 0.01, immediate: true),
        ];
      case 10: // 24:00~25:00 프리보스 램프
        return [
          SpawnRule('mob3', 0.25, 0.7, 0.01),
          SpawnRule('mob5', 0.30, 0.5, 0.01),
        ];
      case 11: // 25:00~28:00 스테이지 보스 페이즈
        return [
          SpawnRule('mob4', 0.35, 0.6, 0.01),
          SpawnRule('mob5', 0.40, 0.5, 0.01),
          SpawnRule('mobBoss', 90, 0.5, 0.01, immediate: true),
        ];
      case 12: // 28:00~30:00 ★최대 물량 (피날레)
        return [
          SpawnRule('mob1', 0.12, 0.9, 0.01),
          SpawnRule('mob3', 0.15, 0.7, 0.01),
          SpawnRule('mob4', 0.18, 0.6, 0.01),
          SpawnRule('mob5', 0.20, 0.5, 0.01),
          SpawnRule('mobBoss', 45, 0.5, 0.01, immediate: true),
        ];
      default: // 30:00~ (일반 모드 계속 도전 구간)
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
    if (sec < 60) return 0;
    if (sec < 180) return 1;
    if (sec < 300) return 2;
    if (sec < 340) return 3;
    if (sec < 540) return 4;
    if (sec < 600) return 5;
    if (sec < 780) return 6;
    if (sec < 960) return 7;
    if (sec < 1200) return 8;
    if (sec < 1440) return 9;
    if (sec < 1500) return 10;
    if (sec < 1680) return 11;
    if (sec < 1800) return 12;
    return 13;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isRunning) return;
    final tc = game.cycleTime; // 무한 모드는 30분마다 0으로 되감김
    final total = game.elapsed;

    // 무한 모드: 사이클 전환 감지 → 이벤트 플래그 리셋 + 배너
    if (game.endlessCycle != _cycle) {
      _cycle = game.endlessCycle;
      ring1Done = ring2Done = false;
      stageBossSpawned = false;
      _phase = -1; // 각본 처음부터
      game.showBanner('🔄 사이클 ${_cycle + 1} — 적들이 훨씬 강해진다!', 5);
    }

    _applyPhase(_phaseForTime(tc));
    // 저주·하이퍼: 스폰 간격 단축
    final spawnMult =
        game.stats.curseSpawn * (game.modeHyper ? 1.5 : 1.0) * (1 + _cycle * 0.5);
    for (final r in _rules) {
      r.timer += dt;
      if (r.timer >= r.gap / spawnMult) {
        r.timer = 0;
        _spawn(r.mobKey, r.expDrop, r.itemDrop);
      }
    }

    // ── 스웜 러시: 2:00부터 45초마다 (사신 직전 10초 제외)
    if (tc >= 120 && tc < 1790) {
      _swarmTimer += dt;
      if (_swarmTimer >= 45) {
        _swarmTimer = 0;
        spawnSwarm();
      }
    }

    // ── 포위 이벤트: 13:00, 21:00 (동선 검사)
    if (!ring1Done && tc >= 780) {
      ring1Done = true;
      spawnRing();
    }
    if (!ring2Done && tc >= 1260) {
      ring2Done = true;
      spawnRing();
    }

    // ── 25:00 스테이지 보스 (처치 시 하이퍼 해금)
    if (!stageBossSpawned && tc >= SurvivorGame.kStageBossAt) {
      stageBossSpawned = true;
      spawnStageBoss();
    }

    // ── 사신 (무한 모드 제외): 29:50 예고, 30:00부터 1분마다 +1
    if (!game.modeEndless) {
      if (!game.reaperWarned && total >= SurvivorGame.kRunSeconds - 10) {
        game.reaperWarned = true;
        game.showBanner('☠ 무언가 무시무시한 것이 다가온다...', 5);
      }
      while (total >= SurvivorGame.kRunSeconds + reaperCount * 60) {
        _spawnReaper();
        reaperCount++;
        if (reaperCount > 60) break; // 안전장치
      }
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

  /// 25:00 스테이지 보스 — 거대·고체력, 처치 시 확정 상자 + 하이퍼 해금
  void spawnStageBoss() {
    final a = game.rng.nextDouble() * math.pi * 2;
    game.world.add(Mob(
      config: kMobs['mobBoss']!,
      position: game.player.position +
          Vector2(math.cos(a), math.sin(a)) * (spawnRadius * 0.8),
      expDropRate: 1.0,
      itemDropRate: 0,
      isStageBoss: true,
      hpOverride: 1500 * game.waveHpMult,
      speedOverride: 45,
      damageOverride: 55,
    ));
    game.showBanner('👹 스테이지 보스가 나타났다!', 5);
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
