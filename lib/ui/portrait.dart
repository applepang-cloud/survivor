import 'package:flame/components.dart' show Vector2;
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';

import '../game/survivor_game.dart';
import '../game/characters.dart';

/// 대원 초상화 — 캐릭터 일러스트(`assets/portraits/[id].png`)를 표시.
/// 일러스트가 없는 빌드(공개 클론 등)에서는 인게임 스프라이트 틴트로 폴백.
class CharacterPortrait extends StatelessWidget {
  const CharacterPortrait({
    super.key,
    required this.game,
    required this.character,
    this.size = 72,
    this.height, // 지정 시 세로형 초상 (스토리 대화창용)
  });

  final SurvivorGame game;
  final Character character;
  final double size;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final w = size;
    final h = height ?? size;
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: character.color, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        character.illust,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter, // 정사각/가로 크롭 시 얼굴 위주
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => game.isLoaded
            ? CustomPaint(
                painter: _SpritePainter(game.gfx.playerIdle, character.tint))
            : const SizedBox.shrink(),
      ),
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
