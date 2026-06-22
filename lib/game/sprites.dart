import 'dart:ui';
import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

/// 원작 PreLoader.js 의 스프라이트시트 규격을 그대로 옮긴 에셋 로더.
class GameAssets {
  late final SpriteAnimation playerRun;
  late final Sprite playerIdle;

  late final Map<String, SpriteAnimation> mobRun; // mob1..mob5, mobBoss

  late final SpriteAnimation whipAnim; // 65x27 x4 @20fps
  late final SpriteAnimation lightningAnim; // 72x72 x16 @40fps
  late final SpriteAnimation fireballAnim; // 512x384 x20 @40fps loop
  late final SpriteAnimation explodeAnim; // 32x32 x7 @20fps

  late final Sprite arrow; // 16x16
  late final Sprite shield; // 16x16
  late final Sprite sword; // 16x16
  late final Image background;
  late final Image main;

  late final List<Sprite> expColors; // expUp 16x16 x6 (green..purple)
  late final List<Sprite> items; // items 16x16 x4 (magnet,freeze,potion,allkill)

  Future<void> load(Images images) async {
    final playerImg = await images.load('player.png');
    playerRun = SpriteAnimation.fromFrameData(
      playerImg,
      SpriteAnimationData.sequenced(
          amount: 8, stepTime: 1 / 12, textureSize: Vector2(80, 80)),
    );
    playerIdle = Sprite(playerImg, srcSize: Vector2(80, 80));

    mobRun = {};
    for (final key in ['mob1', 'mob2', 'mob3', 'mob4', 'mob5']) {
      final img = await images.load('$key.png');
      mobRun[key] = SpriteAnimation.fromFrameData(
        img,
        SpriteAnimationData.sequenced(
            amount: 6, stepTime: 1 / 12, textureSize: Vector2(64, 64)),
      );
    }
    final bossImg = await images.load('mobBoss.png');
    mobRun['mobBoss'] = SpriteAnimation.fromFrameData(
      bossImg,
      SpriteAnimationData.sequenced(
          amount: 8, stepTime: 1 / 12, textureSize: Vector2(160, 128)),
    );

    final whipImg = await images.load('whip.png');
    whipAnim = SpriteAnimation.fromFrameData(
      whipImg,
      SpriteAnimationData.sequenced(
          amount: 4,
          stepTime: 1 / 20,
          textureSize: Vector2(65, 27),
          loop: false),
    );

    final lightningImg = await images.load('lightning.png');
    lightningAnim = SpriteAnimation.fromFrameData(
      lightningImg,
      SpriteAnimationData.sequenced(
          amount: 16,
          stepTime: 1 / 40,
          textureSize: Vector2(72, 72),
          loop: false),
    );

    final fireballImg = await images.load('fireball.png');
    fireballAnim = SpriteAnimation.fromFrameData(
      fireballImg,
      SpriteAnimationData.sequenced(
        amount: 20,
        amountPerRow: 4,
        stepTime: 1 / 40,
        textureSize: Vector2(512, 384),
      ),
    );

    final explosionImg = await images.load('explosion.png');
    explodeAnim = SpriteAnimation.fromFrameData(
      explosionImg,
      SpriteAnimationData.sequenced(
          amount: 7,
          stepTime: 1 / 20,
          textureSize: Vector2(32, 32),
          loop: false),
    );

    arrow = Sprite(await images.load('arrow.png'));
    shield = Sprite(await images.load('shield.png'));
    sword = Sprite(await images.load('sword.png'));
    background = await images.load('background.png');
    main = await images.load('main.png');

    final expImg = await images.load('expUp.png');
    final expSheet = SpriteSheet(image: expImg, srcSize: Vector2(16, 16));
    expColors = [for (var i = 0; i < 6; i++) expSheet.getSpriteById(i)];

    final itemsImg = await images.load('items.png');
    final itemSheet = SpriteSheet(image: itemsImg, srcSize: Vector2(16, 16));
    items = [for (var i = 0; i < 4; i++) itemSheet.getSpriteById(i)];
  }
}
