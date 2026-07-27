import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import 'stats.dart';
import 'survivor_game.dart';
import 'mob.dart';

class Player extends SpriteAnimationComponent
    with HasGameReference<SurvivorGame>, CollisionCallbacks {
  Player() : super(size: Vector2(80, 80) * 1.3, anchor: Anchor.center);

  static const double baseSpeed = 180; // 원작 3px/frame ≈ 180/s
  double maxHp = 100;
  late double hp = maxHp;
  double pickupRadius = 60; // 경험치/골드 흡수 반경 (자석 스탯)

  double _invuln = 0;
  int facing = 1; // 1 오른쪽, -1 왼쪽
  bool _moving = false;
  bool _flipped = false;
  ColorFilter? _baseTint; // 대원 고유 틴트 (피격 플래시 후 복귀)

  static const _hitColor = Color(0xFFDB4455);

  /// 대원 틴트 설정 (startGame에서 호출)
  void setCharacterTint(Color color) {
    _baseTint = ColorFilter.mode(color, BlendMode.modulate);
    paint.colorFilter = _baseTint;
  }

  @override
  Future<void> onLoad() async {
    animation = game.gfx.playerRun.clone();
    playing = false;
    add(CircleHitbox(radius: 26, anchor: Anchor.center)..position = size / 2);
  }

  /// 장신구 변화 반영 (최대체력 증가분은 즉시 회복)
  void applyStats(PlayerStats s) {
    final newMax = 100 * s.maxHpMult;
    if (newMax > maxHp) hp += newMax - maxHp;
    maxHp = newMax;
    pickupRadius = s.magnet;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_invuln > 0) {
      _invuln -= dt;
      if (_invuln <= 0) paint.colorFilter = _baseTint;
    }
    // 회복 스탯: 초당 재생 (VS Recovery)
    if (game.isRunning && game.stats.recovery > 0 && hp < maxHp) {
      hp = (hp + game.stats.recovery * dt).clamp(0, maxHp);
    }

    final dir = game.inputDirection();
    final moving = dir.length2 > 0.001;
    if (moving) {
      dir.normalize();
      game.lastMoveDir = dir.clone();
      position += dir * baseSpeed * game.stats.moveMult * dt;
      if (dir.x.abs() > 0.01) facing = dir.x > 0 ? 1 : -1;
    }
    if (moving != _moving) {
      _moving = moving;
      playing = moving;
      if (!moving) animationTicker?.reset();
    }
    final flip = facing < 0;
    if (flip != _flipped) {
      _flipped = flip;
      flipHorizontally();
    }
  }

  void takeDamage(double dmg) {
    if (_invuln > 0) return;
    // 방어력: 고정 감소, 최소 1 피해 (VS Armor)
    final eff = (dmg - game.stats.armor).clamp(1.0, double.infinity);
    hp -= eff;
    _invuln = 0.5;
    paint.colorFilter = const ColorFilter.mode(_hitColor, BlendMode.modulate);
    game.onPlayerHit();
    // 위기 무전 (1회)
    if (hp > 0 && hp / maxHp < 0.3 && !game.lowHpSaid) {
      game.lowHpSaid = true;
      game.radioSay(game.character.talkLowHp);
    }
    if (hp <= 0) {
      hp = 0;
      game.gameOver();
    }
  }

  void heal(double amount) {
    hp = (hp + amount).clamp(0, maxHp);
  }

  @override
  void onCollision(Set<Vector2> p, PositionComponent other) {
    super.onCollision(p, other);
    if (other is Mob) takeDamage(other.contactDamage);
  }
}
