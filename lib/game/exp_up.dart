import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import 'data.dart';
import 'survivor_game.dart';
import 'player.dart';

/// 원작 ExpUp — 죽은 자리에 가만히 놓이며, 플레이어가 닿으면 획득.
/// 자석(magnet) 아이템을 먹으면 플레이어 쪽으로 끌려온다.
class ExpUp extends SpriteComponent
    with HasGameReference<SurvivorGame>, CollisionCallbacks {
  ExpUp({required this.config, required Vector2 mobPosition})
      : super(
          position: mobPosition.clone()
            ..y += (config.key == 'mobBoss' ? 70 : 30),
          anchor: Anchor.center,
          size: Vector2(16, 16) * 1.5,
        );

  final MobConfig config;
  bool magnetized = false;

  int get value => config.exp;

  @override
  Future<void> onLoad() async {
    sprite = game.gfx.expColors[kExpColorIndex[config.key]!];
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (magnetized) {
      final dir = game.player.position - position;
      if (dir.length2 > 1) {
        dir.normalize();
        position += dir * 1000 * dt;
      }
    }
  }

  @override
  void onCollisionStart(Set<Vector2> p, PositionComponent other) {
    super.onCollisionStart(p, other);
    if (other is Player) {
      game.audio.pickup();
      game.gainExp(value);
      removeFromParent();
    }
  }
}
