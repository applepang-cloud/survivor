import 'package:flame/components.dart';

import 'data.dart';
import 'survivor_game.dart';
import 'weapons.dart';

class AttackEvent {
  final WeaponType type;
  double damage;
  double scale;
  double gap; // 초 단위 발사 간격
  double timer = 0;
  AttackEvent(this.type, this.damage, this.scale, this.gap);
}

/// 원작 attackManager + PlayingScene.afterLevelUp 의 스크립트형 무기 진행을 그대로 옮김.
class AttackManager extends Component with HasGameReference<SurvivorGame> {
  final List<AttackEvent> events = [];
  int shieldCount = 0;
  double shieldAngle = 0.05;
  bool _whipFlipNext = false;

  void reset() {
    events.clear();
    shieldCount = 0;
    shieldAngle = 0.05;
    game.shieldAngle = 0.05;
    game.world.children.whereType<ShieldOrb>().forEach((s) => s.removeFromParent());
    // 시작 무기: 화살 (원작 create()에서 addAttackEvent("arrow",10,1.5,1000))
    _add(WeaponType.arrow, 10, 1.5, 1000);
  }

  void _add(WeaponType type, double dmg, double scale, double gapMs) {
    events.add(AttackEvent(type, dmg, scale, gapMs / 1000));
  }

  void _setGap(WeaponType type, double gapMs) {
    for (final e in events) {
      if (e.type == type) e.gap = gapMs / 1000;
    }
  }

  void _setScale(WeaponType type, double scale) {
    for (final e in events) {
      if (e.type == type) e.scale = scale;
    }
  }

  void _setDamage(WeaponType type, double dmg) {
    for (final e in events) {
      if (e.type == type) e.damage = dmg;
    }
  }

  Set<WeaponType> get ownedTypes {
    final s = events.map((e) => e.type).toSet();
    if (shieldCount > 0) s.add(WeaponType.shield);
    return s;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isRunning) return;
    for (final e in events) {
      e.timer += dt;
      if (e.timer >= e.gap) {
        e.timer = 0;
        _fire(e);
      }
    }
  }

  void _fire(AttackEvent e) {
    game.audio.shoot();
    final p = game.player.position;
    switch (e.type) {
      case WeaponType.arrow:
        game.world.add(Arrow(p, e.damage, e.scale));
        break;
      case WeaponType.sword:
        game.world.add(Sword(p, e.damage, e.scale));
        break;
      case WeaponType.fireball:
        game.world.add(Fireball(p, e.damage, e.scale));
        break;
      case WeaponType.whip:
        final left = game.player.facing < 0;
        final firstX = left ? p.x - 150 : p.x + 150;
        game.world.add(Whip(Vector2(firstX, p.y), left, e.damage, e.scale));
        final secondX = left ? p.x + 150 : p.x - 150;
        game.add(TimerComponent(
          period: 0.2,
          repeat: false,
          removeOnFinish: true,
          onTick: () {
            final pp = game.player.position;
            game.world.add(Whip(
                Vector2(secondX - p.x + pp.x, pp.y), !left, e.damage, e.scale));
          },
        ));
        _whipFlipNext = !_whipFlipNext;
        break;
      case WeaponType.lightning:
        final m1 = game.randomMob();
        if (m1 != null) {
          game.world.add(Lightning(m1.position, e.damage, e.scale));
        }
        game.add(TimerComponent(
          period: 0.2,
          repeat: false,
          removeOnFinish: true,
          onTick: () {
            final m2 = game.randomMob();
            if (m2 != null) {
              game.world.add(Lightning(m2.position, e.damage, e.scale));
            }
          },
        ));
        break;
      case WeaponType.shield:
        break; // 방패는 타이머 없이 상시 회전
    }
  }

  void _rebuildShields(int count) {
    shieldCount = count;
    game.world.children.whereType<ShieldOrb>().forEach((s) => s.removeFromParent());
    for (int i = 0; i < count; i++) {
      final theta = (3.14159265 * 2 / count) * i;
      game.world.add(ShieldOrb(theta, 10, 2));
    }
  }

  /// 원작 PlayingScene.afterLevelUp 의 case 그대로 (level = 증가 후 값)
  void afterLevelUp(int level) {
    switch (level) {
      case 2:
        _add(WeaponType.whip, 10, 1.5, 1000);
        break;
      case 3:
        _add(WeaponType.sword, 10, 1.8, 500);
        break;
      case 4:
        _rebuildShields(1);
        break;
      case 5:
        _add(WeaponType.fireball, 20, 0.25, 1000);
        break;
      case 6:
        _add(WeaponType.lightning, 10, 1, 1000);
        break;
      case 7:
        _setGap(WeaponType.arrow, 500);
        break;
      case 8:
        _setScale(WeaponType.whip, 3);
        break;
      case 9:
        _rebuildShields(4);
        break;
      case 10:
        _setGap(WeaponType.sword, 250);
        break;
      case 11:
        _setGap(WeaponType.fireball, 500);
        break;
      case 12:
        _setGap(WeaponType.lightning, 500);
        break;
      case 13:
        _setGap(WeaponType.arrow, 100);
        break;
      case 14:
        _setGap(WeaponType.whip, 500);
        break;
      case 15:
        _rebuildShields(8);
        break;
      case 16:
        _setGap(WeaponType.sword, 100);
        break;
      case 17:
        for (int i = 0; i < 4; i++) {
          _add(WeaponType.fireball, 20, 0.25, 500);
        }
        break;
      case 18:
        for (int i = 0; i < 4; i++) {
          _add(WeaponType.lightning, 10, 1, 500);
        }
        break;
      case 19:
        shieldAngle = 0.1;
        game.shieldAngle = 0.1;
        break;
      case 20:
        _setDamage(WeaponType.arrow, 30);
        _setDamage(WeaponType.sword, 30);
        _setDamage(WeaponType.whip, 30);
        break;
    }
  }
}
