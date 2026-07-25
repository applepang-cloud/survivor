import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game/survivor_game.dart';
import 'ui/bitmap_font.dart';
import 'overlays/menu_overlay.dart';
import 'overlays/hud_overlay.dart';
import 'overlays/levelup_overlay.dart';
import 'overlays/gameover_overlay.dart';
import 'overlays/chest_overlay.dart';
import 'overlays/pause_overlay.dart';
import 'overlays/sound_button.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BitmapFont.ensureLoaded();
  runApp(const SurvivorApp());
}

class SurvivorApp extends StatelessWidget {
  const SurvivorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final game = SurvivorGame();
    return MaterialApp(
      title: 'Survivor',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF000000),
        body: GameWidget<SurvivorGame>(
          game: game,
          overlayBuilderMap: {
            'menu': (ctx, g) => MenuOverlay(game: g),
            'hud': (ctx, g) => HudOverlay(game: g),
            'levelup': (ctx, g) => LevelUpOverlay(game: g),
            'gameover': (ctx, g) => GameOverOverlay(game: g),
            'chest': (ctx, g) => ChestOverlay(game: g),
            'pause': (ctx, g) => PauseOverlay(game: g),
            'soundbtn': (ctx, g) => SoundButton(game: g),
          },
          initialActiveOverlays: const ['hud', 'soundbtn'],
        ),
      ),
    );
  }
}
