import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import 'survivor_game.dart';
import 'mob.dart';

class Player extends SpriteAnimationComponent
    with HasGameReference<SurvivorGame>, CollisionCallbacks {
  Player()
      : super(size: Vector2(80, 80) * 1.3, anchor: Anchor.center);

  static const double speed = 180; // 원작 3px/frame ≈ 180/s
  double maxHp = 100;
  late double hp = maxHp;

  double _invuln = 0;
  int facing = 1; // 1 오른쪽, -1 왼쪽
  bool _moving = false;
  bool _flipped = false;

  static const _hitColor = Color(0xFFDB4455);

  @override
  Future<void> onLoad() async {
    animation = game.gfx.playerRun.clone();
    playing = false;
    add(CircleHitbox(radius: 26, anchor: Anchor.center)..position = size / 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_invuln > 0) {
      _invuln -= dt;
      if (_invuln <= 0) paint.colorFilter = null;
    }

    final dir = game.inputDirection();
    final moving = dir.length2 > 0.001;
    if (moving) {
      dir.normalize();
      game.lastMoveDir = dir.clone();
      position += dir * speed * dt;
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
    hp -= dmg;
    _invuln = 0.5;
    paint.colorFilter =
        const ColorFilter.mode(_hitColor, BlendMode.modulate);
    game.onPlayerHit();
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
    if (other is Mob) takeDamage(other.config.contactDamage);
  }
}
