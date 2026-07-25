/// 뱀파이어 서바이버즈의 능력치 체계 (나무위키 분석 기반).
/// 모든 무기는 캐릭터 스탯(피해량/쿨타임/범위/탄속/지속/투사체수)을 곱연산으로 공유한다.
library;

/// 장신구(패시브 아이템) — VS의 대응 아이템과 수치를 따름
enum PassiveType {
  spinach, // 시금치: 피해량 +10%/lvl
  emptyTome, // 빈 책: 쿨타임 -8%/lvl
  candelabra, // 촛대: 공격범위 +10%/lvl
  bracer, // 팔 보호대: 투사체 속도 +10%/lvl
  spellbinder, // 주문속박기: 지속시간 +10%/lvl
  duplicator, // 복제 반지: 투사체 수 +1/lvl (최대 2)
  hollowHeart, // 검은 심장: 최대 체력 +20%/lvl
  pummarola, // 붉은 심장: 회복 +0.2/lvl
  armorPlate, // 갑옷: 방어력 +1/lvl
  wings, // 날개: 이동속도 +10%/lvl
  attractorb, // 매혹구: 획득 반경 +20/lvl
  crown, // 왕관: 성장(경험치) +8%/lvl
  clover, // 클로버: 행운 +10%/lvl
}

class PassiveDef {
  final String name;
  final String emoji;
  final String desc;
  final int maxLevel;
  const PassiveDef(this.name, this.emoji, this.desc, this.maxLevel);
}

const Map<PassiveType, PassiveDef> kPassives = {
  PassiveType.spinach: PassiveDef('시금치', '🥬', '피해량 +10%', 5),
  PassiveType.emptyTome: PassiveDef('빈 책', '📖', '무기 쿨타임 -8%', 5),
  PassiveType.candelabra: PassiveDef('촛대', '🕯️', '공격 범위 +10%', 5),
  PassiveType.bracer: PassiveDef('팔 보호대', '💪', '투사체 속도 +10%', 5),
  PassiveType.spellbinder: PassiveDef('주문속박기', '🔮', '지속시간 +10%', 5),
  PassiveType.duplicator: PassiveDef('복제 반지', '💍', '투사체 수 +1', 2),
  PassiveType.hollowHeart: PassiveDef('검은 심장', '🖤', '최대 체력 +20%', 5),
  PassiveType.pummarola: PassiveDef('붉은 심장', '🍅', '초당 체력 회복 +0.2', 5),
  PassiveType.armorPlate: PassiveDef('갑옷', '🥋', '받는 피해 -1', 5),
  PassiveType.wings: PassiveDef('날개', '🪽', '이동 속도 +10%', 5),
  PassiveType.attractorb: PassiveDef('매혹구', '🧲', '경험치 획득 반경 +20', 5),
  PassiveType.crown: PassiveDef('왕관', '👑', '경험치 획득량 +8%', 5),
  PassiveType.clover: PassiveDef('클로버', '🍀', '행운 +10% (4번째 선택지·치명타)', 5),
};

/// 캐릭터 종합 스탯 — 장신구 레벨로부터 산출 (VS 능력치 문서의 계산식)
class PlayerStats {
  double might = 1; // 피해량 배율
  double cooldown = 1; // 쿨타임 배율 (감소, 하한 0.4)
  double area = 1; // 공격범위 배율
  double projSpeed = 1; // 투사체 속도 배율
  double duration = 1; // 지속시간 배율
  int amount = 0; // 추가 투사체 수
  double armor = 0; // 고정 피해 감소
  double recovery = 0; // 초당 체력 재생
  double maxHpMult = 1;
  double moveMult = 1;
  double magnet = 60; // 획득 반경(px)
  double growth = 1; // 경험치 배율
  double luck = 1; // 행운

  static PlayerStats from(Map<PassiveType, int> p) {
    int l(PassiveType t) => p[t] ?? 0;
    final s = PlayerStats();
    s.might = 1 + 0.10 * l(PassiveType.spinach);
    s.cooldown = (1 - 0.08 * l(PassiveType.emptyTome)).clamp(0.4, 1.0);
    s.area = 1 + 0.10 * l(PassiveType.candelabra);
    s.projSpeed = 1 + 0.10 * l(PassiveType.bracer);
    s.duration = 1 + 0.10 * l(PassiveType.spellbinder);
    s.amount = l(PassiveType.duplicator);
    s.armor = l(PassiveType.armorPlate).toDouble();
    s.recovery = 0.2 * l(PassiveType.pummarola);
    s.maxHpMult = 1 + 0.20 * l(PassiveType.hollowHeart);
    s.moveMult = 1 + 0.10 * l(PassiveType.wings);
    s.magnet = 60 + 20.0 * l(PassiveType.attractorb);
    s.growth = 1 + 0.08 * l(PassiveType.crown);
    s.luck = 1 + 0.10 * l(PassiveType.clover);
    return s;
  }
}
