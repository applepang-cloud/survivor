import 'dart:math' as math;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import 'survivor_game.dart';
import 'mob.dart';

/// 한 발의 공격 사양 — 피해/치명타/넉백/관통 (VS 전투 규칙)
class HitSpec {
  final double damage;
  final double critChance; // 행운 적용 전 기본 확률
  final double knock;
  final bool pierce;
  final bool healOnHit; // 피의 눈물: 명중 시 회복
  const HitSpec(this.damage,
      {this.critChance = 0,
      this.knock = 0,
      this.pierce = false,
      this.healOnHit = false});
}

/// 명중 처리 공통 — 치명타 굴림 후 몹에 피해 적용
void _applyHit(SurvivorGame game, Mob mob, HitSpec spec, Vector2 from,
    {bool isStatic = false}) {
  final critRoll =
      spec.critChance > 0 && game.rng.nextDouble() < spec.critChance * game.stats.luck;
  final dmg = critRoll ? spec.damage * 2 : spec.damage;
  if (isStatic) {
    final could = mob.canBeAttacked;
    mob.hitByStatic(dmg, crit: critRoll, from: from, knock: spec.knock);
    if (could && spec.healOnHit) game.player.heal(1);
  } else {
    mob.takeDamage(dmg, crit: critRoll, from: from, knock: spec.knock);
    if (spec.healOnHit) game.player.heal(1);
  }
}

class Arrow extends SpriteComponent
    with HasGameReference<SurvivorGame>, CollisionCallbacks {
  Arrow(Vector2 pos, this.spec, double sc, {this.spread = 0})
      : super(
            position: pos.clone(),
            anchor: Anchor.center,
            size: Vector2(16, 16) * sc);
  final HitSpec spec;
  final double spread;
  double _life = 1.5;
  late Vector2 _vel;
  final Set<Mob> _hit = {};

  @override
  Future<void> onLoad() async {
    sprite = game.gfx.arrow;
    _life = 1.5 * game.stats.duration;
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
    _vel.scale(game.stats.projSpeed);
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
    if (other is Mob && !_hit.contains(other)) {
      _hit.add(other);
      _applyHit(game, other, spec, position);
      if (!spec.pierce) removeFromParent();
    }
  }
}

class Sword extends SpriteComponent
    with HasGameReference<SurvivorGame>, CollisionCallbacks {
  Sword(Vector2 pos, this.spec, double sc, {this.spread = 0, this.fixedDir})
      : super(
            position: pos.clone(),
            anchor: Anchor.center,
            size: Vector2(16, 16) * sc);
  final HitSpec spec;
  final double spread;
  final Vector2? fixedDir; // 죽음의 나선: 8방향 고정
  double _life = 1.5;
  late Vector2 _vel;
  final Set<Mob> _hit = {};

  @override
  Future<void> onLoad() async {
    sprite = game.gfx.sword;
    _life = 1.5 * game.stats.duration;
    final dir = fixedDir ??
        (game.lastMoveDir.length2 > 0.001
            ? game.lastMoveDir.normalized()
            : Vector2(game.player.facing.toDouble(), 0));
    _vel = (dir * 500)..rotate(spread);
    _vel.scale(game.stats.projSpeed);
    angle = math.pi / 2 + math.pi / 4;
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += _vel * dt;
    angle += 12 * dt;
    _life -= dt;
    if (_life <= 0) removeFromParent();
  }

  @override
  void onCollisionStart(Set<Vector2> p, PositionComponent other) {
    super.onCollisionStart(p, other);
    if (other is Mob && !_hit.contains(other)) {
      _hit.add(other);
      _applyHit(game, other, spec, position);
      if (!spec.pierce) removeFromParent();
    }
  }
}

class Whip extends SpriteAnimationComponent
    with HasGameReference<SurvivorGame>, CollisionCallbacks {
  Whip(Vector2 pos, this.headingLeft, this.spec, double sc)
      : super(
            position: pos.clone(),
            anchor: Anchor.center,
            size: Vector2(65, 27) * sc);
  final bool headingLeft;
  final HitSpec spec;

  @override
  Future<void> onLoad() async {
    animation = game.gfx.whipAnim.clone();
    if (headingLeft) flipHorizontally();
    add(RectangleHitbox());
    add(RemoveEffect(delay: 0.2 * game.stats.duration));
  }

  @override
  void onCollisionStart(Set<Vector2> p, PositionComponent other) {
    super.onCollisionStart(p, other);
    if (other is Mob) {
      _applyHit(game, other, spec, game.player.position, isStatic: true);
    }
  }
}

class Lightning extends SpriteAnimationComponent
    with HasGameReference<SurvivorGame>, CollisionCallbacks {
  Lightning(Vector2 pos, this.spec, double sc)
      : super(
            position: pos.clone()..y += 30,
            anchor: Anchor.center,
            size: Vector2(72, 72) * sc);
  final HitSpec spec;

  @override
  Future<void> onLoad() async {
    animation = game.gfx.lightningAnim.clone();
    add(RectangleHitbox());
    add(RemoveEffect(delay: 0.4 * game.stats.duration));
  }

  @override
  void onCollisionStart(Set<Vector2> p, PositionComponent other) {
    super.onCollisionStart(p, other);
    if (other is Mob) {
      _applyHit(game, other, spec, position, isStatic: true);
    }
  }
}

class Fireball extends SpriteAnimationComponent
    with HasGameReference<SurvivorGame>, CollisionCallbacks {
  Fireball(Vector2 pos, this.spec, double sc)
      : super(
            position: pos.clone(),
            anchor: Anchor.center,
            size: Vector2(512, 384) * sc);
  final HitSpec spec;
  double _life = 5.0;
  late Vector2 _vel;
  final Set<Mob> _hit = {};

  @override
  Future<void> onLoad() async {
    animation = game.gfx.fireballAnim.clone();
    _life = 5.0 * game.stats.duration;
    final target = game.randomMob();
    if (target == null) {
      _vel = Vector2(0, -250);
    } else {
      final dx = target.position.x - position.x;
      final dy = target.position.y - position.y;
      final root = math.sqrt(dx * dx + dy * dy) / 2;
      final drift = spec.pierce ? 0 : 30; // 지옥불은 정조준
      _vel = Vector2((dx / root) * 150, (dy / root) * 150 + drift);
      angle = math.atan2(dy, dx);
    }
    _vel.scale(game.stats.projSpeed);
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
    if (other is Mob && !_hit.contains(other)) {
      _hit.add(other);
      _applyHit(game, other, spec, position);
      if (!spec.pierce) removeFromParent();
    }
  }
}

/// 플레이어 주위를 회전하는 방패
class ShieldOrb extends SpriteComponent
    with HasGameReference<SurvivorGame>, CollisionCallbacks {
  ShieldOrb(this.theta, this.spec, double sc, {this.orbitRadius = 150})
      : super(anchor: Anchor.center, size: Vector2(16, 16) * sc);
  double theta;
  final HitSpec spec;
  final double orbitRadius;

  @override
  Future<void> onLoad() async {
    sprite = game.gfx.shield;
    add(CircleHitbox());
    _place();
  }

  void _place() {
    position = game.player.position +
        Vector2(math.cos(theta), math.sin(theta)) * orbitRadius;
  }

  @override
  void update(double dt) {
    super.update(dt);
    theta += game.shieldAngle;
    _place();
  }

  @override
  void onCollisionStart(Set<Vector2> p, PositionComponent other) {
    super.onCollisionStart(p, other);
    if (other is Mob) {
      _applyHit(game, other, spec, game.player.position, isStatic: true);
    }
  }

  @override
  void onCollision(Set<Vector2> p, PositionComponent other) {
    super.onCollision(p, other);
    if (other is Mob) {
      _applyHit(game, other, spec, game.player.position, isStatic: true);
    }
  }
}

/// 몹 사망 시 폭발 애니메이션
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
