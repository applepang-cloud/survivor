import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import 'data.dart';
import 'survivor_game.dart';
import 'weapons.dart';
import 'exp_up.dart';
import 'item.dart';

class Mob extends SpriteAnimationComponent
    with HasGameReference<SurvivorGame>, CollisionCallbacks {
  Mob({
    required this.config,
    required Vector2 position,
    required this.expDropRate,
    required this.itemDropRate,
  }) : super(
          position: position,
          size: config.displaySize,
          anchor: Anchor.center,
        ) {
    hp = config.hp;
    speed = config.speed;
  }

  final MobConfig config;
  final double expDropRate;
  final double itemDropRate;
  late double hp;
  late double speed;

  bool canBeAttacked = true; // 정적 무기용 500ms 쿨다운
  double _flash = 0;
  bool frozen = false;

  static const _hitColor = Color(0xFFDB4455);

  @override
  Future<void> onLoad() async {
    animation = game.gfx.mobRun[config.key]!.clone();
    add(CircleHitbox(radius: config.hitRadius, anchor: Anchor.center)
      ..position = size / 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_flash > 0) {
      _flash -= dt;
      if (_flash <= 0) paint.colorFilter = null;
    }
    if (frozen) return;
    // 플레이어(머리 위 -30) 방향으로 이동
    final target = game.player.position - Vector2(0, 30);
    final dir = target - position;
    if (dir.length2 > 1) {
      dir.normalize();
      position += dir * speed * dt;
    }
    flipHorizontally2(position.x > game.player.position.x);
    if (hp <= 0) die();
  }

  bool _flipped = false;
  void flipHorizontally2(bool left) {
    if (left != _flipped) {
      _flipped = left;
      flipHorizontally();
    }
  }

  /// 투사체(dynamic) 직접 피해
  void takeDamage(double dmg) {
    hp -= dmg;
    _displayHit();
    if (hp <= 0) die();
  }

  /// 정적 무기 피해 — 500ms 쿨다운
  void hitByStatic(double dmg) {
    if (!canBeAttacked) return;
    hp -= dmg;
    _displayHit();
    canBeAttacked = false;
    add(TimerComponent(
        period: 0.5,
        repeat: false,
        removeOnFinish: true,
        onTick: () => canBeAttacked = true));
    if (hp <= 0) die();
  }

  void _displayHit() {
    paint.colorFilter = const ColorFilter.mode(_hitColor, BlendMode.modulate);
    _flash = 0.2;
  }

  bool _dead = false;
  void die() {
    if (_dead || !isMounted) return;
    _dead = true;
    game.world.add(Explosion(position));
    if (game.rng.nextDouble() < expDropRate) {
      game.world.add(ExpUp(config: config, mobPosition: position));
    }
    if (game.rng.nextDouble() < itemDropRate) {
      game.world.add(ItemDrop(mobPosition: position, isBoss: config.key == 'mobBoss'));
    }
    game.onMobKilled();
    removeFromParent();
  }
}
