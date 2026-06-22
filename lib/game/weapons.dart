import 'dart:math' as math;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import 'survivor_game.dart';
import 'mob.dart';

/// 투사체형 무기 (arrow/sword/fireball) — 몹에 닿으면 데미지 후 자신 소멸(dynamic)
/// 정적형 무기 (whip/lightning/shield) — 몹의 500ms 쿨다운 적용, 자신은 유지(static)

class Arrow extends SpriteComponent
    with HasGameReference<SurvivorGame>, CollisionCallbacks {
  Arrow(Vector2 pos, this.damage, double sc, {this.spread = 0})
      : super(
            position: pos.clone(),
            anchor: Anchor.center,
            size: Vector2(16, 16) * sc);
  final double damage;
  final double spread;
  double _life = 1.5;
  late Vector2 _vel;

  @override
  Future<void> onLoad() async {
    sprite = game.gfx.arrow;
    final closest = game.closestMob();
    if (closest == null) {
      _vel = Vector2(0, -250);
    } else {
      final dx = closest.position.x - position.x;
      final dy = closest.position.y - position.y;
      final root = math.sqrt(dx * dx + dy * dy) / 2;
      _vel = Vector2((dx / root) * 250, (dy / root) * 250 + 30);
      angle = math.atan2(dy, dx) + math.pi / 2 + math.pi / 4;
    }
    if (spread != 0) {
      _vel.rotate(spread);
      angle += spread;
    }
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += _vel * dt;
    _life -= dt;
    if (_life <= 0) removeFromParent();
  }

  @override
  void onCollisionStart(Set<Vector2> p, PositionComponent other) {
    super.onCollisionStart(p, other);
    if (other is Mob) {
      other.takeDamage(damage);
      removeFromParent();
    }
  }
}

class Sword extends SpriteComponent
    with HasGameReference<SurvivorGame>, CollisionCallbacks {
  Sword(Vector2 pos, this.damage, double sc, {this.spread = 0})
      : super(
            position: pos.clone(),
            anchor: Anchor.center,
            size: Vector2(16, 16) * sc);
  final double damage;
  final double spread;
  double _life = 1.5;
  late Vector2 _vel;

  @override
  Future<void> onLoad() async {
    sprite = game.gfx.sword;
    final dir = game.lastMoveDir.length2 > 0.001
        ? game.lastMoveDir.normalized()
        : Vector2(game.player.facing.toDouble(), 0);
    _vel = (dir * 500)..rotate(spread); // 원작 250 * SPEED(2)
    angle = math.pi / 2 + math.pi / 4;
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += _vel * dt;
    angle += 12 * dt; // 회전(원작 angularVelocity 800)
    _life -= dt;
    if (_life <= 0) removeFromParent();
  }

  @override
  void onCollisionStart(Set<Vector2> p, PositionComponent other) {
    super.onCollisionStart(p, other);
    if (other is Mob) {
      other.takeDamage(damage);
      removeFromParent();
    }
  }
}

class Whip extends SpriteAnimationComponent
    with HasGameReference<SurvivorGame>, CollisionCallbacks {
  Whip(Vector2 pos, this.headingLeft, this.damage, double sc)
      : super(
            position: pos.clone(),
            anchor: Anchor.center,
            size: Vector2(65, 27) * sc);
  final bool headingLeft;
  final double damage;

  @override
  Future<void> onLoad() async {
    animation = game.gfx.whipAnim.clone();
    if (headingLeft) flipHorizontally();
    add(RectangleHitbox());
    add(RemoveEffect(delay: 0.2)); // DURATION 200ms
  }

  @override
  void onCollisionStart(Set<Vector2> p, PositionComponent other) {
    super.onCollisionStart(p, other);
    if (other is Mob) other.hitByStatic(damage);
  }
}

class Lightning extends SpriteAnimationComponent
    with HasGameReference<SurvivorGame>, CollisionCallbacks {
  Lightning(Vector2 pos, this.damage, double sc)
      : super(
            position: pos.clone()..y += 30,
            anchor: Anchor.center,
            size: Vector2(72, 72) * sc);
  final double damage;

  @override
  Future<void> onLoad() async {
    animation = game.gfx.lightningAnim.clone();
    add(RectangleHitbox());
    add(RemoveEffect(delay: 0.4)); // DURATION 400ms
  }

  @override
  void onCollisionStart(Set<Vector2> p, PositionComponent other) {
    super.onCollisionStart(p, other);
    if (other is Mob) other.hitByStatic(damage);
  }
}

class Fireball extends SpriteAnimationComponent
    with HasGameReference<SurvivorGame>, CollisionCallbacks {
  Fireball(Vector2 pos, this.damage, double sc)
      : super(
            position: pos.clone(),
            anchor: Anchor.center,
            size: Vector2(512, 384) * sc);
  final double damage;
  double _life = 5.0;
  late Vector2 _vel;

  @override
  Future<void> onLoad() async {
    animation = game.gfx.fireballAnim.clone();
    final target = game.randomMob();
    if (target == null) {
      _vel = Vector2(0, -250);
    } else {
      final dx = target.position.x - position.x;
      final dy = target.position.y - position.y;
      final root = math.sqrt(dx * dx + dy * dy) / 2;
      _vel = Vector2((dx / root) * 150, (dy / root) * 150 + 30);
      angle = math.atan2(dy, dx);
    }
    add(CircleHitbox(radius: size.y * 0.28, anchor: Anchor.center)
      ..position = size / 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += _vel * dt;
    _life -= dt;
    if (_life <= 0) removeFromParent();
  }

  @override
  void onCollisionStart(Set<Vector2> p, PositionComponent other) {
    super.onCollisionStart(p, other);
    if (other is Mob) {
      other.takeDamage(damage);
      removeFromParent();
    }
  }
}

/// 플레이어 주위를 일정 반경(150)으로 회전하는 방패
class ShieldOrb extends SpriteComponent
    with HasGameReference<SurvivorGame>, CollisionCallbacks {
  ShieldOrb(this.theta, this.damage, double sc)
      : super(anchor: Anchor.center, size: Vector2(16, 16) * sc);
  double theta;
  final double damage;
  static const double radius = 150;

  @override
  Future<void> onLoad() async {
    sprite = game.gfx.shield;
    add(CircleHitbox());
    _place();
  }

  void _place() {
    position = game.player.position +
        Vector2(math.cos(theta), math.sin(theta)) * radius;
  }

  @override
  void update(double dt) {
    super.update(dt);
    theta += game.shieldAngle; // 원작: 매 프레임 shieldAngle 만큼 회전
    _place();
  }

  @override
  void onCollisionStart(Set<Vector2> p, PositionComponent other) {
    super.onCollisionStart(p, other);
    if (other is Mob) other.hitByStatic(damage);
  }

  @override
  void onCollision(Set<Vector2> p, PositionComponent other) {
    super.onCollision(p, other);
    if (other is Mob) other.hitByStatic(damage);
  }
}

/// 몹 사망 시 폭발 애니메이션 (시각 효과)
class Explosion extends SpriteAnimationComponent
    with HasGameReference<SurvivorGame> {
  Explosion(Vector2 pos)
      : super(
            position: pos.clone()..y += 30,
            anchor: Anchor.center,
            size: Vector2(32, 32) * 2);

  @override
  Future<void> onLoad() async {
    animation = game.gfx.explodeAnim.clone();
    add(RemoveEffect(delay: 0.4));
  }
}
