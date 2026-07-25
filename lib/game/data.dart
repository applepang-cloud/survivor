import 'package:flame/components.dart';

import 'stats.dart';

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

const Map<WeaponType, String> kWeaponDesc = {
  WeaponType.arrow: '가장 가까운 적을 관통',
  WeaponType.whip: '좌우로 넓게 휘두른다',
  WeaponType.sword: '이동 방향으로 던진다',
  WeaponType.shield: '주위를 회전하며 보호',
  WeaponType.fireball: '적을 향해 날아간다',
  WeaponType.lightning: '무작위 적을 강타',
};

const int kMaxWeaponLevel = 8;

/// 무기별 기본 치명타 확률 (행운 배율 적용, 치명타 = 2배 피해)
const Map<WeaponType, double> kWeaponCrit = {
  WeaponType.arrow: 0.05,
  WeaponType.whip: 0.0,
  WeaponType.sword: 0.05,
  WeaponType.shield: 0.0,
  WeaponType.fireball: 0.0,
  WeaponType.lightning: 0.0,
};

/// 무기별 넉백 강도 (VS: 무기마다 넉백이 다르다)
const Map<WeaponType, double> kWeaponKnock = {
  WeaponType.arrow: 90,
  WeaponType.whip: 50,
  WeaponType.sword: 90,
  WeaponType.shield: 150,
  WeaponType.fireball: 130,
  WeaponType.lightning: 0,
};

/// 무기 진화 — 무기 만렙 + 대응 장신구 보유 시 보스 보물상자에서 진화 (VS 조합법)
class EvoDef {
  final PassiveType passive;
  final String name;
  final String emoji;
  final String desc;
  const EvoDef(this.passive, this.name, this.emoji, this.desc);
}

const Map<WeaponType, EvoDef> kEvolutions = {
  WeaponType.whip:
      EvoDef(PassiveType.hollowHeart, '피의 눈물', '🩸', '치명타가 터지고 명중 시 체력 회복'),
  WeaponType.arrow:
      EvoDef(PassiveType.bracer, '천 개의 칼날', '⚔️', '적을 관통하는 화살 폭풍'),
  WeaponType.sword:
      EvoDef(PassiveType.candelabra, '죽음의 나선', '🌀', '8방향으로 회전하며 관통'),
  WeaponType.fireball:
      EvoDef(PassiveType.spinach, '지옥불', '☄️', '거대한 화염구가 모든 것을 관통'),
  WeaponType.lightning:
      EvoDef(PassiveType.duplicator, '뇌운 고리', '🌩️', '번개가 두 배로 강타'),
  WeaponType.shield:
      EvoDef(PassiveType.armorPlate, '수호자의 서약', '✨', '더 크고 빠른 수호 방패'),
};

/// 무기 레벨별 능력치 (레벨업 선택지로 강화)
class WStats {
  final double damage;
  final double cooldown; // 초
  final double scale;
  final int count;
  const WStats(this.damage, this.cooldown, this.scale, this.count);
}

WStats weaponStats(WeaponType t, int lvl) {
  final l = lvl - 1; // 0부터
  double clamp(double v, double lo) => v < lo ? lo : v;
  switch (t) {
    case WeaponType.arrow:
      return WStats(10 + l * 6, clamp(1.0 - l * 0.1, 0.2), 1.5, 1 + l ~/ 2);
    case WeaponType.sword:
      return WStats(10 + l * 6, clamp(0.5 - l * 0.05, 0.12), 1.8, 1 + l ~/ 2);
    case WeaponType.whip:
      return WStats(
          10 + l * 8, clamp(1.0 - l * 0.08, 0.4), 1.5 + l * 0.2, 1 + l ~/ 3);
    case WeaponType.fireball:
      return WStats(
          20 + l * 10, clamp(1.0 - l * 0.08, 0.4), 0.25 + l * 0.03, 1 + l ~/ 3);
    case WeaponType.lightning:
      return WStats(10 + l * 7, clamp(1.0 - l * 0.08, 0.4), 1.0, 1 + l ~/ 2);
    case WeaponType.shield:
      return WStats(10 + l * 5, 0, 2.0, lvl); // 방패 개수 = 레벨
  }
}

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
