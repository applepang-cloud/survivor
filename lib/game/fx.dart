import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'survivor_game.dart';
import 'player.dart';

/// 피해량 숫자 텍스트 (치명타는 노란색 + 큰 글씨)
class DamageText extends TextComponent {
  DamageText(double dmg, Vector2 pos, {bool crit = false})
      : super(
          text: dmg >= 100 ? dmg.round().toString() : dmg.toStringAsFixed(0),
          position: pos + Vector2(0, -20),
          anchor: Anchor.center,
          priority: 60,
          textRenderer: TextPaint(
            style: TextStyle(
              fontSize: crit ? 22 : 14,
              fontWeight: FontWeight.w900,
              color: crit ? const Color(0xFFFFD54F) : Colors.white,
              shadows: const [Shadow(color: Colors.black, blurRadius: 3)],
            ),
          ),
        );

  double _life = 0.5;

  @override
  void update(double dt) {
    super.update(dt);
    position.y -= 55 * dt;
    _life -= dt;
    if (_life <= 0) removeFromParent();
  }
}

/// 보스가 떨어뜨리는 보물상자 — 획득 시 무기 진화/골드 (VS 진화 시스템)
class TreasureChest extends PositionComponent
    with HasGameReference<SurvivorGame>, CollisionCallbacks {
  TreasureChest({required Vector2 position})
      : super(
            position: position,
            size: Vector2.all(44),
            anchor: Anchor.center,
            priority: 8);

  double _bob = 0;

  @override
  Future<void> onLoad() async {
    add(TextComponent(
      text: '🎁',
      anchor: Anchor.center,
      position: size / 2,
      textRenderer: TextPaint(style: const TextStyle(fontSize: 34)),
    ));
    add(CircleHitbox(radius: 26, anchor: Anchor.center)..position = size / 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _bob += dt * 4;
    scale.setValues(1 + 0.06 * _bob.remainder(1), 1 + 0.06 * _bob.remainder(1));
  }

  @override
  void onCollisionStart(Set<Vector2> p, PositionComponent other) {
    super.onCollisionStart(p, other);
    if (other is Player && game.isRunning) {
      removeFromParent();
      game.openChest();
    }
  }
}

/// 금화 — VS의 골드 드랍
class GoldCoin extends PositionComponent
    with HasGameReference<SurvivorGame>, CollisionCallbacks {
  GoldCoin({required Vector2 position, this.value = 1})
      : super(
            position: position,
            size: Vector2.all(22),
            anchor: Anchor.center,
            priority: 6);

  final int value;

  @override
  Future<void> onLoad() async {
    add(TextComponent(
      text: '🪙',
      anchor: Anchor.center,
      position: size / 2,
      textRenderer: TextPaint(style: const TextStyle(fontSize: 16)),
    ));
    add(CircleHitbox(radius: 12, anchor: Anchor.center)..position = size / 2);
  }

  bool _magnet = false;

  @override
  void update(double dt) {
    super.update(dt);
    final d = game.player.position.distanceTo(position);
    if (d < game.player.pickupRadius) _magnet = true;
    if (_magnet && d > 1) {
      final dir = (game.player.position - position)..normalize();
      position += dir * 340 * dt;
    }
  }

  @override
  void onCollisionStart(Set<Vector2> p, PositionComponent other) {
    super.onCollisionStart(p, other);
    if (other is Player) {
      game.gainGold(value);
      removeFromParent();
    }
  }
}
