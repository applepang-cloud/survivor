import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data.dart';
import 'stats.dart';
import 'sprites.dart';
import 'audio.dart';
import 'player.dart';
import 'mob.dart';
import 'background.dart';
import 'mob_manager.dart';
import 'attack_manager.dart';
import 'weapons.dart';
import 'exp_up.dart';
import 'item.dart';
import 'fx.dart';

class GameStats {
  final double hp, maxHp;
  final int level, kills, gold;
  final double exp, maxExp, time;
  final Map<WeaponType, int> weapons; // 보유 무기 → 레벨
  final Set<WeaponType> evolved;
  final Map<PassiveType, int> passives; // 보유 장신구 → 레벨
  GameStats({
    required this.hp,
    required this.maxHp,
    required this.level,
    required this.kills,
    required this.gold,
    required this.exp,
    required this.maxExp,
    required this.time,
    required this.weapons,
    required this.evolved,
    required this.passives,
  });
}

/// 레벨업 선택지 (무기/장신구/보급)
class UpgradeOption {
  final String key; // 지우기(banish) 식별용
  final String title;
  final String desc;
  final String emoji;
  final Color color;
  final void Function() apply;
  UpgradeOption(this.key, this.title, this.desc, this.emoji, this.color,
      this.apply);
}

class SurvivorGame extends FlameGame
    with HasCollisionDetection, KeyboardEvents {
  SurvivorGame()
      : super(
          camera: CameraComponent.withFixedResolution(width: 1280, height: 720),
        );

  final math.Random rng = math.Random();
  final GameAssets gfx = GameAssets();
  final GameAudio audio = GameAudio();

  late Player player;
  late Background background;
  late MobSpawner spawner;
  late AttackManager attack;
  late JoystickComponent joystick;

  // 진행 상태
  double elapsed = 0;
  int kills = 0;
  int level = 1;
  int gold = 0;
  double exp = 0;
  double maxExp = 50; // 초기 50, 레벨업마다 ×1.3
  bool isRunning = false;
  bool _leveling = false;

  // VS 능력치 (장신구로 성장)
  PlayerStats stats = PlayerStats();
  final Map<PassiveType, int> passives = {};
  static const int kMaxPassiveSlots = 6;

  // 레벨업 보조 (VS: 새로고침/건너뛰기/지우기)
  int rerollsLeft = 2, skipsLeft = 2, banishesLeft = 2;
  final Set<String> banished = {};

  // 보물상자 / 사신
  double lastChestAt = -999;
  List<String> chestLines = [];
  bool reaperWarned = false;

  // 10분 생존 클리어 (VS: 제한시간 도달 = 스테이지 클리어)
  bool cleared = false;
  static const int kClearBonusGold = 100;

  // ESC 일시정지 (원작 pauseManager)
  bool escPaused = false;

  double shieldAngle = 0.05;
  Vector2 lastMoveDir = Vector2(1, 0);

  List<UpgradeOption> pendingUpgrades = [];

  final Set<LogicalKeyboardKey> _keys = {};

  /// 화면 중앙 경고 배너 (사신 예고, 포위 등)
  final ValueNotifier<String?> banner = ValueNotifier(null);

  final ValueNotifier<GameStats> hud = ValueNotifier(GameStats(
    hp: 100,
    maxHp: 100,
    level: 1,
    kills: 0,
    gold: 0,
    exp: 0,
    maxExp: 50,
    time: 0,
    weapons: {WeaponType.arrow: 1},
    evolved: {},
    passives: {},
  ));
  int finalTime = 0, finalLevel = 1, finalKills = 0, finalGold = 0;

  @override
  Color backgroundColor() => const Color(0xFF000000);

  @override
  Future<void> onLoad() async {
    await gfx.load(images);
    await audio.preload();

    background = Background();
    world.add(background);

    player = Player();
    world.add(player);
    camera.follow(player);

    attack = AttackManager();
    add(attack);
    spawner = MobSpawner();
    add(spawner);

    joystick = JoystickComponent(
      knob: CircleComponent(
          radius: 30,
          paint: Paint()..color = Colors.white.withValues(alpha: 0.85)),
      background: CircleComponent(
          radius: 64,
          paint: Paint()..color = Colors.white.withValues(alpha: 0.25)),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );

    overlays.add('menu');
  }

  // ---- 입력 ----
  @override
  KeyEventResult onKeyEvent(KeyEvent e, Set<LogicalKeyboardKey> keys) {
    _keys
      ..clear()
      ..addAll(keys);
    // ESC: 일시정지 토글 (원작: ESC로 정지/해제)
    if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) {
      togglePause();
    }
    return KeyEventResult.handled;
  }

  /// ESC 일시정지 토글 — 레벨업/상자/클리어/게임오버/메뉴 중에는 무시
  void togglePause() {
    if (overlays.isActive('levelup') ||
        overlays.isActive('chest') ||
        overlays.isActive('clear') ||
        overlays.isActive('gameover') ||
        overlays.isActive('menu')) {
      return;
    }
    if (!escPaused && isRunning) {
      escPaused = true;
      isRunning = false;
      audio.pauseBgm();
      pauseEngine();
      overlays.add('pause');
    } else if (escPaused) {
      escPaused = false;
      overlays.remove('pause');
      isRunning = true;
      audio.resumeBgm();
      resumeEngine();
    }
  }

  /// 일시정지 화면에서 메뉴로 나가기
  void quitToMenu() {
    escPaused = false;
    overlays.remove('pause');
    audio.stopBgm();
    if (joystick.isMounted) joystick.removeFromParent();
    isRunning = false;
    overlays.add('menu');
    resumeEngine();
  }

  Vector2 inputDirection() {
    final v = Vector2.zero();
    if (joystick.isMounted && joystick.direction != JoystickDirection.idle) {
      v.add(joystick.relativeDelta);
    }
    if (_keys.contains(LogicalKeyboardKey.arrowUp) ||
        _keys.contains(LogicalKeyboardKey.keyW)) {
      v.y -= 1;
    }
    if (_keys.contains(LogicalKeyboardKey.arrowDown) ||
        _keys.contains(LogicalKeyboardKey.keyS)) {
      v.y += 1;
    }
    if (_keys.contains(LogicalKeyboardKey.arrowLeft) ||
        _keys.contains(LogicalKeyboardKey.keyA)) {
      v.x -= 1;
    }
    if (_keys.contains(LogicalKeyboardKey.arrowRight) ||
        _keys.contains(LogicalKeyboardKey.keyD)) {
      v.x += 1;
    }
    return v;
  }

  // ---- 흐름 ----
  void startGame() {
    // 월드 정리
    for (final type in [
      Mob,
      ExpUp,
      ItemDrop,
      Arrow,
      Sword,
      Whip,
      Fireball,
      Lightning,
      ShieldOrb,
      TreasureChest,
      GoldCoin,
      DamageText,
    ]) {
      world.children
          .where((c) => c.runtimeType == type)
          .toList()
          .forEach((c) => c.removeFromParent());
    }

    player.position = Vector2.zero();
    player.maxHp = 100;
    player.hp = 100;
    player.pickupRadius = 60;
    player.paint.colorFilter = null;

    elapsed = 0;
    kills = 0;
    level = 1;
    gold = 0;
    exp = 0;
    maxExp = 50;
    _leveling = false;
    stats = PlayerStats();
    passives.clear();
    rerollsLeft = 2;
    skipsLeft = 2;
    banishesLeft = 2;
    banished.clear();
    lastChestAt = -999;
    chestLines = [];
    reaperWarned = false;
    cleared = false;
    banner.value = null;
    escPaused = false;
    pendingUpgrades = [];
    shieldAngle = 0.05;
    lastMoveDir = Vector2(1, 0);

    attack.reset();
    spawner.reset();

    overlays.remove('menu');
    overlays.remove('gameover');
    overlays.remove('levelup');
    overlays.remove('chest');
    overlays.remove('pause');
    overlays.remove('clear');
    if (!joystick.isMounted) camera.viewport.add(joystick);
    isRunning = true;
    audio.startBgm();
    resumeEngine();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isRunning) return;
    elapsed += dt;
    // 10:00 도달 = 스테이지 클리어 (VS: 제한시간 생존이 1차 목표)
    if (!cleared && elapsed >= 600) {
      cleared = true;
      gold += kClearBonusGold;
      audio.levelup();
      isRunning = false;
      _updateHud();
      pauseEngine();
      overlays.add('clear');
      return;
    }
    _updateHud();
  }

  /// 클리어 화면에서 "계속 도전" — 사신을 피하며 기록 도전 (무한 모드)
  void continueAfterClear() {
    overlays.remove('clear');
    isRunning = true;
    resumeEngine();
    showBanner('☠ 사신이 몰려온다! 얼마나 버틸 수 있을까?', 4);
  }

  /// 클리어 화면에서 "여기서 승리" — 승리 결과 화면으로 종료
  void finishRun() {
    overlays.remove('clear');
    gameOver(); // cleared=true 라 승리 화면으로 표시됨
  }

  /// 시간 경과 몹 체력 배율 (VS: 웨이브가 갈수록 강해짐) × 저주
  double get waveHpMult =>
      (1 + math.max(0, elapsed - 120) / 60 * 0.6) * stats.curseHp;

  // ---- 조준 헬퍼 ----
  Mob? closestMob() {
    Mob? best;
    double bestD = double.infinity;
    for (final m in world.children.whereType<Mob>()) {
      final d = m.position.distanceToSquared(player.position);
      if (d < bestD) {
        bestD = d;
        best = m;
      }
    }
    return best;
  }

  Mob? randomMob() {
    final mobs = world.children.whereType<Mob>().toList();
    if (mobs.isEmpty) return null;
    return mobs[rng.nextInt(mobs.length)];
  }

  // ---- 콜백 ----
  void onMobKilled() => kills++;

  void showBanner(String text, [double seconds = 3.5]) {
    banner.value = text;
    add(TimerComponent(
        period: seconds,
        repeat: false,
        removeOnFinish: true,
        onTick: () {
          if (banner.value == text) banner.value = null;
        }));
  }

  void gainGold(int amount) {
    gold += amount;
    audio.pickup();
  }

  void spawnDamageText(double dmg, Vector2 pos, {bool crit = false}) {
    // 성능 보호: 동시 표시 수 제한 (VS도 후반 데미지표시가 부하 주범)
    if (world.children.whereType<DamageText>().length > 40) return;
    world.add(DamageText(dmg, pos.clone(), crit: crit));
  }

  void onPlayerHit() {
    audio.hit();
    camera.viewfinder.add(MoveByEffect(
      Vector2(rng.nextDouble() * 10 - 5, rng.nextDouble() * 10 - 5),
      EffectController(duration: 0.05, reverseDuration: 0.05),
    ));
  }

  void gainExp(int amount) {
    if (_leveling) return;
    exp += amount * stats.growth * stats.curseExp;
    if (exp >= maxExp) _levelUp();
  }

  void _levelUp() {
    level++;
    exp -= maxExp;
    maxExp *= 1.3;
    pendingUpgrades = _buildOptions();
    _leveling = true;
    isRunning = false;
    audio.levelup();
    _updateHud();
    pauseEngine();
    overlays.add('levelup');
  }

  void _closeLevelUp() {
    pendingUpgrades = [];
    _leveling = false;
    overlays.remove('levelup');
    isRunning = true;
    _updateHud();
    resumeEngine();
    if (exp >= maxExp) _levelUp(); // 연속 레벨업
  }

  void applyUpgrade(UpgradeOption option) {
    option.apply();
    recomputeStats();
    _closeLevelUp();
  }

  /// 새로고침 (VS Reroll)
  void rerollUpgrades() {
    if (rerollsLeft <= 0) return;
    rerollsLeft--;
    pendingUpgrades = _buildOptions();
    _updateHud();
    overlays.remove('levelup');
    overlays.add('levelup'); // 강제 리빌드
  }

  /// 건너뛰기 (VS Skip)
  void skipUpgrade() {
    if (skipsLeft <= 0) return;
    skipsLeft--;
    _closeLevelUp();
  }

  /// 지우기 (VS Banish) — 이번 판에서 해당 선택지 영구 제거
  void banishUpgrade(UpgradeOption option) {
    if (banishesLeft <= 0) return;
    banishesLeft--;
    banished.add(option.key);
    pendingUpgrades =
        pendingUpgrades.where((o) => o.key != option.key).toList();
    if (pendingUpgrades.isEmpty) {
      _closeLevelUp();
    } else {
      overlays.remove('levelup');
      overlays.add('levelup');
    }
  }

  /// 4번째 선택지 확률 — 행운의 영향 (VS: 행운이 4번째 슬롯 확률을 높임)
  double get fourthChance =>
      (0.05 + (stats.luck - 1.0) * 0.5).clamp(0.0, 0.6);

  List<UpgradeOption> _buildOptions() {
    final pool = <UpgradeOption>[];
    const gold = Color(0xFFFFD54F);
    const blue = Color(0xFF4FC3F7);
    const green = Color(0xFF81C784);

    // 무기 강화 / 신규
    for (final t in WeaponType.values) {
      final key = 'w:${t.name}';
      if (banished.contains(key)) continue;
      final lv = attack.levelOf(t);
      if (lv > 0 && lv < kMaxWeaponLevel) {
        pool.add(UpgradeOption(key, '${kWeaponName[t]} Lv.${lv + 1}',
            kWeaponDesc[t]!, kWeaponEmoji[t]!, gold, () => attack.upgrade(t)));
      } else if (lv == 0) {
        pool.add(UpgradeOption(key, '${kWeaponName[t]} 획득!', kWeaponDesc[t]!,
            kWeaponEmoji[t]!, blue, () => attack.addWeapon(t)));
      }
    }

    // 장신구 강화 / 신규 (슬롯 6개 제한)
    for (final p in PassiveType.values) {
      final key = 'p:${p.name}';
      if (banished.contains(key)) continue;
      final def = kPassives[p]!;
      final lv = passives[p] ?? 0;
      if (lv > 0 && lv < def.maxLevel) {
        pool.add(UpgradeOption(key, '${def.name} Lv.${lv + 1}', def.desc,
            def.emoji, green, () => passives[p] = lv + 1));
      } else if (lv == 0 && passives.length < kMaxPassiveSlots) {
        pool.add(UpgradeOption(key, '${def.name} 획득!', def.desc, def.emoji,
            green, () => passives[p] = 1));
      }
    }

    // 모두 만렙이면 보급 선택지 (VS: 치킨/골드)
    if (pool.isEmpty) {
      return [
        UpgradeOption('chicken', '치킨', '체력 30 회복', '🍗',
            const Color(0xFFEF5350), () => player.heal(30)),
        UpgradeOption('gold', '금화 주머니', '골드 +25', '🪙', gold,
            () => this.gold += 25),
      ];
    }

    pool.shuffle(rng);
    final n = rng.nextDouble() < fourthChance ? 4 : 3;
    return pool.take(n).toList();
  }

  /// 장신구 변화 반영 — 스탯 재계산 + 파생치 적용
  void recomputeStats() {
    stats = PlayerStats.from(passives);
    player.applyStats(stats);
    attack.refreshShields();
  }

  // ---- 보물상자 (VS: 진화는 상자에서) ----
  WeaponType? evolveEligible() {
    for (final t in attack.levels.keys) {
      if (attack.levelOf(t) >= kMaxWeaponLevel &&
          !attack.isEvolved(t) &&
          passives.containsKey(kEvolutions[t]!.passive)) {
        return t;
      }
    }
    return null;
  }

  void openChest() {
    chestLines = [];
    final t = evolveEligible();
    if (t != null) {
      attack.evolve(t);
      final evo = kEvolutions[t]!;
      chestLines.add('무기 진화! ${kWeaponEmoji[t]} → ${evo.emoji} ${evo.name}');
      chestLines.add(evo.desc);
      audio.levelup();
    } else {
      audio.item();
    }
    final g = 20 + rng.nextInt(41);
    gold += g;
    chestLines.add('🪙 골드 +$g');
    isRunning = false;
    _updateHud();
    pauseEngine();
    overlays.add('chest');
  }

  void closeChest() {
    overlays.remove('chest');
    isRunning = true;
    resumeEngine();
  }

  void gameOver() {
    isRunning = false;
    audio.stopBgm();
    audio.gameover();
    finalTime = elapsed.floor();
    finalLevel = level;
    finalKills = kills;
    finalGold = gold;
    if (joystick.isMounted) joystick.removeFromParent();
    overlays.add('gameover');
    pauseEngine();
  }

  void backToMenu() {
    overlays.remove('gameover');
    overlays.add('menu');
    resumeEngine();
  }

  void _updateHud() {
    hud.value = GameStats(
      hp: player.hp,
      maxHp: player.maxHp,
      level: level,
      kills: kills,
      gold: gold,
      exp: exp,
      maxExp: maxExp,
      time: elapsed,
      weapons: attack.ownedLevels,
      evolved: Set.of(attack.evolved),
      passives: Map.of(passives),
    );
  }
}
