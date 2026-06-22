import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:survivor/game/survivor_game.dart';
import 'package:survivor/game/data.dart';
import 'package:survivor/game/mob.dart';

Future<SurvivorGame> _pumpGame(WidgetTester tester) async {
  final game = SurvivorGame();
  // 이미지 디코딩은 실제 비동기 — runAsync 안에서 로드 완료까지 대기
  await tester.runAsync(() async {
    await tester.pumpWidget(
      GameWidget<SurvivorGame>(
        game: game,
        overlayBuilderMap: {
          'menu': (_, _) => const SizedBox.shrink(),
          'hud': (_, _) => const SizedBox.shrink(),
          'levelup': (_, _) => const SizedBox.shrink(),
          'gameover': (_, _) => const SizedBox.shrink(),
        },
      ),
    );
    await game.loaded;
  });
  await tester.pump();
  await tester.pump();
  return game;
}

void main() {
  testWidgets('starts with arrow weapon, player at origin, 100 hp',
      (tester) async {
    final game = await _pumpGame(tester);
    game.startGame();
    expect(game.isRunning, isTrue);
    expect(game.attack.ownedTypes.contains(WeaponType.arrow), isTrue);
    expect(game.player.hp, 100);
    expect(game.player.position, Vector2.zero());
  });

  testWidgets('spawns mobs over time', (tester) async {
    final game = await _pumpGame(tester);
    game.startGame();
    for (var i = 0; i < 200; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(game.world.children.whereType<Mob>().length, greaterThan(0));
  });

  testWidgets('weapons auto-attack and kill mobs (combat loop)',
      (tester) async {
    final game = await _pumpGame(tester);
    game.startGame();
    for (var i = 0; i < 700; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(game.kills, greaterThan(0));
  });

  testWidgets('level up follows scripted progression (lv2 = whip)',
      (tester) async {
    final game = await _pumpGame(tester);
    game.startGame();
    expect(game.level, 1);
    game.gainExp(60); // maxExp 50 초과 → 레벨업 대기
    expect(game.isRunning, isFalse);
    game.continueAfterLevelUp();
    expect(game.level, 2);
    expect(game.isRunning, isTrue);
    // 원작: 레벨2에서 채찍 획득
    expect(game.attack.ownedTypes.contains(WeaponType.whip), isTrue);
    // maxExp 가 1.3배로 증가
    expect(game.maxExp, closeTo(65, 0.001));
  });

  testWidgets('full scripted unlock order matches original', (tester) async {
    final game = await _pumpGame(tester);
    game.startGame();
    // 레벨 2~6 진행하며 무기 5종 추가 확인
    final expectAt = {
      2: WeaponType.whip,
      3: WeaponType.sword,
      4: WeaponType.shield,
      5: WeaponType.fireball,
      6: WeaponType.lightning,
    };
    for (var lv = 2; lv <= 6; lv++) {
      game.gainExp(game.maxExp.ceil() + 1);
      game.continueAfterLevelUp();
      expect(game.attack.ownedTypes.contains(expectAt[lv]), isTrue,
          reason: 'level $lv should unlock ${expectAt[lv]}');
    }
    // 모든 6종 보유
    expect(game.attack.ownedTypes.length, 6);
  });

  testWidgets('player dies on lethal damage', (tester) async {
    final game = await _pumpGame(tester);
    game.startGame();
    game.player.takeDamage(150);
    expect(game.player.hp, 0);
    expect(game.isRunning, isFalse);
  });
}
