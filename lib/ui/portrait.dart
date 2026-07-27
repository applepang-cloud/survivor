import 'package:flame/components.dart' show Vector2;
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';

import '../game/survivor_game.dart';
import '../game/characters.dart';

/// 대원 초상화 — 인게임 스프라이트(첫 프레임)를 틴트해 픽셀 그대로 확대.
class CharacterPortrait extends StatelessWidget {
  const CharacterPortrait({
    super.key,
    required this.game,
    required this.character,
    this.size = 72,
  });

  final SurvivorGame game;
  final Character character;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: character.color, width: 2),
      ),
      child: game.isLoaded
          ? CustomPaint(
              painter: _SpritePainter(game.gfx.playerIdle, character.tint))
          : const SizedBox.shrink(),
    );
  }
}

class _SpritePainter extends CustomPainter {
  _SpritePainter(this.sprite, this.tint);
  final Sprite sprite;
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.none
      ..colorFilter = ColorFilter.mode(tint, BlendMode.modulate);
    sprite.render(canvas,
        size: Vector2(size.width, size.height), overridePaint: paint);
  }

  @override
  bool shouldRepaint(_SpritePainter old) =>
      old.sprite != sprite || old.tint != tint;
}
