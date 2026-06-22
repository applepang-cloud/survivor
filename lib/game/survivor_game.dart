import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data.dart';
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

class GameStats {
  final double hp, maxHp;
  final int level, kills;
  final double exp, maxExp, time;
  final Map<WeaponType, int> weapons; // 보유 무기 → 레벨
  GameStats({
    required this.hp,
    required this.maxHp,
    required this.level,
    required this.kills,
    required this.exp,
    required this.maxExp,
    required this.time,
    required this.weapons,
  });
}

/// 레벨업 시 3개 중 1개를 고르는 선택지
class UpgradeOption {
  final String title;
  final String desc;
  final String emoji;
  final Color color;
  final void Function() apply;
  UpgradeOption(this.title, this.desc, this.emoji, this.color, this.apply);
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

  // 상태
  double elapsed = 0;
  int kills = 0;
  int level = 1;
  double exp = 0;
  double maxExp = 50; // 초기 50, 레벨업마다 ×1.3
  bool isRunning = false;
  bool _leveling = false;

  double damageMult = 1.0; // 패시브 공격력 강화
  double shieldAngle = 0.05;
  Vector2 lastMoveDir = Vector2(1, 0);

  List<UpgradeOption> pendingUpgrades = [];

  final Set<LogicalKeyboardKey> _keys = {};

  final ValueNotifier<GameStats> hud = ValueNotifier(GameStats(
    hp: 100,
    maxHp: 100,
    level: 1,
    kills: 0,
    exp: 0,
    maxExp: 50,
    time: 0,
    weapons: {WeaponType.arrow: 1},
  ));
  int finalTime = 0, finalLevel = 1, finalKills = 0;

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
    return KeyEventResult.handled;
  }

  Vector2 inputDirection() {
    final v = Vector2.zero();
    if (joystick.isMounted && joystick.direction != JoystickDirection.idle) {
      v.add(joystick.relativeDelta);
    }
    if (_keys.contains(LogicalKeyboardKey.arrowUp) ||
        _keys.contains(LogicalKeyboardKey.keyW)) v.y -= 1;
    if (_keys.contains(LogicalKeyboardKey.arrowDown) ||
        _keys.contains(LogicalKeyboardKey.keyS)) v.y += 1;
    if (_keys.contains(LogicalKeyboardKey.arrowLeft) ||
        _keys.contains(LogicalKeyboardKey.keyA)) v.x -= 1;
    if (_keys.contains(LogicalKeyboardKey.arrowRight) ||
        _keys.contains(LogicalKeyboardKey.keyD)) v.x += 1;
    return v;
  }

  // ---- 흐름 ----
  void startGame() {
    // 정리
    world.children.whereType<Mob>().forEach((m) => m.removeFromParent());
    world.children.whereType<ExpUp>().forEach((m) => m.removeFromParent());
    world.children.whereType<ItemDrop>().forEach((m) => m.removeFromParent());
    world.children.whereType<Arrow>().forEach((m) => m.removeFromParent());
    world.children.whereType<Sword>().forEach((m) => m.removeFromParent());
    world.children.whereType<Whip>().forEach((m) => m.removeFromParent());
    world.children.whereType<Fireball>().forEach((m) => m.removeFromParent());
    world.children.whereType<Lightning>().forEach((m) => m.removeFromParent());
    world.children.whereType<ShieldOrb>().forEach((m) => m.removeFromParent());

    player.position = Vector2.zero();
    player.maxHp = 100;
    player.hp = 100;
    player.speed = 180;
    player.pickupRadius = 60;
    player.paint.colorFilter = null;

    elapsed = 0;
    kills = 0;
    level = 1;
    exp = 0;
    maxExp = 50;
    _leveling = false;
    damageMult = 1.0;
    pendingUpgrades = [];
    shieldAngle = 0.05;
    lastMoveDir = Vector2(1, 0);

    attack.reset();
    spawner.reset();

    overlays.remove('menu');
    overlays.remove('gameover');
    overlays.remove('levelup');
    if (!joystick.isMounted) camera.viewport.add(joystick);
    isRunning = true;
    resumeEngine();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isRunning) return;
    elapsed += dt;
    _updateHud();
  }

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

  void onPlayerHit() {
    audio.hit();
    camera.viewfinder.add(MoveByEffect(
      Vector2(rng.nextDouble() * 10 - 5, rng.nextDouble() * 10 - 5),
      EffectController(duration: 0.05, reverseDuration: 0.05),
    ));
  }

  void gainExp(int amount) {
    if (_leveling) return;
    exp += amount;
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

  /// 레벨업 화면에서 3개 중 하나를 고르면 호출
  void applyUpgrade(UpgradeOption option) {
    option.apply();
    pendingUpgrades = [];
    _leveling = false;
    overlays.remove('levelup');
    isRunning = true;
    _updateHud();
    resumeEngine();
    // 남은 경험치로 또 레벨업 가능하면 연속 처리
    if (exp >= maxExp) _levelUp();
  }

  List<UpgradeOption> _buildOptions() {
    final pool = <UpgradeOption>[];
    const gold = Color(0xFFFFD54F);

    // 보유 무기 강화
    for (final t in attack.levels.keys) {
      if (attack.levelOf(t) < kMaxWeaponLevel) {
        final lv = attack.levelOf(t) + 1;
        pool.add(UpgradeOption('${kWeaponName[t]} Lv.$lv', kWeaponDesc[t]!,
            kWeaponEmoji[t]!, gold, () => attack.upgrade(t)));
      }
    }
    // 새 무기 획득
    for (final t in WeaponType.values) {
      if (!attack.owns(t)) {
        pool.add(UpgradeOption('${kWeaponName[t]} 획득!', kWeaponDesc[t]!,
            kWeaponEmoji[t]!, const Color(0xFF4FC3F7), () => attack.addWeapon(t)));
      }
    }
    // 패시브 (항상 선택 가능)
    final passives = <UpgradeOption>[
      UpgradeOption('체력 회복', 'HP를 40 회복', '❤️', const Color(0xFFEF5350),
          () => player.heal(40)),
      UpgradeOption('최대 체력 +25', '튼튼해진다', '🛡️', const Color(0xFF66BB6A), () {
        player.maxHp += 25;
        player.heal(25);
      }),
      UpgradeOption('이동 속도 +10%', '더 빠르게', '👟', const Color(0xFF29B6F6),
          () => player.speed *= 1.10),
      UpgradeOption('획득 범위 +30', '경험치를 멀리서 흡수', '🧲',
          const Color(0xFFAB47BC), () => player.pickupRadius += 30),
      UpgradeOption('공격력 +15%', '모든 무기 강화', '💥', const Color(0xFFFF7043),
          () => damageMult *= 1.15),
    ];

    final all = [...pool, ...passives]..shuffle(rng);
    return all.take(3).toList();
  }

  void gameOver() {
    isRunning = false;
    audio.gameover();
    finalTime = elapsed.floor();
    finalLevel = level;
    finalKills = kills;
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
      exp: exp,
      maxExp: maxExp,
      time: elapsed,
      weapons: attack.ownedLevels,
    );
  }
}
