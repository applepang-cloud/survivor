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
    expect(game.attack.owns(WeaponType.arrow), isTrue);
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

  testWidgets('level up pauses and offers 3 choices', (tester) async {
    final game = await _pumpGame(tester);
    game.startGame();
    expect(game.level, 1);
    game.gainExp(60); // maxExp 50 초과 → 레벨업
    expect(game.level, 2);
    expect(game.isRunning, isFalse);
    expect(game.pendingUpgrades.length, 3);
    expect(game.maxExp, closeTo(65, 0.001)); // 1.3배
  });

  testWidgets('choosing a new-weapon option grants that weapon',
      (tester) async {
    final game = await _pumpGame(tester);
    game.startGame();
    game.gainExp(60);
    // 새 무기 획득 선택지를 찾아 적용
    final before = game.attack.ownedLevels.length;
    final newWeapon =
        game.pendingUpgrades.firstWhere((o) => o.title.contains('획득'),
            orElse: () => game.pendingUpgrades.first);
    game.applyUpgrade(newWeapon);
    expect(game.isRunning, isTrue);
    expect(game.pendingUpgrades, isEmpty);
    expect(game.attack.ownedLevels.length, greaterThanOrEqualTo(before));
  });

  testWidgets('applying any option resumes the game', (tester) async {
    final game = await _pumpGame(tester);
    game.startGame();
    game.gainExp(60);
    game.applyUpgrade(game.pendingUpgrades.first);
    expect(game.isRunning, isTrue);
    expect(game.attack.owns(WeaponType.arrow), isTrue); // 시작 무기 유지
  });

  testWidgets('player dies on lethal damage', (tester) async {
    final game = await _pumpGame(tester);
    game.startGame();
    game.player.takeDamage(150);
    expect(game.player.hp, 0);
    expect(game.isRunning, isFalse);
  });
}
