import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import 'data.dart';
import 'survivor_game.dart';
import 'weapons.dart';
import 'exp_up.dart';
import 'item.dart';
import 'fx.dart';

class Mob extends SpriteAnimationComponent
    with HasGameReference<SurvivorGame>, CollisionCallbacks {
  Mob({
    required this.config,
    required Vector2 position,
    required this.expDropRate,
    required this.itemDropRate,
    double hpMult = 1.0,
    this.isReaper = false,
  }) : super(
          position: position,
          size: config.displaySize * (isReaper ? 1.3 : 1.0),
          anchor: Anchor.center,
        ) {
    hp = config.hp * hpMult * (isReaper ? 99999 : 1);
    speed = isReaper ? 120 : config.speed;
    contactDamage = isReaper ? 99999 : config.contactDamage;
  }

  final MobConfig config;
  final double expDropRate;
  final double itemDropRate;
  final bool isReaper; // 사신: 사실상 불사, 즉사급 접촉 피해
  late double hp;
  late double speed;
  late double contactDamage;

  bool canBeAttacked = true; // 정적 무기용 500ms 쿨다운
  double _flash = 0;
  bool frozen = false;
  final Vector2 _kb = Vector2.zero(); // 넉백 잔여 속도

  static const _hitColor = Color(0xFFDB4455);
  static const _reaperColor = Color(0xFF551133);

  @override
  Future<void> onLoad() async {
    animation = game.gfx.mobRun[config.key]!.clone();
    if (isReaper) {
      paint.colorFilter =
          const ColorFilter.mode(_reaperColor, BlendMode.modulate);
    }
    add(CircleHitbox(radius: config.hitRadius, anchor: Anchor.center)
      ..position = size / 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_flash > 0) {
      _flash -= dt;
      if (_flash <= 0 && !isReaper) paint.colorFilter = null;
    }
    // 넉백 적용 (감쇠)
    if (_kb.length2 > 4) {
      position += _kb * dt;
      _kb.scale(math.max(0, 1 - dt * 7));
    }
    if (frozen && !isReaper) return;

    // 너무 멀어진 몹은 스폰 링으로 재배치 (VS의 몹 리포지셔닝)
    if (!isReaper) {
      final distSq = position.distanceToSquared(game.player.position);
      final ring = game.spawner.spawnRadius;
      if (distSq > ring * ring * 2.6) {
        final a = game.rng.nextDouble() * math.pi * 2;
        position = game.player.position +
            Vector2(math.cos(a), math.sin(a)) * ring;
      }
    }

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
  void takeDamage(double dmg,
      {bool crit = false, Vector2? from, double knock = 0}) {
    if (isReaper) dmg = math.min(dmg, 1); // 사신은 사실상 불사
    hp -= dmg;
    _displayHit();
    _applyKnock(from, knock);
    game.spawnDamageText(dmg, position, crit: crit);
    if (hp <= 0) die();
  }

  /// 정적 무기 피해 — 500ms 쿨다운 (원작 Survivor 방식 유지)
  void hitByStatic(double dmg,
      {bool crit = false, Vector2? from, double knock = 0}) {
    if (!canBeAttacked) return;
    if (isReaper) dmg = math.min(dmg, 1);
    hp -= dmg;
    _displayHit();
    _applyKnock(from, knock);
    game.spawnDamageText(dmg, position, crit: crit);
    canBeAttacked = false;
    add(TimerComponent(
        period: 0.5,
        repeat: false,
        removeOnFinish: true,
        onTick: () => canBeAttacked = true));
    if (hp <= 0) die();
  }

  void _applyKnock(Vector2? from, double knock) {
    if (knock <= 0 || isReaper) return;
    final dir = from == null
        ? (position - game.player.position)
        : (position - from);
    if (dir.length2 < 0.001) return;
    dir.normalize();
    _kb.add(dir * knock);
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
      game.world
          .add(ItemDrop(mobPosition: position, isBoss: config.key == 'mobBoss'));
    }
    final isBoss = config.key == 'mobBoss';
    if (isBoss) {
      // 보스: 보물상자(쿨다운) 또는 금화 다발 (VS: 보스는 보물상자 드랍)
      if (game.elapsed - game.lastChestAt > 40) {
        game.lastChestAt = game.elapsed;
        game.world.add(TreasureChest(position: position.clone()));
      } else {
        for (var i = 0; i < 3; i++) {
          game.world.add(GoldCoin(
              position: position +
                  Vector2(game.rng.nextDouble() * 60 - 30,
                      game.rng.nextDouble() * 40 - 20),
              value: 5));
        }
      }
    } else if (game.rng.nextDouble() < 0.04) {
      game.world.add(GoldCoin(position: position.clone(), value: 1));
    }
    game.onMobKilled();
    removeFromParent();
  }
}
