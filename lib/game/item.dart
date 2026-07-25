import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import 'survivor_game.dart';
import 'player.dart';
import 'mob.dart';
import 'exp_up.dart';

enum ItemType { magnet, freeze, potion, allkill }

/// 원작 Items — 자석/빙결/물약/전체처치 (드랍률 0.01)
/// 사신에게는 빙결/전체처치가 통하지 않는다.
class ItemDrop extends SpriteComponent
    with HasGameReference<SurvivorGame>, CollisionCallbacks {
  ItemDrop({required Vector2 mobPosition, required this.isBoss})
      : super(
          position: mobPosition.clone()..y += (isBoss ? 100 : 60),
          anchor: Anchor.center,
          size: Vector2(16, 16) * 1.5,
        );

  final bool isBoss;
  late final ItemType type;

  @override
  Future<void> onLoad() async {
    type = ItemType.values[game.rng.nextInt(4)];
    sprite = game.gfx.items[type.index];
    add(CircleHitbox());
  }

  @override
  void onCollisionStart(Set<Vector2> p, PositionComponent other) {
    super.onCollisionStart(p, other);
    if (other is! Player) return;
    game.audio.item();
    switch (type) {
      case ItemType.magnet:
        for (final e in game.world.children.whereType<ExpUp>()) {
          e.magnetized = true;
        }
        break;
      case ItemType.freeze:
        for (final m in game.world.children.whereType<Mob>()) {
          if (m.isReaper) continue;
          m.frozen = true;
          m.add(TimerComponent(
              period: 5,
              repeat: false,
              removeOnFinish: true,
              onTick: () => m.frozen = false));
        }
        break;
      case ItemType.potion:
        game.player.heal(30); // VS 바닥 치킨과 동일한 30 회복
        break;
      case ItemType.allkill:
        for (final m in game.world.children.whereType<Mob>().toList()) {
          if (m.isReaper) continue;
          m.takeDamage(999999);
        }
        break;
    }
    removeFromParent();
  }
}
