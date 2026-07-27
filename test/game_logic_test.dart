import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:survivor/game/survivor_game.dart';
import 'package:survivor/game/data.dart';
import 'package:survivor/game/stats.dart';
import 'package:survivor/game/mob.dart';
import 'package:survivor/game/fx.dart';

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
          'chest': (_, _) => const SizedBox.shrink(),
          'pause': (_, _) => const SizedBox.shrink(),
          'clear': (_, _) => const SizedBox.shrink(),
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
  setUp(() {
    // 플러그인 채널이 없는 테스트 환경용 인메모리 저장소 (테스트마다 초기화)
    SharedPreferences.setMockInitialValues({});
  });

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

  testWidgets('level up pauses and offers 3+ choices', (tester) async {
    final game = await _pumpGame(tester);
    game.startGame();
    expect(game.level, 1);
    game.gainExp(60); // maxExp 50 초과 → 레벨업
    expect(game.level, 2);
    expect(game.isRunning, isFalse);
    expect(game.pendingUpgrades.length, inInclusiveRange(3, 4));
    expect(game.maxExp, closeTo(65, 0.001)); // 1.3배
  });

  testWidgets('applying any option resumes the game', (tester) async {
    final game = await _pumpGame(tester);
    game.startGame();
    game.gainExp(60);
    game.applyUpgrade(game.pendingUpgrades.first);
    expect(game.isRunning, isTrue);
    expect(game.attack.owns(WeaponType.arrow), isTrue); // 시작 무기 유지
  });

  testWidgets('reroll / skip / banish consume charges', (tester) async {
    final game = await _pumpGame(tester);
    game.startGame();
    game.gainExp(60);
    expect(game.rerollsLeft, 2);
    game.rerollUpgrades();
    expect(game.rerollsLeft, 1);
    expect(game.pendingUpgrades.length, inInclusiveRange(3, 4));

    final target = game.pendingUpgrades.first;
    game.banishUpgrade(target);
    expect(game.banishesLeft, 1);
    expect(game.banished.contains(target.key), isTrue);
    expect(game.pendingUpgrades.any((o) => o.key == target.key), isFalse);

    if (!game.isRunning) {
      game.skipUpgrade();
      expect(game.skipsLeft, 1);
    }
    expect(game.isRunning, isTrue);
  });

  testWidgets('passive items shape player stats (VS 능력치)', (tester) async {
    final game = await _pumpGame(tester);
    game.startGame();
    game.passives[PassiveType.spinach] = 5; // 피해 +50%
    game.passives[PassiveType.armorPlate] = 3; // 방어 3
    game.passives[PassiveType.hollowHeart] = 5; // 최대체력 +100%
    game.passives[PassiveType.pummarola] = 5; // 회복 1.0/s
    game.recomputeStats();

    expect(game.stats.might, closeTo(1.5, 0.001));
    expect(game.stats.armor, 3);
    expect(game.player.maxHp, closeTo(200, 0.001));
    expect(game.player.hp, closeTo(200, 0.001)); // 증가분 즉시 회복

    // 방어력: 10 피해 → 7만 받는다
    game.player.takeDamage(10);
    expect(game.player.hp, closeTo(193, 0.001));

    // 회복: 시간이 지나면 체력 재생
    final before = game.player.hp;
    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(game.player.hp, greaterThan(before));
  });

  testWidgets('luck raises 4th-option chance', (tester) async {
    final game = await _pumpGame(tester);
    game.startGame();
    final base = game.fourthChance;
    game.passives[PassiveType.clover] = 5;
    game.recomputeStats();
    expect(game.fourthChance, greaterThan(base));
  });

  testWidgets('weapon evolution via treasure chest (VS 진화)', (tester) async {
    final game = await _pumpGame(tester);
    game.startGame();
    // 채찍 만렙 + 검은 심장 → 진화 자격
    game.attack.levels[WeaponType.whip] = kMaxWeaponLevel;
    game.passives[PassiveType.hollowHeart] = 1;
    game.recomputeStats();
    expect(game.evolveEligible(), WeaponType.whip);

    game.openChest();
    expect(game.attack.isEvolved(WeaponType.whip), isTrue);
    expect(game.chestLines.any((l) => l.contains('피의 눈물')), isTrue);
    expect(game.isRunning, isFalse);
    game.closeChest();
    expect(game.isRunning, isTrue);
  });

  testWidgets('ESC pause toggles and quit returns to menu', (tester) async {
    final game = await _pumpGame(tester);
    game.startGame();
    expect(game.isRunning, isTrue);

    game.togglePause();
    expect(game.escPaused, isTrue);
    expect(game.isRunning, isFalse);
    expect(game.overlays.isActive('pause'), isTrue);

    game.togglePause();
    expect(game.escPaused, isFalse);
    expect(game.isRunning, isTrue);
    expect(game.overlays.isActive('pause'), isFalse);

    // 레벨업 중에는 ESC 무시
    game.gainExp(60);
    expect(game.isRunning, isFalse);
    game.togglePause();
    expect(game.escPaused, isFalse);
    game.applyUpgrade(game.pendingUpgrades.first);

    // 일시정지 → 메뉴로
    game.togglePause();
    game.quitToMenu();
    expect(game.isRunning, isFalse);
    expect(game.overlays.isActive('menu'), isTrue);
    expect(game.overlays.isActive('pause'), isFalse);
  });

  testWidgets('swarm rush spawns charging candy mobs', (tester) async {
    final game = await _pumpGame(tester);
    game.startGame();
    game.spawner.spawnSwarm();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    final swarm = game.world.children
        .whereType<Mob>()
        .where((m) => m.chargeDir != null)
        .toList();
    expect(swarm.length, greaterThanOrEqualTo(50));
    expect(swarm.first.hp, 1); // 체력 1 사탕
    expect(swarm.first.contactDamage, lessThan(10)); // 접촉 피해 약함
  });

  testWidgets('encirclement ring spawns tanky slow wall + banner',
      (tester) async {
    final game = await _pumpGame(tester);
    game.startGame();
    game.spawner.spawnRing();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    final ring = game.world.children
        .whereType<Mob>()
        .where((m) => m.lifespan != null && m.chargeDir == null)
        .toList();
    expect(ring.length, 26);
    expect(ring.first.speed, lessThan(30)); // 저속
    expect(game.banner.value, isNotNull); // 경고 배너
  });

  testWidgets('evolution chest gated until 10:00', (tester) async {
    final game = await _pumpGame(tester);
    game.startGame();

    Future<void> killBossAt(double elapsed) async {
      game.elapsed = elapsed;
      final boss = Mob(
          config: kMobs['mobBoss']!,
          position: Vector2(150, 0),
          expDropRate: 0,
          itemDropRate: 0);
      game.world.add(boss);
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      boss.takeDamage(9999999);
      await tester.pump(const Duration(milliseconds: 16));
    }

    // 10분 전: 상자 없음 (금화만)
    await killBossAt(100);
    expect(game.world.children.whereType<TreasureChest>().length, 0);

    // 10분 후: 상자 드랍
    await killBossAt(700);
    expect(game.world.children.whereType<TreasureChest>().length, 1);
  });

  testWidgets('stage boss at 25:00 drops chest and unlocks hyper',
      (tester) async {
    final game = await _pumpGame(tester);
    game.startGame();
    expect(game.meta.hyperUnlocked, isFalse);

    game.elapsed = 1499.5;
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final boss = game.world.children
        .whereType<Mob>()
        .where((m) => m.isStageBoss)
        .toList();
    expect(boss.length, 1);

    boss.first.takeDamage(999999999);
    await tester.pump(const Duration(milliseconds: 16));
    expect(game.world.children.whereType<TreasureChest>().length,
        greaterThanOrEqualTo(1));
    expect(game.meta.hyperUnlocked, isTrue);
    expect(game.stageBossKilled, isTrue);
  });

  testWidgets('hyper mode multiplies threat and gold', (tester) async {
    final game = await _pumpGame(tester);
    game.modeHyper = true;
    game.startGame();
    expect(game.waveHpMult, closeTo(1.5, 1e-9)); // 적 체력 +50%
    final g0 = game.gold;
    game.gainGold(10);
    expect(game.gold - g0, 15); // 골드 +50%
  });

  testWidgets('turbo mode doubles time flow', (tester) async {
    final game = await _pumpGame(tester);
    game.modeTurbo = true;
    game.startGame();
    expect(game.timeScale, 2.0);
    final t0 = game.elapsed;
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    // 실제 0.32초 펌프 → 게임 시간 ~0.64초
    expect(game.elapsed - t0, greaterThan(0.5));
  });

  testWidgets('endless mode: no clear popup, cycles scale up',
      (tester) async {
    final game = await _pumpGame(tester);
    game.modeEndless = true;
    game.startGame();

    game.elapsed = 1799.5;
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    // 30분을 넘어도 클리어 팝업 없이 계속
    expect(game.cleared, isFalse);
    expect(game.isRunning, isTrue);
    expect(game.overlays.isActive('clear'), isFalse);
    expect(game.spawner.reaperCount, 0); // 무한 모드엔 사신 없음

    // 사이클 1: 적 체력 2배
    game.elapsed = 1900;
    expect(game.endlessCycle, 1);
    expect(game.waveHpMult, closeTo(2.0, 1e-9)); // cycleTime 100 → 기본1 ×2
    game.modeEndless = false;
  });

  testWidgets(
      'clear at 30:00 (bonus gold) → continue → reapers stack per minute',
      (tester) async {
    final game = await _pumpGame(tester);
    game.startGame();

    game.elapsed = 1799.5;
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    // 29:50 경고 → 30:00 클리어 팝업 (일시정지, 보너스 골드)
    expect(game.reaperWarned, isTrue);
    expect(game.cleared, isTrue);
    expect(game.isRunning, isFalse);
    expect(game.overlays.isActive('clear'), isTrue);
    expect(game.gold, greaterThanOrEqualTo(SurvivorGame.kClearBonusGold));
    expect(game.meta.endlessUnlocked, isTrue); // 클리어 → 무한 모드 해금
    expect(game.spawner.reaperCount, 0); // 팝업 중엔 아직 사신 없음

    // 계속 도전 → 사신 등장
    game.continueAfterClear();
    expect(game.isRunning, isTrue);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(game.spawner.reaperCount, 1);

    // 1분 뒤 사신 추가
    game.elapsed = 1859.5;
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(game.spawner.reaperCount, 2);
    expect(
        game.world.children
            .whereType<Mob>()
            .where((m) => m.isReaper)
            .length,
        2);
  });

  testWidgets('finish run after clear shows victory result', (tester) async {
    final game = await _pumpGame(tester);
    game.startGame();
    game.elapsed = 1799.9;
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(game.overlays.isActive('clear'), isTrue);

    game.finishRun();
    expect(game.cleared, isTrue); // 게임오버 화면이 승리 스타일로 표시
    expect(game.overlays.isActive('gameover'), isTrue);
    expect(game.overlays.isActive('clear'), isFalse);
    expect(game.finalTime, greaterThanOrEqualTo(1800));

    // 다시 시작하면 클리어 상태 초기화
    game.startGame();
    expect(game.cleared, isFalse);
  });

  testWidgets('curse skull trades danger for faster growth', (tester) async {
    final game = await _pumpGame(tester);
    game.startGame();

    // 저주 없음: 기준값
    expect(game.stats.curseSpawn, 1.0);
    expect(game.waveHpMult, closeTo(1.0, 1e-9));

    // 미치광이의 두개골 3랭크
    game.passives[PassiveType.skull] = 3;
    game.recomputeStats();
    expect(game.stats.curseSpawn, closeTo(1.75, 1e-9)); // 스폰 +75%
    expect(game.stats.curseHp, closeTo(1.6, 1e-9)); // 적 체력 +60%
    expect(game.stats.curseExp, closeTo(1.45, 1e-9)); // 경험치 +45%
    expect(game.waveHpMult, closeTo(1.6, 1e-9)); // 몹 체력에 반영

    // 경험치 가속 반영
    final before = game.exp;
    game.gainExp(10);
    expect(game.exp - before, closeTo(14.5, 0.01));
  });

  testWidgets('player dies on lethal damage', (tester) async {
    final game = await _pumpGame(tester);
    game.startGame();
    game.player.takeDamage(500);
    expect(game.player.hp, 0);
    expect(game.isRunning, isFalse);
  });
}
