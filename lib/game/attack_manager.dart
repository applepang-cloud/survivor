import 'dart:math' as math;
import 'package:flame/components.dart';

import 'data.dart';
import 'survivor_game.dart';
import 'weapons.dart';

/// 레벨업 선택으로 무기를 획득/강화하고, 만렙+장신구 조합 시 진화하는 매니저.
/// 발사 시 캐릭터 스탯(피해량/쿨타임/범위/탄속/투사체수)을 곱연산 적용 (VS 방식).
class AttackManager extends Component with HasGameReference<SurvivorGame> {
  final Map<WeaponType, int> levels = {};
  final Map<WeaponType, double> _timers = {};
  final Set<WeaponType> evolved = {};
  double shieldAngle = 0.05;

  void reset() {
    levels.clear();
    _timers.clear();
    evolved.clear();
    shieldAngle = 0.05;
    game.shieldAngle = 0.05;
    game.world.children
        .whereType<ShieldOrb>()
        .forEach((s) => s.removeFromParent());
    addWeapon(WeaponType.arrow); // 시작 무기
  }

  int levelOf(WeaponType t) => levels[t] ?? 0;
  bool owns(WeaponType t) => levelOf(t) > 0;
  bool isEvolved(WeaponType t) => evolved.contains(t);
  Map<WeaponType, int> get ownedLevels =>
      {for (final e in levels.entries) e.key: e.value};

  void addWeapon(WeaponType t) {
    levels[t] = 1;
    _timers[t] = 0;
    if (t == WeaponType.shield) refreshShields();
  }

  void upgrade(WeaponType t) {
    levels[t] = levelOf(t) + 1;
    if (t == WeaponType.shield) refreshShields();
  }

  /// 진화 (보물상자에서 호출)
  void evolve(WeaponType t) {
    evolved.add(t);
    if (t == WeaponType.shield) {
      game.shieldAngle = shieldAngle * 1.7;
      refreshShields();
    }
  }

  /// 스탯/레벨 변화 후 방패 오브 재구성
  void refreshShields() {
    if (!owns(WeaponType.shield)) return;
    final lvl = levelOf(WeaponType.shield);
    final evo = isEvolved(WeaponType.shield);
    final s = weaponStats(WeaponType.shield, lvl);
    final st = game.stats;
    final count = lvl + st.amount + (evo ? 2 : 0);
    final dmg = s.damage * st.might * (evo ? 1.5 : 1.0);
    final scale = s.scale * st.area * (evo ? 1.5 : 1.0);
    final radius = evo ? 175.0 : 150.0;
    final spec = HitSpec(dmg,
        knock: kWeaponKnock[WeaponType.shield]!,
        critChance: kWeaponCrit[WeaponType.shield]!);
    game.world.children
        .whereType<ShieldOrb>()
        .forEach((o) => o.removeFromParent());
    for (int i = 0; i < count; i++) {
      final theta = (math.pi * 2 / count) * i;
      game.world.add(ShieldOrb(theta, spec, scale, orbitRadius: radius));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isRunning) return;
    for (final t in levels.keys) {
      if (t == WeaponType.shield) continue;
      final s = weaponStats(t, levels[t]!);
      var cd = s.cooldown * game.stats.cooldown;
      if (isEvolved(t)) {
        cd *= (t == WeaponType.arrow) ? 0.4 : 0.75; // 천 개의 칼날: 연사
      }
      cd = math.max(cd, 0.08);
      _timers[t] = (_timers[t] ?? 0) + dt;
      if (_timers[t]! >= cd) {
        _timers[t] = 0;
        _fire(t, s);
      }
    }
  }

  void _fire(WeaponType t, WStats s) {
    game.audio.shoot();
    final st = game.stats;
    final p = game.player.position;
    final evo = isEvolved(t);
    final dmg = s.damage * st.might * (evo ? 1.5 : 1.0);
    final count = s.count + st.amount + (evo && t == WeaponType.arrow ? 1 : 0);
    final scale = s.scale * st.area * (evo && t == WeaponType.fireball ? 1.6 : 1.0);
    final crit = (t == WeaponType.whip && evo) ? 0.10 : kWeaponCrit[t]!;
    final spec = HitSpec(dmg,
        critChance: crit,
        knock: kWeaponKnock[t]!,
        pierce: evo &&
            (t == WeaponType.arrow ||
                t == WeaponType.sword ||
                t == WeaponType.fireball),
        healOnHit: evo && t == WeaponType.whip);

    switch (t) {
      case WeaponType.arrow:
        for (int i = 0; i < count; i++) {
          final spread = (i - (count - 1) / 2) * 0.18;
          game.world.add(Arrow(p, spec, scale, spread: spread));
        }
        break;
      case WeaponType.sword:
        if (evo) {
          // 죽음의 나선: 8방향 관통
          for (int i = 0; i < 8; i++) {
            final a = math.pi * 2 / 8 * i;
            game.world.add(Sword(p, spec, scale,
                fixedDir: Vector2(math.cos(a), math.sin(a))));
          }
        } else {
          for (int i = 0; i < count; i++) {
            final spread = (i - (count - 1) / 2) * 0.22;
            game.world.add(Sword(p, spec, scale, spread: spread));
          }
        }
        break;
      case WeaponType.fireball:
        for (int i = 0; i < count; i++) {
          game.world.add(Fireball(p, spec, scale));
        }
        break;
      case WeaponType.whip:
        _fireWhip(p, spec, scale, count);
        break;
      case WeaponType.lightning:
        final strikes = evo ? count * 2 : count; // 뇌운 고리: 두 배 강타
        for (int i = 0; i < strikes; i++) {
          final m = game.randomMob();
          if (m != null) game.world.add(Lightning(m.position, spec, scale));
        }
        game.add(TimerComponent(
          period: 0.2,
          repeat: false,
          removeOnFinish: true,
          onTick: () {
            for (int i = 0; i < strikes; i++) {
              final m = game.randomMob();
              if (m != null) {
                game.world.add(Lightning(m.position, spec, scale));
              }
            }
          },
        ));
        break;
      case WeaponType.shield:
        break;
    }
  }

  void _fireWhip(Vector2 p, HitSpec spec, double scale, int count) {
    final left = game.player.facing < 0;
    final dirs = <Vector2>[Vector2(1, 0), Vector2(-1, 0)];
    if (count >= 2) dirs.addAll([Vector2(0, 1), Vector2(0, -1)]);
    if (count >= 3) dirs.addAll([Vector2(1, 1), Vector2(-1, -1)]);
    for (final d in dirs) {
      final pos = p + d.normalized() * 150;
      game.world
          .add(Whip(pos, left && d.x == 0 ? true : d.x < 0, spec, scale));
    }
  }
}
