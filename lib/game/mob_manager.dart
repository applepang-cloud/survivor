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
  SpawnRule(this.mobKey, this.gap, this.expDrop, this.itemDrop);
}

/// 원작 PlayingScene 의 시간대별 몹 스폰 스케줄 (10초 단위 전환).
class MobSpawner extends Component with HasGameReference<SurvivorGame> {
  List<SpawnRule> _rules = [];
  int _phase = -1;

  late final double spawnRadius;

  MobSpawner() {
    // 고정 해상도 대각선 절반 (원작 getRandomPosition)
    spawnRadius = math.sqrt(1280 * 1280 + 720 * 720) / 2;
  }

  void reset() {
    _phase = -1;
    _rules = [];
    _applyPhase(0);
    // 시작 시 즉시 한 마리 (원작 create()의 new Mob(...mob1...))
    _spawn('mob1', 0.9, 0.01);
  }

  List<SpawnRule> _rulesForPhase(int phase) {
    switch (phase) {
      case 0:
        return [SpawnRule('mob1', 0.3, 0.9, 0.01)];
      case 1:
        return [SpawnRule('mob2', 0.3, 0.8, 0.01)];
      case 2:
        return [SpawnRule('mob3', 0.3, 0.7, 0.01)];
      case 3:
        return [SpawnRule('mob4', 0.3, 0.6, 0.01)];
      case 4:
        return [SpawnRule('mob5', 0.3, 0.5, 0.01)];
      case 5:
        return [SpawnRule('mobBoss', 0.3, 0.5, 0.01)];
      default:
        return [
          SpawnRule('mob1', 0.1, 0.9, 0.01),
          SpawnRule('mob2', 0.1, 0.8, 0.01),
          SpawnRule('mob3', 0.1, 0.7, 0.01),
          SpawnRule('mob4', 0.1, 0.6, 0.01),
          SpawnRule('mob5', 0.1, 0.5, 0.01),
          SpawnRule('mobBoss', 0.1, 0.5, 0.01),
        ];
    }
  }

  void _applyPhase(int phase) {
    if (phase == _phase) return;
    _phase = phase;
    _rules = _rulesForPhase(phase);
  }

  int _phaseForTime(double sec) {
    if (sec < 20) return 0;
    if (sec < 40) return 1;
    if (sec < 60) return 2;
    if (sec < 80) return 3;
    if (sec < 100) return 4;
    if (sec < 120) return 5;
    return 6;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isRunning) return;
    _applyPhase(_phaseForTime(game.elapsed));
    for (final r in _rules) {
      r.timer += dt;
      if (r.timer >= r.gap) {
        r.timer = 0;
        _spawn(r.mobKey, r.expDrop, r.itemDrop);
      }
    }
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
    ));
  }
}
