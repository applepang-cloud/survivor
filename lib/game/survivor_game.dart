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
  final Set<WeaponType> weapons;
  final int shieldCount;
  GameStats({
    required this.hp,
    required this.maxHp,
    required this.level,
    required this.kills,
    required this.exp,
    required this.maxExp,
    required this.time,
    required this.weapons,
    required this.shieldCount,
  });
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
  double maxExp = 50; // 원작 ExpBar 초기 50, 레벨업마다 ×1.3
  double _overflow = 0;
  bool isRunning = false;
  bool _leveling = false;

  double shieldAngle = 0.05;
  Vector2 lastMoveDir = Vector2(1, 0);

  final Set<LogicalKeyboardKey> _keys = {};

  final ValueNotifier<GameStats> hud = ValueNotifier(GameStats(
    hp: 100,
    maxHp: 100,
    level: 1,
    kills: 0,
    exp: 0,
    maxExp: 50,
    time: 0,
    weapons: {WeaponType.arrow},
    shieldCount: 0,
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
    player.paint.colorFilter = null;

    elapsed = 0;
    kills = 0;
    level = 1;
    exp = 0;
    maxExp = 50;
    _overflow = 0;
    _leveling = false;
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
    if (exp >= maxExp) {
      _overflow = exp - maxExp;
      _leveling = true;
      isRunning = false;
      audio.levelup();
      _updateHud();
      pauseEngine();
      overlays.add('levelup');
    }
  }

  /// 레벨업 화면에서 "계속"을 누르면 호출 (원작 afterLevelUp)
  void continueAfterLevelUp() {
    level++;
    maxExp *= 1.3;
    exp = _overflow;
    _overflow = 0;
    attack.afterLevelUp(level);
    _leveling = false;
    overlays.remove('levelup');
    isRunning = true;
    _updateHud();
    resumeEngine();
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
      weapons: attack.ownedTypes,
      shieldCount: attack.shieldCount,
    );
  }
}
