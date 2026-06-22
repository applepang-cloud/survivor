import 'dart:ui';
import 'package:flame/components.dart';

import 'survivor_game.dart';

/// 원작의 tileSprite 배경 — background.png 를 카메라가 보는 영역에 타일링.
class Background extends Component with HasGameReference<SurvivorGame> {
  Background() {
    priority = -100;
  }

  @override
  void render(Canvas canvas) {
    final img = game.gfx.background;
    final tileW = img.width.toDouble();
    final tileH = img.height.toDouble();
    final rect = game.camera.visibleWorldRect;

    final startX = (rect.left / tileW).floor() * tileW;
    final startY = (rect.top / tileH).floor() * tileH;
    final paint = Paint();

    for (double x = startX; x < rect.right; x += tileW) {
      for (double y = startY; y < rect.bottom; y += tileH) {
        canvas.drawImageRect(
          img,
          Rect.fromLTWH(0, 0, tileW, tileH),
          Rect.fromLTWH(x, y, tileW, tileH),
          paint,
        );
      }
    }
  }
}
