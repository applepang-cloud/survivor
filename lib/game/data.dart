import 'package:flame/components.dart';

/// 원작의 6가지 무기 (whip, arrow, sword, shield, fireball, lightning)
enum WeaponType { arrow, whip, sword, shield, fireball, lightning }

const Map<WeaponType, String> kWeaponEmoji = {
  WeaponType.arrow: '🏹',
  WeaponType.whip: '🔗',
  WeaponType.sword: '🗡️',
  WeaponType.shield: '🛡️',
  WeaponType.fireball: '🔥',
  WeaponType.lightning: '⚡',
};

const Map<WeaponType, String> kWeaponName = {
  WeaponType.arrow: '화살',
  WeaponType.whip: '채찍',
  WeaponType.sword: '검',
  WeaponType.shield: '방패',
  WeaponType.fireball: '화염구',
  WeaponType.lightning: '번개',
};

/// 몹 종류별 설정 (원작 PlayingScene/Mob/ExpUp 수치 그대로)
class MobConfig {
  final String key; // 텍스처 키 = 애니메이션 키
  final double hp;
  final double contactDamage;
  final int exp;
  final double scale;
  final double speed;
  final Vector2 frameSize;
  const MobConfig(this.key, this.hp, this.contactDamage, this.exp, this.scale,
      this.speed, this.frameSize);

  Vector2 get displaySize => frameSize * scale;
  double get hitRadius => frameSize.y * scale * 0.22;
}

final Map<String, MobConfig> kMobs = {
  'mob1': MobConfig('mob1', 10, 5, 10, 2, 60, Vector2(64, 64)),
  'mob2': MobConfig('mob2', 20, 10, 20, 2, 60, Vector2(64, 64)),
  'mob3': MobConfig('mob3', 30, 20, 30, 2, 60, Vector2(64, 64)),
  'mob4': MobConfig('mob4', 40, 25, 40, 2, 60, Vector2(64, 64)),
  'mob5': MobConfig('mob5', 50, 33, 50, 2, 60, Vector2(64, 64)),
  'mobBoss': MobConfig('mobBoss', 60, 50, 60, 3, 50, Vector2(160, 128)),
};

/// expUp 색상 인덱스 (green0 yellow1 pink2 blue3 red4 purple5)
const Map<String, int> kExpColorIndex = {
  'mob1': 0,
  'mob2': 1,
  'mob3': 2,
  'mob4': 3,
  'mob5': 4,
  'mobBoss': 5,
};
