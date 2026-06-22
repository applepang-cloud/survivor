import 'dart:math' as math;
import 'package:flame/components.dart';

import 'data.dart';
import 'survivor_game.dart';
import 'weapons.dart';

/// 레벨업 선택으로 무기를 획득/강화하는 매니저.
/// 각 무기는 레벨(1~kMaxWeaponLevel)을 가지며 능력치는 weaponStats()로 산출.
class AttackManager extends Component with HasGameReference<SurvivorGame> {
  final Map<WeaponType, int> levels = {};
  final Map<WeaponType, double> _timers = {};
  double shieldAngle = 0.05;

  void reset() {
    levels.clear();
    _timers.clear();
    shieldAngle = 0.05;
    game.shieldAngle = 0.05;
    game.world.children
        .whereType<ShieldOrb>()
        .forEach((s) => s.removeFromParent());
    addWeapon(WeaponType.arrow); // 시작 무기
  }

  int levelOf(WeaponType t) => levels[t] ?? 0;
  bool owns(WeaponType t) => levelOf(t) > 0;
  Map<WeaponType, int> get ownedLevels =>
      {for (final e in levels.entries) e.key: e.value};

  void addWeapon(WeaponType t) {
    levels[t] = 1;
    _timers[t] = 0;
    if (t == WeaponType.shield) _rebuildShields(1);
  }

  void upgrade(WeaponType t) {
    levels[t] = levelOf(t) + 1;
    if (t == WeaponType.shield) _rebuildShields(levelOf(t));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isRunning) return;
    for (final t in levels.keys) {
      if (t == WeaponType.shield) continue;
      final s = weaponStats(t, levels[t]!);
      _timers[t] = (_timers[t] ?? 0) + dt;
      if (_timers[t]! >= s.cooldown) {
        _timers[t] = 0;
        _fire(t, s);
      }
    }
  }

  void _fire(WeaponType t, WStats s) {
    game.audio.shoot();
    final p = game.player.position;
    final dmg = s.damage * game.damageMult;
    switch (t) {
      case WeaponType.arrow:
        for (int i = 0; i < s.count; i++) {
          final spread = (i - (s.count - 1) / 2) * 0.18;
          game.world.add(Arrow(p, dmg, s.scale, spread: spread));
        }
        break;
      case WeaponType.sword:
        for (int i = 0; i < s.count; i++) {
          final spread = (i - (s.count - 1) / 2) * 0.22;
          game.world.add(Sword(p, dmg, s.scale, spread: spread));
        }
        break;
      case WeaponType.fireball:
        for (int i = 0; i < s.count; i++) {
          game.world.add(Fireball(p, dmg, s.scale));
        }
        break;
      case WeaponType.whip:
        _fireWhip(p, dmg, s);
        break;
      case WeaponType.lightning:
        for (int i = 0; i < s.count; i++) {
          final m = game.randomMob();
          if (m != null) game.world.add(Lightning(m.position, dmg, s.scale));
        }
        // 원작처럼 200ms 뒤 추가 일제 강타
        game.add(TimerComponent(
          period: 0.2,
          repeat: false,
          removeOnFinish: true,
          onTick: () {
            for (int i = 0; i < s.count; i++) {
              final m = game.randomMob();
              if (m != null) {
                game.world.add(Lightning(m.position, dmg, s.scale));
              }
            }
          },
        ));
        break;
      case WeaponType.shield:
        break;
    }
  }

  void _fireWhip(Vector2 p, double dmg, WStats s) {
    final left = game.player.facing < 0;
    // 기본 좌우 한 쌍 (원작), count 증가 시 상하/대각 추가
    final dirs = <Vector2>[Vector2(1, 0), Vector2(-1, 0)];
    if (s.count >= 2) dirs.addAll([Vector2(0, 1), Vector2(0, -1)]);
    if (s.count >= 3) {
      dirs.addAll([Vector2(1, 1), Vector2(-1, -1)]);
    }
    for (final d in dirs) {
      final pos = p + d.normalized() * 150;
      game.world.add(Whip(pos, left && d.x == 0 ? true : d.x < 0, dmg, s.scale));
    }
  }

  void _rebuildShields(int count) {
    game.world.children
        .whereType<ShieldOrb>()
        .forEach((s) => s.removeFromParent());
    final dmg = weaponStats(WeaponType.shield, count).damage * game.damageMult;
    for (int i = 0; i < count; i++) {
      final theta = (math.pi * 2 / count) * i;
      game.world.add(ShieldOrb(theta, dmg, 2));
    }
  }
}
