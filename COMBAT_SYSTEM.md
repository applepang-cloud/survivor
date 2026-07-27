# 뱀파이어 서바이버즈 방식 전투 시스템 — 기획 + 소스 아카이브

> 프로젝트: `C:\c_c\survivor` (Flutter + Flame 1.37)
> 이 문서는 본 프로젝트에서 구현한 VS(뱀파이어 서바이버즈) 방식 전투의
> **기획 사양 전체**와 **핵심 소스 전문**을 한 파일로 보존한 아카이브다.
> 다른 프로젝트에 이식하거나 밸런스를 다듬을 때 이 문서만 보면 되도록 작성했다.
> 분석 배경은 `VS_BALANCE.md`(나무위키 기반 원작 분석) 참고.

---

# PART A. 기획서

## A-1. 전투의 기둥 (Design Pillars)

1. **조작은 이동뿐, 공격은 자동** — 실력은 동선·포지셔닝·빌드 선택으로 표현된다.
2. **교차 곡선** — 위협은 분 단위 각본(계단형), 파워는 곱연산 스탯(지수형).
   10분 진화에서 역전되고, 30분 사신이 정점에서 런을 끊는다.
3. **30~60초 주기의 의사결정 인터럽트** — 레벨업 3~4택이 반복 조작의 단조로움을 보완.
4. **위장된 보상** — 스웜 러시·저주 등 "위협처럼 보이는 보상 가속 장치"를 심는다.
5. **손실의 재활용** — 클리어/처치가 영구 해금(모드)으로 전환된다.

## A-2. 런 타임라인 — 30분 각본 (14페이즈)

시간은 초 단위(sec). 무한 모드에서는 `elapsed % 1800` 로 각본이 루프된다.
`gap` = 스폰 간격(초). `immediate` = 페이즈 진입 즉시 1회 스폰(분보스).

| # | 구간 | 내용 | 스폰 규칙 |
|---|---|---|---|
| 0 | 0:00~1:00 | 워밍업 | mob1 gap .45 |
| 1 | 1:00~3:00 | 첫 분보스 + 램프업 | mob1 .30 / mob2 .60 / 보스 1회 |
| 2 | 3:00~5:00 | 상승 | mob2 .35 / mob3 .70 |
| 3 | 5:00~5:40 | ★약졸 스파이크 | mob1 .07 / mob2 .12 |
| 4 | 5:40~9:00 | 본 게임 + 6:00 분보스 | mob3 .35 / mob4 .70 / 보스 1회 |
| 5 | 9:00~10:00 | ★커트라인(튼튼몹) | mob4 .45 |
| 6 | 10:00~13:00 | **진화 개방** + 2분보스 | mob3 .30 / mob4 .50 / 보스 120s |
| 7 | 13:00~16:00 | (13:00 포위) | mob4 .35 / mob5 .55 / 보스 120s |
| 8 | 16:00~20:00 | ★소강 — 빌드 완성 구간 | mob4 .85 / mob5 1.10 |
| 9 | 20:00~24:00 | 재상승 (21:00 포위) | mob4 .40 / mob5 .50 / 보스 120s |
| 10 | 24:00~25:00 | 프리보스 램프 | mob3 .25 / mob5 .30 |
| 11 | 25:00~28:00 | **★스테이지 보스** | mob4 .35 / mob5 .40 / 보스 90s |
| 12 | 28:00~30:00 | ★최대 물량 피날레 | mob1 .12 / mob3 .15 / mob4 .18 / mob5 .20 / 보스 45s |
| 13 | 30:00~ | 계속 도전 구간 | mob5 .18 / 보스 30s |

독립 이벤트 채널 (기본 스폰과 병행):

| 이벤트 | 시점 | 사양 |
|---|---|---|
| 스웜 러시 | 2:00부터 45초마다 (29:50까지) | 체력1 × 60마리(20열×3행, 간격 55/70px), 랜덤 방향 직선 관통, 속도 175~205, 접촉피해 3, expDrop 0.3, 수명 후 조용히 소멸 |
| 포위 이벤트 | 13:00, 21:00 (사이클마다 리셋) | mob4 × 26마리, 반경 560 링, 체력 ×5, 속도 16, 접촉 6, expDrop 0.6, 수명 55초, 경고 배너 |
| 스테이지 보스 | 25:00 (1500s) | 크기 ×1.8·금색 틴트, HP 1500×waveHpMult, 속도 45, 접촉 55, 확정 보물상자 + 금화 10개, **처치 시 하이퍼 모드 해금** |
| 사신 | 29:50 경고 → 30:00부터 1분마다 +1 | 무적(피해 1 캡), 접촉 즉사(99999), 속도 120, 무한 모드에선 미등장 |

## A-3. 무기 시스템 (6종)

### 발사 파이프라인
```
무기 쿨타임 타이머 만료
→ 실효 쿨다운 = 기본CD × stats.cooldown(빈 책) × 진화보정, 하한 0.08s
→ 피해 = 기본피해(레벨) × stats.might(시금치) × 진화보정(×1.5)
→ 발수 = 기본count(레벨) + stats.amount(복제 반지)
→ 크기 = 기본scale × stats.area(촛대)
→ HitSpec{피해, 치명률(=무기crit×행운), 넉백, 관통, 흡혈} 로 투사체 생성
```

### 무기별 사양 (`weaponStats(type, lvl)`, lvl 1~8, l = lvl-1)

| 무기 | 조준 | 명중 방식 | 피해 | 쿨다운(초) | 크기 | 발수 | 치명 | 넉백 |
|---|---|---|---|---|---|---|---|---|
| 🏹 화살 | 최근접 몹 | dynamic(명중 소멸) | 10+6l | 1.0−0.1l (≥0.2) | 1.5 | 1+l/2 | 5% | 90 |
| 🗡️ 검 | 이동 방향 투척·회전 | dynamic | 10+6l | 0.5−0.05l (≥0.12) | 1.8 | 1+l/2 | 5% | 90 |
| 🔗 채찍 | 좌우 ±150 고정(발수↑시 상하/대각) | static(몹당 0.5s 쿨) | 10+8l | 1.0−0.08l (≥0.4) | 1.5+0.2l | 1+l/3 | 0 | 50 |
| 🛡️ 방패 | 반경 150 상시 궤도 | static | 10+5l | 상시 | 2.0 | 개수=lvl | 0 | 150 |
| 🔥 화염구 | 무작위 몹 조준, 5s 비행 | dynamic | 20+10l | 1.0−0.08l (≥0.4) | 0.25+0.03l | 1+l/3 | 0 | 130 |
| ⚡ 번개 | 무작위 몹 위치 강타(0.2s 후 재강타) | static | 10+7l | 1.0−0.08l (≥0.4) | 1.0 | 1+l/2 | 0 | 0 |

- **dynamic**: 명중 즉시 투사체 소멸 (관통 시 유지).
- **static**: 설치/지속형 — 몹마다 0.5초 피격 쿨다운(`canBeAttacked`)으로 중복 타격 제한.
- 치명타 = 무기 기본 치명률 × stats.luck, 성공 시 피해 ×2 + 노란 데미지 숫자.
- 넉백: 피격 방향 반대 벡터를 몹의 잔여속도(_kb)에 가산, 초당 ×(1−7dt) 감쇠.

### 진화 (만렙 8 + 지정 장신구 → 10:00 이후 보물상자에서)

| 무기 | 필요 장신구 | 진화명 | 효과 |
|---|---|---|---|
| 채찍 | 🖤 검은 심장 | 🩸 피의 눈물 | 치명 10% 부여 + 명중 시 흡혈 |
| 화살 | 💪 팔 보호대 | ⚔️ 천 개의 칼날 | 관통 + 발수 +1 + 쿨다운 ×0.4 |
| 검 | 🕯️ 촛대 | 🌀 죽음의 나선 | 8방향 고정 발사 + 관통 |
| 화염구 | 🥬 시금치 | ☄️ 지옥불 | 관통 + 크기 ×1.6 |
| 번개 | 💍 복제 반지 | 🌩️ 뇌운 고리 | 강타 수 ×2 |
| 방패 | 🥋 갑옷 | ✨ 수호자의 서약 | 개수 +2, 크기·피해 ×1.5, 궤도 175, 회전 ×1.7 |

공통: 진화 시 피해 ×1.5, 쿨다운 ×0.75(화살은 ×0.4).

## A-4. 성장 시스템

- **경험치**: 몹 처치 → 💎 보석 드랍(몹별 10~60) → 획득 반경(기본 60, 매혹구로 확장) 내 흡수.
  필요 경험치 = 50 × 1.3^(레벨-1). 획득량 = 보석값 × growth(왕관) × 저주 × 단축(+25%).
- **레벨업**: 엔진 정지 → 선택지 3개(행운 비례 확률로 4개) → 적용 후 재개(연속 레벨업 지원).
  - 선택지 풀 = 보유 무기 강화 + 미보유 무기 + 장신구(슬롯 6) 강화/신규. 전부 만렙이면 치킨/골드.
  - **새로고침 ×2 / 건너뛰기 ×2 / 지우기 ×2** (지우기 = 그 판에서 해당 선택지 영구 제외).
- **장신구 14종** (`PassiveType`, 슬롯 6개):

| 장신구 | 효과/레벨 | 만렙 |
|---|---|---|
| 🥬 시금치 | 피해 +10% | 5 |
| 📖 빈 책 | 쿨타임 −8% | 5 |
| 🕯️ 촛대 | 범위 +10% | 5 |
| 💪 팔 보호대 | 탄속 +10% | 5 |
| 🔮 주문속박기 | 지속 +10% | 5 |
| 💍 복제 반지 | 발수 +1 | 2 |
| 🖤 검은 심장 | 최대체력 +20% | 5 |
| 🍅 붉은 심장 | 초당 회복 +0.2 | 5 |
| 🥋 갑옷 | 받는 피해 −1 | 5 |
| 🪽 날개 | 이속 +10% | 5 |
| 🧲 매혹구 | 획득 반경 +20 | 5 |
| 👑 왕관 | 경험치 +8% | 5 |
| 🍀 클로버 | 행운 +10% (4번째 슬롯·치명) | 5 |
| 💀 미치광이의 두개골 | **저주**: 적 스폰 +25%·체력 +20% ↔ 경험치 +15% | 3 |

- **플레이어**: HP 100(방어력만큼 고정 감산, 최소 1), 피격 후 0.5s 무적, 이속 180×moveMult.

## A-5. 보물상자·골드

- 분보스 처치 → **10:00 이후** + 직전 상자로부터 40초 경과 시 보물상자, 아니면 금화 3개.
- 상자 열기: 진화 가능(만렙+장신구) 시 진화 발동, 골드 20~60. 스테이지 보스는 **확정 상자**.
- 골드: 상자/보스/일반몹 4% 드랍. 하이퍼 모드 ×1.5. (현재 골드는 기록용 — 영구 상점은 미구현)

## A-6. 몹

| 몹 | HP | 접촉피해 | 경험치 | 속도 |
|---|---|---|---|---|
| mob1~mob5 | 10/20/30/40/50 | 5/10/20/25/33 | 10~50 | 60 |
| mobBoss(분보스) | 60 | 50 | 60 | 50 |

- 시간 체력 배율: `waveHpMult = (1 + max(0, tc−120)/60 × 0.35) × 저주 × 하이퍼1.5 × (1+무한사이클)`
- 몹은 플레이어(머리 위 −30px)로 직진 추적. 스폰 링 = 화면 대각선 절반(≈734px).
- 너무 멀어진 몹(>링×1.6)은 스폰 링으로 재배치 (VS 리포지셔닝).
- 빙결(아이템)·자석·물약·올킬 아이템 드랍 0.01~0.02.

## A-7. 클리어 / 모드 / 해금

- **30:00 도달 = STAGE CLEAR** 팝업(+보너스 100골드): "여기서 승리" 또는 "계속 도전"(사신 기록전).
  클리어 후 사망해도 결과 화면은 🏆 승리 스타일 (VS: 사신에게 죽어도 클리어 인정).
- **모드 3종** — 메뉴 토글, 중첩 가능, `shared_preferences` 영구 저장:

| 모드 | 효과 | 해금 조건 |
|---|---|---|
| 🔥 하이퍼 | 적 체력·스폰 +50%, 골드 +50% | 25분 스테이지 보스 처치 |
| ⏩ 단축 | 전체 2배속(HasTimeScale) + 경험치 +25% | 한 판 레벨 30 도달 |
| ♾️ 무한 | 사신·클리어 없음, 30분 각본 루프, 사이클마다 체력 +100%·스폰 +50% | 30분 클리어 |

## A-8. 이식 시 주의 (이번 구현에서 배운 함정)

1. **HasTimeScale**: FlameGame에서 자신의 `update()` 오버라이드는 **스케일 전 dt**를 받는다
   (자식 컴포넌트만 스케일됨). 게임 시계는 `elapsed += dt * timeScale` 로 직접 곱할 것.
2. **SharedPreferences**: 테스트/플러그인 없는 환경에서 `getInstance()`가 예외가 아니라
   **영원히 완료되지 않을 수 있다** → `.timeout()` 가드 + 테스트에서 `setMockInitialValues({})`.
3. **컴포넌트 라이프사이클 큐**: 엔진 일시정지 중 `removeFromParent()`는 큐에만 쌓인다.
   재시작 시 `isMounted` 체크가 통과해버려 조이스틱이 사라지는 류의 버그 발생 —
   재시작 루틴에서는 무조건 `removeFromParent(); add();` 로 재마운트할 것.
4. **flame_test 미사용**: 자체 GameWidget에 오버레이 빌더가 없어 `overlays.add`가 크래시.
   테스트는 직접 `GameWidget + 더미 오버레이 맵`으로 펌프하고, 에셋 디코딩이 실제 async라
   `tester.runAsync(() async { ...; await game.loaded; })` 패턴 필수. 게임 루프 구동은
   `tester.pump(Duration(milliseconds: 16))` 반복 (수동 updateTree는 dt가 주입되지 않음).
5. **데미지 숫자 상한**: 동시 표시 40개 제한 — VS도 후반 프레임 저하의 주범이 데미지 표기다.

---

# PART B. 아키텍처

```
lib/
├── main.dart                  # 오버레이 등록, 가로고정/몰입(모바일), 비트맵폰트 로드
├── game/
│   ├── survivor_game.dart     # 오케스트레이터: 런 상태·레벨업·상자·클리어·모드·배너
│   ├── data.dart              # ★밸런스 테이블: 무기/진화/치명/넉백/몹
│   ├── stats.dart             # ★장신구 14종 + PlayerStats 곱연산 산출
│   ├── meta.dart              # 해금 영구 저장 (shared_preferences)
│   ├── attack_manager.dart    # 무기 쿨타임 루프 + 발사 + 진화 반영
│   ├── weapons.dart           # 투사체/설치형 6종 + HitSpec + 방패 궤도
│   ├── mob.dart               # 몹: 추적/넉백/피격(dynamic·static)/사망 드랍/보스·사신
│   ├── mob_manager.dart       # ★30분 각본 스포너 + 스웜/포위/보스/사신 이벤트
│   ├── player.dart            # 이동/무적/회복/접촉 피해
│   ├── exp_up.dart            # 경험치 보석 (흡수 반경/자석)
│   ├── item.dart              # 드랍 아이템 4종 (자석/빙결/물약/올킬)
│   ├── fx.dart                # 보물상자·금화·데미지숫자·폭발
│   ├── audio.dart / sprites.dart / background.dart
├── overlays/                  # menu(모드 토글)/hud/levelup/chest/clear/pause/gameover
└── ui/bitmap_font.dart        # 원작 AngelCode 비트맵 폰트 렌더러
test/game_logic_test.dart      # 22개 — 전투/레벨업/진화/이벤트/모드/클리어 검증
```

데이터 흐름 (1프레임):
```
GameLoop → SurvivorGame.update(elapsed·클리어 판정)
         → MobSpawner.update(각본 스폰 + 이벤트 + 사신)
         → AttackManager.update(쿨타임 → HitSpec 생성 → 투사체 add)
         → 투사체/몹 충돌 → Mob.takeDamage/hitByStatic → 사망 → 드랍
         → ExpUp 흡수 → gainExp → (가득) 레벨업 인터럽트 → 선택 → recomputeStats
```

---

# PART C. 핵심 소스 전문

아래는 전투 시스템 핵심 파일의 전체 소스다 (UI 오버레이·에셋 로더는 저장소 참조).

## lib/game/data.dart

```dart
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

```

## lib/game/stats.dart

```dart
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
  skull, // 미치광이의 두개골: 저주 — 적 스폰/체력↑, 경험치↑ (리스크 교환)
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
  PassiveType.skull: PassiveDef(
      '미치광이의 두개골', '💀', '저주: 적 스폰 +25%·체력 +20%, 경험치 +15%', 3),
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
  // 저주(리스크 교환): 적 스폰 빈도·체력을 올리는 대신 경험치 가속
  double curseSpawn = 1;
  double curseHp = 1;
  double curseExp = 1;

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
    s.curseSpawn = 1 + 0.25 * l(PassiveType.skull);
    s.curseHp = 1 + 0.20 * l(PassiveType.skull);
    s.curseExp = 1 + 0.15 * l(PassiveType.skull);
    return s;
  }
}

```

## lib/game/meta.dart

```dart
import 'package:shared_preferences/shared_preferences.dart';

/// 런 밖 영구 진행(해금) 저장 — VS의 모드 해금 방식.
/// 저장 실패(테스트 등 플러그인 없음)해도 게임 진행엔 지장 없도록 전부 방어적.
class MetaProgress {
  bool hyperUnlocked = false; // 25분 스테이지 보스 처치
  bool turboUnlocked = false; // 한 판에서 레벨 30 도달
  bool endlessUnlocked = false; // 30분 생존 클리어

  static const _kHyper = 'meta.hyper';
  static const _kTurbo = 'meta.turbo';
  static const _kEndless = 'meta.endless';

  // 테스트 등 플러그인 없는 환경에서 플랫폼 채널이 영원히 응답하지 않을 수 있어
  // 타임아웃으로 방어한다 (실기기/웹에서는 수 ms 안에 완료됨).
  static Future<SharedPreferences> _prefs() =>
      SharedPreferences.getInstance().timeout(const Duration(seconds: 3));

  static Future<MetaProgress> load() async {
    final m = MetaProgress();
    try {
      final p = await _prefs();
      m.hyperUnlocked = p.getBool(_kHyper) ?? false;
      m.turboUnlocked = p.getBool(_kTurbo) ?? false;
      m.endlessUnlocked = p.getBool(_kEndless) ?? false;
    } catch (_) {}
    return m;
  }

  Future<void> save() async {
    try {
      final p = await _prefs();
      await p.setBool(_kHyper, hyperUnlocked);
      await p.setBool(_kTurbo, turboUnlocked);
      await p.setBool(_kEndless, endlessUnlocked);
    } catch (_) {}
  }
}

```

## lib/game/survivor_game.dart

```dart
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data.dart';
import 'stats.dart';
import 'meta.dart';
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
    with HasCollisionDetection, KeyboardEvents, HasTimeScale {
  SurvivorGame()
      : super(
          camera: CameraComponent.withFixedResolution(width: 1280, height: 720),
        );

  // ---- 런 타임라인 (VS 표준 30분) ----
  static const double kRunSeconds = 1800; // 30:00 사신/클리어
  static const double kStageBossAt = 1500; // 25:00 스테이지 보스
  static const double kChestGateAt = 600; // 10:00 진화 상자 개방

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

  // 30분 생존 클리어 (VS: 제한시간 도달 = 스테이지 클리어)
  bool cleared = false;
  static const int kClearBonusGold = 100;

  // ---- 모드 (VS식 해금 토글, 중첩 가능) ----
  MetaProgress meta = MetaProgress();
  bool modeHyper = false; // 하이퍼: 적 강화 + 골드 보너스
  bool modeTurbo = false; // 단축: 2배속 + 경험치 +25%
  bool modeEndless = false; // 무한: 30분 루프, 사이클마다 강화
  bool endlessJustUnlocked = false; // 클리어 화면 안내용
  bool stageBossKilled = false;

  /// 무한 모드 사이클 (0부터). 일반 모드는 항상 0.
  int get endlessCycle =>
      modeEndless ? (elapsed ~/ kRunSeconds).clamp(0, 99) : 0;

  /// 웨이브 각본 기준 시간 (무한 모드는 30분마다 처음부터 반복)
  double get cycleTime => modeEndless ? elapsed % kRunSeconds : elapsed;

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
    meta = await MetaProgress.load();

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
    timeScale = 1.0;
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
    stageBossKilled = false;
    endlessJustUnlocked = false;
    banner.value = null;
    escPaused = false;
    // 단축 모드: 전체 2배속 (모드 플래그는 메뉴에서 선택되어 유지됨)
    timeScale = modeTurbo ? 2.0 : 1.0;
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
    // 재시작 안전: 직전 게임오버에서 제거가 큐에 남아 있어도 항상 새로 마운트
    joystick.removeFromParent();
    camera.viewport.add(joystick);
    isRunning = true;
    audio.startBgm();
    resumeEngine();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isRunning) return;
    // 주의: 이 오버라이드는 HasTimeScale 스케일링 이전의 dt를 받으므로
    // 게임 시계는 직접 배속을 곱한다 (자식 컴포넌트는 믹스인이 스케일).
    elapsed += dt * timeScale;
    // 30:00 도달 = 스테이지 클리어 (무한 모드는 계속 루프)
    if (!modeEndless && !cleared && elapsed >= kRunSeconds) {
      cleared = true;
      gold += kClearBonusGold;
      if (!meta.endlessUnlocked) {
        meta.endlessUnlocked = true;
        endlessJustUnlocked = true;
        meta.save();
      }
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

  /// 시간 경과 몹 체력 배율 (VS: 웨이브가 갈수록 강해짐)
  /// × 저주 × 하이퍼(+50%) × 무한 사이클(+100%/사이클)
  double get waveHpMult =>
      (1 + math.max(0, cycleTime - 120) / 60 * 0.35) *
      stats.curseHp *
      (modeHyper ? 1.5 : 1.0) *
      (1 + endlessCycle);

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

  /// 25분 스테이지 보스 처치 → 하이퍼 모드 해금 (VS 규칙)
  void onStageBossKilled() {
    stageBossKilled = true;
    if (!meta.hyperUnlocked) {
      meta.hyperUnlocked = true;
      meta.save();
      showBanner('🔓 하이퍼 모드 해금! (메뉴에서 선택)', 5);
    } else {
      showBanner('💥 스테이지 보스 격파!', 3);
    }
  }

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
    // 하이퍼 모드: 골드 +50% (VS 하이퍼의 골드 보너스)
    gold += (amount * (modeHyper ? 1.5 : 1.0)).round();
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
    // 단축 모드: 경험치 +25% (VS 단축 모드 보너스)
    exp += amount * stats.growth * stats.curseExp * (modeTurbo ? 1.25 : 1.0);
    if (exp >= maxExp) _levelUp();
  }

  void _levelUp() {
    level++;
    // 해금: 한 판에서 레벨 30 도달 → 단축 모드
    if (level >= 30 && !meta.turboUnlocked) {
      meta.turboUnlocked = true;
      meta.save();
      showBanner('🔓 단축 모드 해금! (메뉴에서 선택)', 4);
    }
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
    timeScale = 1.0;
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

```

## lib/game/attack_manager.dart

```dart
import 'dart:math' as math;
import 'package:flame/components.dart';

import 'data.dart';
import 'survivor_game.dart';
import 'weapons.dart';

/// 레벨업 선택으로 무기를 획득/강화하고, 만렙+장신구 조합 시 진화하는 매니저.
/// 발사 시 캐릭터 스탯(피해량/쿨타임/범위/탄속/투사체수)을 곱연산 적용 (VS 방식).
class AttackManager extends Component with HasGameReference<SurvivorGame> {
  final Map<WeaponType, int> levels = {};
  final Map<WeaponType, double> _timers = {};
  final Set<WeaponType> evolved = {};
  double shieldAngle = 0.05;

  void reset() {
    levels.clear();
    _timers.clear();
    evolved.clear();
    shieldAngle = 0.05;
    game.shieldAngle = 0.05;
    game.world.children
        .whereType<ShieldOrb>()
        .forEach((s) => s.removeFromParent());
    addWeapon(WeaponType.arrow); // 시작 무기
  }

  int levelOf(WeaponType t) => levels[t] ?? 0;
  bool owns(WeaponType t) => levelOf(t) > 0;
  bool isEvolved(WeaponType t) => evolved.contains(t);
  Map<WeaponType, int> get ownedLevels =>
      {for (final e in levels.entries) e.key: e.value};

  void addWeapon(WeaponType t) {
    levels[t] = 1;
    _timers[t] = 0;
    if (t == WeaponType.shield) refreshShields();
  }

  void upgrade(WeaponType t) {
    levels[t] = levelOf(t) + 1;
    if (t == WeaponType.shield) refreshShields();
  }

  /// 진화 (보물상자에서 호출)
  void evolve(WeaponType t) {
    evolved.add(t);
    if (t == WeaponType.shield) {
      game.shieldAngle = shieldAngle * 1.7;
      refreshShields();
    }
  }

  /// 스탯/레벨 변화 후 방패 오브 재구성
  void refreshShields() {
    if (!owns(WeaponType.shield)) return;
    final lvl = levelOf(WeaponType.shield);
    final evo = isEvolved(WeaponType.shield);
    final s = weaponStats(WeaponType.shield, lvl);
    final st = game.stats;
    final count = lvl + st.amount + (evo ? 2 : 0);
    final dmg = s.damage * st.might * (evo ? 1.5 : 1.0);
    final scale = s.scale * st.area * (evo ? 1.5 : 1.0);
    final radius = evo ? 175.0 : 150.0;
    final spec = HitSpec(dmg,
        knock: kWeaponKnock[WeaponType.shield]!,
        critChance: kWeaponCrit[WeaponType.shield]!);
    game.world.children
        .whereType<ShieldOrb>()
        .forEach((o) => o.removeFromParent());
    for (int i = 0; i < count; i++) {
      final theta = (math.pi * 2 / count) * i;
      game.world.add(ShieldOrb(theta, spec, scale, orbitRadius: radius));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isRunning) return;
    for (final t in levels.keys) {
      if (t == WeaponType.shield) continue;
      final s = weaponStats(t, levels[t]!);
      var cd = s.cooldown * game.stats.cooldown;
      if (isEvolved(t)) {
        cd *= (t == WeaponType.arrow) ? 0.4 : 0.75; // 천 개의 칼날: 연사
      }
      cd = math.max(cd, 0.08);
      _timers[t] = (_timers[t] ?? 0) + dt;
      if (_timers[t]! >= cd) {
        _timers[t] = 0;
        _fire(t, s);
      }
    }
  }

  void _fire(WeaponType t, WStats s) {
    game.audio.shoot();
    final st = game.stats;
    final p = game.player.position;
    final evo = isEvolved(t);
    final dmg = s.damage * st.might * (evo ? 1.5 : 1.0);
    final count = s.count + st.amount + (evo && t == WeaponType.arrow ? 1 : 0);
    final scale = s.scale * st.area * (evo && t == WeaponType.fireball ? 1.6 : 1.0);
    final crit = (t == WeaponType.whip && evo) ? 0.10 : kWeaponCrit[t]!;
    final spec = HitSpec(dmg,
        critChance: crit,
        knock: kWeaponKnock[t]!,
        pierce: evo &&
            (t == WeaponType.arrow ||
                t == WeaponType.sword ||
                t == WeaponType.fireball),
        healOnHit: evo && t == WeaponType.whip);

    switch (t) {
      case WeaponType.arrow:
        for (int i = 0; i < count; i++) {
          final spread = (i - (count - 1) / 2) * 0.18;
          game.world.add(Arrow(p, spec, scale, spread: spread));
        }
        break;
      case WeaponType.sword:
        if (evo) {
          // 죽음의 나선: 8방향 관통
          for (int i = 0; i < 8; i++) {
            final a = math.pi * 2 / 8 * i;
            game.world.add(Sword(p, spec, scale,
                fixedDir: Vector2(math.cos(a), math.sin(a))));
          }
        } else {
          for (int i = 0; i < count; i++) {
            final spread = (i - (count - 1) / 2) * 0.22;
            game.world.add(Sword(p, spec, scale, spread: spread));
          }
        }
        break;
      case WeaponType.fireball:
        for (int i = 0; i < count; i++) {
          game.world.add(Fireball(p, spec, scale));
        }
        break;
      case WeaponType.whip:
        _fireWhip(p, spec, scale, count);
        break;
      case WeaponType.lightning:
        final strikes = evo ? count * 2 : count; // 뇌운 고리: 두 배 강타
        for (int i = 0; i < strikes; i++) {
          final m = game.randomMob();
          if (m != null) game.world.add(Lightning(m.position, spec, scale));
        }
        game.add(TimerComponent(
          period: 0.2,
          repeat: false,
          removeOnFinish: true,
          onTick: () {
            for (int i = 0; i < strikes; i++) {
              final m = game.randomMob();
              if (m != null) {
                game.world.add(Lightning(m.position, spec, scale));
              }
            }
          },
        ));
        break;
      case WeaponType.shield:
        break;
    }
  }

  void _fireWhip(Vector2 p, HitSpec spec, double scale, int count) {
    final left = game.player.facing < 0;
    final dirs = <Vector2>[Vector2(1, 0), Vector2(-1, 0)];
    if (count >= 2) dirs.addAll([Vector2(0, 1), Vector2(0, -1)]);
    if (count >= 3) dirs.addAll([Vector2(1, 1), Vector2(-1, -1)]);
    for (final d in dirs) {
      final pos = p + d.normalized() * 150;
      game.world
          .add(Whip(pos, left && d.x == 0 ? true : d.x < 0, spec, scale));
    }
  }
}

```

## lib/game/weapons.dart

```dart
import 'dart:math' as math;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import 'survivor_game.dart';
import 'mob.dart';

/// 한 발의 공격 사양 — 피해/치명타/넉백/관통 (VS 전투 규칙)
class HitSpec {
  final double damage;
  final double critChance; // 행운 적용 전 기본 확률
  final double knock;
  final bool pierce;
  final bool healOnHit; // 피의 눈물: 명중 시 회복
  const HitSpec(this.damage,
      {this.critChance = 0,
      this.knock = 0,
      this.pierce = false,
      this.healOnHit = false});
}

/// 명중 처리 공통 — 치명타 굴림 후 몹에 피해 적용
void _applyHit(SurvivorGame game, Mob mob, HitSpec spec, Vector2 from,
    {bool isStatic = false}) {
  final critRoll =
      spec.critChance > 0 && game.rng.nextDouble() < spec.critChance * game.stats.luck;
  final dmg = critRoll ? spec.damage * 2 : spec.damage;
  if (isStatic) {
    final could = mob.canBeAttacked;
    mob.hitByStatic(dmg, crit: critRoll, from: from, knock: spec.knock);
    if (could && spec.healOnHit) game.player.heal(1);
  } else {
    mob.takeDamage(dmg, crit: critRoll, from: from, knock: spec.knock);
    if (spec.healOnHit) game.player.heal(1);
  }
}

class Arrow extends SpriteComponent
    with HasGameReference<SurvivorGame>, CollisionCallbacks {
  Arrow(Vector2 pos, this.spec, double sc, {this.spread = 0})
      : super(
            position: pos.clone(),
            anchor: Anchor.center,
            size: Vector2(16, 16) * sc);
  final HitSpec spec;
  final double spread;
  double _life = 1.5;
  late Vector2 _vel;
  final Set<Mob> _hit = {};

  @override
  Future<void> onLoad() async {
    sprite = game.gfx.arrow;
    _life = 1.5 * game.stats.duration;
    final closest = game.closestMob();
    if (closest == null) {
      _vel = Vector2(0, -250);
    } else {
      final dx = closest.position.x - position.x;
      final dy = closest.position.y - position.y;
      final root = math.sqrt(dx * dx + dy * dy) / 2;
      _vel = Vector2((dx / root) * 250, (dy / root) * 250 + 30);
      angle = math.atan2(dy, dx) + math.pi / 2 + math.pi / 4;
    }
    if (spread != 0) {
      _vel.rotate(spread);
      angle += spread;
    }
    _vel.scale(game.stats.projSpeed);
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += _vel * dt;
    _life -= dt;
    if (_life <= 0) removeFromParent();
  }

  @override
  void onCollisionStart(Set<Vector2> p, PositionComponent other) {
    super.onCollisionStart(p, other);
    if (other is Mob && !_hit.contains(other)) {
      _hit.add(other);
      _applyHit(game, other, spec, position);
      if (!spec.pierce) removeFromParent();
    }
  }
}

class Sword extends SpriteComponent
    with HasGameReference<SurvivorGame>, CollisionCallbacks {
  Sword(Vector2 pos, this.spec, double sc, {this.spread = 0, this.fixedDir})
      : super(
            position: pos.clone(),
            anchor: Anchor.center,
            size: Vector2(16, 16) * sc);
  final HitSpec spec;
  final double spread;
  final Vector2? fixedDir; // 죽음의 나선: 8방향 고정
  double _life = 1.5;
  late Vector2 _vel;
  final Set<Mob> _hit = {};

  @override
  Future<void> onLoad() async {
    sprite = game.gfx.sword;
    _life = 1.5 * game.stats.duration;
    final dir = fixedDir ??
        (game.lastMoveDir.length2 > 0.001
            ? game.lastMoveDir.normalized()
            : Vector2(game.player.facing.toDouble(), 0));
    _vel = (dir * 500)..rotate(spread);
    _vel.scale(game.stats.projSpeed);
    angle = math.pi / 2 + math.pi / 4;
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += _vel * dt;
    angle += 12 * dt;
    _life -= dt;
    if (_life <= 0) removeFromParent();
  }

  @override
  void onCollisionStart(Set<Vector2> p, PositionComponent other) {
    super.onCollisionStart(p, other);
    if (other is Mob && !_hit.contains(other)) {
      _hit.add(other);
      _applyHit(game, other, spec, position);
      if (!spec.pierce) removeFromParent();
    }
  }
}

class Whip extends SpriteAnimationComponent
    with HasGameReference<SurvivorGame>, CollisionCallbacks {
  Whip(Vector2 pos, this.headingLeft, this.spec, double sc)
      : super(
            position: pos.clone(),
            anchor: Anchor.center,
            size: Vector2(65, 27) * sc);
  final bool headingLeft;
  final HitSpec spec;

  @override
  Future<void> onLoad() async {
    animation = game.gfx.whipAnim.clone();
    if (headingLeft) flipHorizontally();
    add(RectangleHitbox());
    add(RemoveEffect(delay: 0.2 * game.stats.duration));
  }

  @override
  void onCollisionStart(Set<Vector2> p, PositionComponent other) {
    super.onCollisionStart(p, other);
    if (other is Mob) {
      _applyHit(game, other, spec, game.player.position, isStatic: true);
    }
  }
}

class Lightning extends SpriteAnimationComponent
    with HasGameReference<SurvivorGame>, CollisionCallbacks {
  Lightning(Vector2 pos, this.spec, double sc)
      : super(
            position: pos.clone()..y += 30,
            anchor: Anchor.center,
            size: Vector2(72, 72) * sc);
  final HitSpec spec;

  @override
  Future<void> onLoad() async {
    animation = game.gfx.lightningAnim.clone();
    add(RectangleHitbox());
    add(RemoveEffect(delay: 0.4 * game.stats.duration));
  }

  @override
  void onCollisionStart(Set<Vector2> p, PositionComponent other) {
    super.onCollisionStart(p, other);
    if (other is Mob) {
      _applyHit(game, other, spec, position, isStatic: true);
    }
  }
}

class Fireball extends SpriteAnimationComponent
    with HasGameReference<SurvivorGame>, CollisionCallbacks {
  Fireball(Vector2 pos, this.spec, double sc)
      : super(
            position: pos.clone(),
            anchor: Anchor.center,
            size: Vector2(512, 384) * sc);
  final HitSpec spec;
  double _life = 5.0;
  late Vector2 _vel;
  final Set<Mob> _hit = {};

  @override
  Future<void> onLoad() async {
    animation = game.gfx.fireballAnim.clone();
    _life = 5.0 * game.stats.duration;
    final target = game.randomMob();
    if (target == null) {
      _vel = Vector2(0, -250);
    } else {
      final dx = target.position.x - position.x;
      final dy = target.position.y - position.y;
      final root = math.sqrt(dx * dx + dy * dy) / 2;
      final drift = spec.pierce ? 0 : 30; // 지옥불은 정조준
      _vel = Vector2((dx / root) * 150, (dy / root) * 150 + drift);
      angle = math.atan2(dy, dx);
    }
    _vel.scale(game.stats.projSpeed);
    add(CircleHitbox(radius: size.y * 0.28, anchor: Anchor.center)
      ..position = size / 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += _vel * dt;
    _life -= dt;
    if (_life <= 0) removeFromParent();
  }

  @override
  void onCollisionStart(Set<Vector2> p, PositionComponent other) {
    super.onCollisionStart(p, other);
    if (other is Mob && !_hit.contains(other)) {
      _hit.add(other);
      _applyHit(game, other, spec, position);
      if (!spec.pierce) removeFromParent();
    }
  }
}

/// 플레이어 주위를 회전하는 방패
class ShieldOrb extends SpriteComponent
    with HasGameReference<SurvivorGame>, CollisionCallbacks {
  ShieldOrb(this.theta, this.spec, double sc, {this.orbitRadius = 150})
      : super(anchor: Anchor.center, size: Vector2(16, 16) * sc);
  double theta;
  final HitSpec spec;
  final double orbitRadius;

  @override
  Future<void> onLoad() async {
    sprite = game.gfx.shield;
    add(CircleHitbox());
    _place();
  }

  void _place() {
    position = game.player.position +
        Vector2(math.cos(theta), math.sin(theta)) * orbitRadius;
  }

  @override
  void update(double dt) {
    super.update(dt);
    theta += game.shieldAngle;
    _place();
  }

  @override
  void onCollisionStart(Set<Vector2> p, PositionComponent other) {
    super.onCollisionStart(p, other);
    if (other is Mob) {
      _applyHit(game, other, spec, game.player.position, isStatic: true);
    }
  }

  @override
  void onCollision(Set<Vector2> p, PositionComponent other) {
    super.onCollision(p, other);
    if (other is Mob) {
      _applyHit(game, other, spec, game.player.position, isStatic: true);
    }
  }
}

/// 몹 사망 시 폭발 애니메이션
class Explosion extends SpriteAnimationComponent
    with HasGameReference<SurvivorGame> {
  Explosion(Vector2 pos)
      : super(
            position: pos.clone()..y += 30,
            anchor: Anchor.center,
            size: Vector2(32, 32) * 2);

  @override
  Future<void> onLoad() async {
    animation = game.gfx.explodeAnim.clone();
    add(RemoveEffect(delay: 0.4));
  }
}

```

## lib/game/mob.dart

```dart
import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import 'data.dart';
import 'survivor_game.dart';
import 'weapons.dart';
import 'exp_up.dart';
import 'item.dart';
import 'fx.dart';

class Mob extends SpriteAnimationComponent
    with HasGameReference<SurvivorGame>, CollisionCallbacks {
  Mob({
    required this.config,
    required Vector2 position,
    required this.expDropRate,
    required this.itemDropRate,
    double hpMult = 1.0,
    this.isReaper = false,
    this.isStageBoss = false, // 25분 보스: 거대·확정 상자·하이퍼 해금
    this.chargeDir, // 스웜: 고정 방향 직진 (추적 안 함)
    this.lifespan, // 수명(초) — 지나면 조용히 소멸 (스웜/포위 이벤트용)
    double? hpOverride,
    double? speedOverride,
    double? damageOverride,
  }) : super(
          position: position,
          size: config.displaySize *
              (isReaper ? 1.3 : (isStageBoss ? 1.8 : 1.0)),
          anchor: Anchor.center,
        ) {
    hp = hpOverride ?? config.hp * hpMult * (isReaper ? 99999 : 1);
    speed = speedOverride ?? (isReaper ? 120 : config.speed);
    contactDamage =
        damageOverride ?? (isReaper ? 99999 : config.contactDamage);
  }

  final MobConfig config;
  final double expDropRate;
  final double itemDropRate;
  final bool isReaper; // 사신: 사실상 불사, 즉사급 접촉 피해
  final bool isStageBoss;
  final Vector2? chargeDir;
  double? lifespan;
  late double hp;
  late double speed;
  late double contactDamage;

  bool canBeAttacked = true; // 정적 무기용 500ms 쿨다운
  double _flash = 0;
  bool frozen = false;
  final Vector2 _kb = Vector2.zero(); // 넉백 잔여 속도

  static const _hitColor = Color(0xFFDB4455);
  static const _reaperColor = Color(0xFF551133);

  @override
  Future<void> onLoad() async {
    animation = game.gfx.mobRun[config.key]!.clone();
    if (isReaper) {
      paint.colorFilter =
          const ColorFilter.mode(_reaperColor, BlendMode.modulate);
    } else if (isStageBoss) {
      paint.colorFilter =
          const ColorFilter.mode(Color(0xFFFFCC66), BlendMode.modulate);
    }
    final r = config.hitRadius * (isStageBoss ? 1.8 : 1.0);
    add(CircleHitbox(radius: r, anchor: Anchor.center)..position = size / 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_flash > 0) {
      _flash -= dt;
      if (_flash <= 0 && !isReaper) paint.colorFilter = null;
    }
    // 넉백 적용 (감쇠)
    if (_kb.length2 > 4) {
      position += _kb * dt;
      _kb.scale(math.max(0, 1 - dt * 7));
    }
    if (frozen && !isReaper) return;

    // 수명 만료 → 조용히 소멸 (킬 카운트/드랍 없음)
    if (lifespan != null) {
      lifespan = lifespan! - dt;
      if (lifespan! <= 0) {
        removeFromParent();
        return;
      }
    }

    // 스웜(돌격형): 플레이어 추적 없이 고정 방향 직진
    if (chargeDir != null) {
      position += chargeDir! * speed * dt;
      flipHorizontally2(chargeDir!.x < 0);
      if (hp <= 0) die();
      return;
    }

    // 너무 멀어진 몹은 스폰 링으로 재배치 (VS의 몹 리포지셔닝)
    if (!isReaper && lifespan == null) {
      final distSq = position.distanceToSquared(game.player.position);
      final ring = game.spawner.spawnRadius;
      if (distSq > ring * ring * 2.6) {
        final a = game.rng.nextDouble() * math.pi * 2;
        position = game.player.position +
            Vector2(math.cos(a), math.sin(a)) * ring;
      }
    }

    // 플레이어(머리 위 -30) 방향으로 이동
    final target = game.player.position - Vector2(0, 30);
    final dir = target - position;
    if (dir.length2 > 1) {
      dir.normalize();
      position += dir * speed * dt;
    }
    flipHorizontally2(position.x > game.player.position.x);
    if (hp <= 0) die();
  }

  bool _flipped = false;
  void flipHorizontally2(bool left) {
    if (left != _flipped) {
      _flipped = left;
      flipHorizontally();
    }
  }

  /// 투사체(dynamic) 직접 피해
  void takeDamage(double dmg,
      {bool crit = false, Vector2? from, double knock = 0}) {
    if (isReaper) dmg = math.min(dmg, 1); // 사신은 사실상 불사
    hp -= dmg;
    _displayHit();
    _applyKnock(from, knock);
    game.spawnDamageText(dmg, position, crit: crit);
    if (hp <= 0) die();
  }

  /// 정적 무기 피해 — 500ms 쿨다운 (원작 Survivor 방식 유지)
  void hitByStatic(double dmg,
      {bool crit = false, Vector2? from, double knock = 0}) {
    if (!canBeAttacked) return;
    if (isReaper) dmg = math.min(dmg, 1);
    hp -= dmg;
    _displayHit();
    _applyKnock(from, knock);
    game.spawnDamageText(dmg, position, crit: crit);
    canBeAttacked = false;
    add(TimerComponent(
        period: 0.5,
        repeat: false,
        removeOnFinish: true,
        onTick: () => canBeAttacked = true));
    if (hp <= 0) die();
  }

  void _applyKnock(Vector2? from, double knock) {
    if (knock <= 0 || isReaper) return;
    final dir = from == null
        ? (position - game.player.position)
        : (position - from);
    if (dir.length2 < 0.001) return;
    dir.normalize();
    _kb.add(dir * knock);
  }

  void _displayHit() {
    paint.colorFilter = const ColorFilter.mode(_hitColor, BlendMode.modulate);
    _flash = 0.2;
  }

  bool _dead = false;
  void die() {
    if (_dead || !isMounted) return;
    _dead = true;
    game.world.add(Explosion(position));
    if (game.rng.nextDouble() < expDropRate) {
      game.world.add(ExpUp(config: config, mobPosition: position));
    }
    if (game.rng.nextDouble() < itemDropRate) {
      game.world
          .add(ItemDrop(mobPosition: position, isBoss: config.key == 'mobBoss'));
    }
    final isBoss = config.key == 'mobBoss';
    if (isStageBoss) {
      // 25분 스테이지 보스: 확정 보물상자 + 금화 소나기 + 하이퍼 해금
      game.lastChestAt = game.elapsed;
      game.world.add(TreasureChest(position: position.clone()));
      for (var i = 0; i < 10; i++) {
        game.world.add(GoldCoin(
            position: position +
                Vector2(game.rng.nextDouble() * 160 - 80,
                    game.rng.nextDouble() * 120 - 60),
            value: 5));
      }
      game.onStageBossKilled();
    } else if (isBoss && !isReaper) {
      // 분보스: 보물상자(쿨다운) 또는 금화 다발 (VS: 보스는 보물상자 드랍)
      // 진화 게이트: 10분 이후 보스부터 상자 개방 (VS의 10분 상자 게이트)
      if (game.elapsed >= SurvivorGame.kChestGateAt &&
          game.elapsed - game.lastChestAt > 40) {
        game.lastChestAt = game.elapsed;
        game.world.add(TreasureChest(position: position.clone()));
      } else {
        for (var i = 0; i < 3; i++) {
          game.world.add(GoldCoin(
              position: position +
                  Vector2(game.rng.nextDouble() * 60 - 30,
                      game.rng.nextDouble() * 40 - 20),
              value: 5));
        }
      }
    } else if (game.rng.nextDouble() < 0.04) {
      game.world.add(GoldCoin(position: position.clone(), value: 1));
    }
    game.onMobKilled();
    removeFromParent();
  }
}

```

## lib/game/mob_manager.dart

```dart
import 'dart:math' as math;
import 'package:flame/components.dart';

import 'data.dart';
import 'survivor_game.dart';
import 'mob.dart';

class SpawnRule {
  final String mobKey;
  final double gap; // 초
  final double expDrop;
  final double itemDrop;
  double timer = 0;
  SpawnRule(this.mobKey, this.gap, this.expDrop, this.itemDrop,
      {bool immediate = false}) {
    if (immediate) timer = gap; // 페이즈 진입 즉시 1회 스폰 (분보스용)
  }
}

/// VS 표준 30분 각본 (VS_BALANCE.md):
/// 워밍업 → 5분 스파이크 → 9분 커트라인 → 10분 진화 개방 → 16~20분 소강 →
/// 25분 스테이지 보스 → 28~30분 최대 물량 → 30분 사신.
/// + 스웜 러시(2분~, 45초), 포위(13분·21분), 무한 모드는 30분 루프+사이클 강화.
class MobSpawner extends Component with HasGameReference<SurvivorGame> {
  List<SpawnRule> _rules = [];
  int _phase = -1;
  int _cycle = 0;
  int reaperCount = 0;
  bool ring1Done = false, ring2Done = false;
  bool stageBossSpawned = false;
  double _swarmTimer = 0;

  bool get reaperSpawned => reaperCount > 0;

  late final double spawnRadius;

  MobSpawner() {
    // 고정 해상도 대각선 절반 (원작 getRandomPosition)
    spawnRadius = math.sqrt(1280 * 1280 + 720 * 720) / 2;
  }

  void reset() {
    _phase = -1;
    _cycle = 0;
    _rules = [];
    reaperCount = 0;
    ring1Done = ring2Done = false;
    stageBossSpawned = false;
    _swarmTimer = 0;
    _applyPhase(0);
    // 시작 시 즉시 한 마리 (원작 create()의 new Mob(...mob1...))
    _spawn('mob1', 0.9, 0.01);
  }

  /// 30분 각본. 경계는 _phaseForTime 과 쌍 (사이클 시간 기준).
  List<SpawnRule> _rulesForPhase(int phase) {
    switch (phase) {
      case 0: // 0:00~1:00 워밍업
        return [SpawnRule('mob1', 0.45, 0.9, 0.01)];
      case 1: // 1:00~3:00 첫 분보스 + 램프업
        return [
          SpawnRule('mob1', 0.30, 0.9, 0.01),
          SpawnRule('mob2', 0.60, 0.8, 0.01),
          SpawnRule('mobBoss', 9999, 0.5, 0.01, immediate: true),
        ];
      case 2: // 3:00~5:00
        return [
          SpawnRule('mob2', 0.35, 0.8, 0.01),
          SpawnRule('mob3', 0.70, 0.7, 0.01),
        ];
      case 3: // 5:00~5:40 ★1차 스파이크: 약졸 러시
        return [
          SpawnRule('mob1', 0.07, 0.8, 0.01),
          SpawnRule('mob2', 0.12, 0.7, 0.01),
        ];
      case 4: // 5:40~9:00 + 6:00 분보스
        return [
          SpawnRule('mob3', 0.35, 0.7, 0.01),
          SpawnRule('mob4', 0.70, 0.6, 0.01),
          SpawnRule('mobBoss', 9999, 0.5, 0.01, immediate: true),
        ];
      case 5: // 9:00~10:00 ★커트라인: 튼튼몹 (VS 9분 거대박쥐)
        return [SpawnRule('mob4', 0.45, 0.6, 0.01)];
      case 6: // 10:00~13:00 진화 개방 + 2분마다 분보스
        return [
          SpawnRule('mob3', 0.30, 0.7, 0.01),
          SpawnRule('mob4', 0.50, 0.6, 0.01),
          SpawnRule('mobBoss', 120, 0.5, 0.01, immediate: true),
        ];
      case 7: // 13:00~16:00 (13:00 포위 이벤트)
        return [
          SpawnRule('mob4', 0.35, 0.6, 0.01),
          SpawnRule('mob5', 0.55, 0.5, 0.01),
          SpawnRule('mobBoss', 120, 0.5, 0.01, immediate: true),
        ];
      case 8: // 16:00~20:00 ★소강: 느리고 튼튼 (빌드 완성 구간)
        return [
          SpawnRule('mob4', 0.85, 0.6, 0.02),
          SpawnRule('mob5', 1.10, 0.5, 0.02),
        ];
      case 9: // 20:00~24:00 재상승 (21:00 포위 이벤트)
        return [
          SpawnRule('mob4', 0.40, 0.6, 0.01),
          SpawnRule('mob5', 0.50, 0.5, 0.01),
          SpawnRule('mobBoss', 120, 0.5, 0.01, immediate: true),
        ];
      case 10: // 24:00~25:00 프리보스 램프
        return [
          SpawnRule('mob3', 0.25, 0.7, 0.01),
          SpawnRule('mob5', 0.30, 0.5, 0.01),
        ];
      case 11: // 25:00~28:00 스테이지 보스 페이즈
        return [
          SpawnRule('mob4', 0.35, 0.6, 0.01),
          SpawnRule('mob5', 0.40, 0.5, 0.01),
          SpawnRule('mobBoss', 90, 0.5, 0.01, immediate: true),
        ];
      case 12: // 28:00~30:00 ★최대 물량 (피날레)
        return [
          SpawnRule('mob1', 0.12, 0.9, 0.01),
          SpawnRule('mob3', 0.15, 0.7, 0.01),
          SpawnRule('mob4', 0.18, 0.6, 0.01),
          SpawnRule('mob5', 0.20, 0.5, 0.01),
          SpawnRule('mobBoss', 45, 0.5, 0.01, immediate: true),
        ];
      default: // 30:00~ (일반 모드 계속 도전 구간)
        return [
          SpawnRule('mob5', 0.18, 0.5, 0.01),
          SpawnRule('mobBoss', 30, 0.5, 0.01, immediate: true),
        ];
    }
  }

  void _applyPhase(int phase) {
    if (phase == _phase) return;
    _phase = phase;
    _rules = _rulesForPhase(phase);
  }

  int _phaseForTime(double sec) {
    if (sec < 60) return 0;
    if (sec < 180) return 1;
    if (sec < 300) return 2;
    if (sec < 340) return 3;
    if (sec < 540) return 4;
    if (sec < 600) return 5;
    if (sec < 780) return 6;
    if (sec < 960) return 7;
    if (sec < 1200) return 8;
    if (sec < 1440) return 9;
    if (sec < 1500) return 10;
    if (sec < 1680) return 11;
    if (sec < 1800) return 12;
    return 13;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isRunning) return;
    final tc = game.cycleTime; // 무한 모드는 30분마다 0으로 되감김
    final total = game.elapsed;

    // 무한 모드: 사이클 전환 감지 → 이벤트 플래그 리셋 + 배너
    if (game.endlessCycle != _cycle) {
      _cycle = game.endlessCycle;
      ring1Done = ring2Done = false;
      stageBossSpawned = false;
      _phase = -1; // 각본 처음부터
      game.showBanner('🔄 사이클 ${_cycle + 1} — 적들이 훨씬 강해진다!', 5);
    }

    _applyPhase(_phaseForTime(tc));
    // 저주·하이퍼: 스폰 간격 단축
    final spawnMult =
        game.stats.curseSpawn * (game.modeHyper ? 1.5 : 1.0) * (1 + _cycle * 0.5);
    for (final r in _rules) {
      r.timer += dt;
      if (r.timer >= r.gap / spawnMult) {
        r.timer = 0;
        _spawn(r.mobKey, r.expDrop, r.itemDrop);
      }
    }

    // ── 스웜 러시: 2:00부터 45초마다 (사신 직전 10초 제외)
    if (tc >= 120 && tc < 1790) {
      _swarmTimer += dt;
      if (_swarmTimer >= 45) {
        _swarmTimer = 0;
        spawnSwarm();
      }
    }

    // ── 포위 이벤트: 13:00, 21:00 (동선 검사)
    if (!ring1Done && tc >= 780) {
      ring1Done = true;
      spawnRing();
    }
    if (!ring2Done && tc >= 1260) {
      ring2Done = true;
      spawnRing();
    }

    // ── 25:00 스테이지 보스 (처치 시 하이퍼 해금)
    if (!stageBossSpawned && tc >= SurvivorGame.kStageBossAt) {
      stageBossSpawned = true;
      spawnStageBoss();
    }

    // ── 사신 (무한 모드 제외): 29:50 예고, 30:00부터 1분마다 +1
    if (!game.modeEndless) {
      if (!game.reaperWarned && total >= SurvivorGame.kRunSeconds - 10) {
        game.reaperWarned = true;
        game.showBanner('☠ 무언가 무시무시한 것이 다가온다...', 5);
      }
      while (total >= SurvivorGame.kRunSeconds + reaperCount * 60) {
        _spawnReaper();
        reaperCount++;
        if (reaperCount > 60) break; // 안전장치
      }
    }
  }

  /// 떼 러시 — 체력 1짜리 60마리가 한 방향으로 화면을 관통 (경험치 사탕)
  void spawnSwarm() {
    final rng = game.rng;
    final a = rng.nextDouble() * math.pi * 2;
    final dir = Vector2(math.cos(a), math.sin(a)); // 진행 방향
    final origin = game.player.position - dir * spawnRadius;
    final perp = Vector2(-dir.y, dir.x);
    const cols = 20, rows = 3;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final off = perp * ((c - (cols - 1) / 2) * 55.0) - dir * (r * 70.0);
        game.world.add(Mob(
          config: kMobs['mob1']!,
          position: origin + off,
          expDropRate: 0.3,
          itemDropRate: 0,
          hpOverride: 1,
          speedOverride: 175 + rng.nextDouble() * 30,
          damageOverride: 3,
          chargeDir: dir.clone(),
          lifespan: (spawnRadius * 2 + 400) / 175,
        ));
      }
    }
  }

  /// 포위 이벤트 — 고체력 저속 링이 조여온다 (화력이 아니라 동선 검사)
  void spawnRing() {
    const count = 26;
    final hp = kMobs['mob4']!.hp * game.waveHpMult * 5;
    for (var i = 0; i < count; i++) {
      final a = math.pi * 2 * i / count;
      game.world.add(Mob(
        config: kMobs['mob4']!,
        position:
            game.player.position + Vector2(math.cos(a), math.sin(a)) * 560,
        expDropRate: 0.6,
        itemDropRate: 0.02,
        hpOverride: hp,
        speedOverride: 16,
        damageOverride: 6,
        lifespan: 55,
      ));
    }
    game.showBanner('⚠ 포위당했다! 틈을 찾아 빠져나가라!', 4);
  }

  /// 25:00 스테이지 보스 — 거대·고체력, 처치 시 확정 상자 + 하이퍼 해금
  void spawnStageBoss() {
    final a = game.rng.nextDouble() * math.pi * 2;
    game.world.add(Mob(
      config: kMobs['mobBoss']!,
      position: game.player.position +
          Vector2(math.cos(a), math.sin(a)) * (spawnRadius * 0.8),
      expDropRate: 1.0,
      itemDropRate: 0,
      isStageBoss: true,
      hpOverride: 1500 * game.waveHpMult,
      speedOverride: 45,
      damageOverride: 55,
    ));
    game.showBanner('👹 스테이지 보스가 나타났다!', 5);
  }

  void _spawnReaper() {
    final a = game.rng.nextDouble() * math.pi * 2;
    game.world.add(Mob(
      config: kMobs['mobBoss']!,
      position: game.player.position +
          Vector2(math.cos(a), math.sin(a)) * spawnRadius,
      expDropRate: 0,
      itemDropRate: 0,
      isReaper: true,
    ));
  }

  void _spawn(String key, double expDrop, double itemDrop) {
    final a = game.rng.nextDouble() * math.pi * 2;
    final pos = game.player.position +
        Vector2(math.cos(a), math.sin(a)) * spawnRadius;
    game.world.add(Mob(
      config: kMobs[key]!,
      position: pos,
      expDropRate: expDrop,
      itemDropRate: itemDrop,
      hpMult: game.waveHpMult,
    ));
  }
}

```

## lib/game/player.dart

```dart
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import 'stats.dart';
import 'survivor_game.dart';
import 'mob.dart';

class Player extends SpriteAnimationComponent
    with HasGameReference<SurvivorGame>, CollisionCallbacks {
  Player() : super(size: Vector2(80, 80) * 1.3, anchor: Anchor.center);

  static const double baseSpeed = 180; // 원작 3px/frame ≈ 180/s
  double maxHp = 100;
  late double hp = maxHp;
  double pickupRadius = 60; // 경험치/골드 흡수 반경 (자석 스탯)

  double _invuln = 0;
  int facing = 1; // 1 오른쪽, -1 왼쪽
  bool _moving = false;
  bool _flipped = false;

  static const _hitColor = Color(0xFFDB4455);

  @override
  Future<void> onLoad() async {
    animation = game.gfx.playerRun.clone();
    playing = false;
    add(CircleHitbox(radius: 26, anchor: Anchor.center)..position = size / 2);
  }

  /// 장신구 변화 반영 (최대체력 증가분은 즉시 회복)
  void applyStats(PlayerStats s) {
    final newMax = 100 * s.maxHpMult;
    if (newMax > maxHp) hp += newMax - maxHp;
    maxHp = newMax;
    pickupRadius = s.magnet;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_invuln > 0) {
      _invuln -= dt;
      if (_invuln <= 0) paint.colorFilter = null;
    }
    // 회복 스탯: 초당 재생 (VS Recovery)
    if (game.isRunning && game.stats.recovery > 0 && hp < maxHp) {
      hp = (hp + game.stats.recovery * dt).clamp(0, maxHp);
    }

    final dir = game.inputDirection();
    final moving = dir.length2 > 0.001;
    if (moving) {
      dir.normalize();
      game.lastMoveDir = dir.clone();
      position += dir * baseSpeed * game.stats.moveMult * dt;
      if (dir.x.abs() > 0.01) facing = dir.x > 0 ? 1 : -1;
    }
    if (moving != _moving) {
      _moving = moving;
      playing = moving;
      if (!moving) animationTicker?.reset();
    }
    final flip = facing < 0;
    if (flip != _flipped) {
      _flipped = flip;
      flipHorizontally();
    }
  }

  void takeDamage(double dmg) {
    if (_invuln > 0) return;
    // 방어력: 고정 감소, 최소 1 피해 (VS Armor)
    final eff = (dmg - game.stats.armor).clamp(1.0, double.infinity);
    hp -= eff;
    _invuln = 0.5;
    paint.colorFilter = const ColorFilter.mode(_hitColor, BlendMode.modulate);
    game.onPlayerHit();
    if (hp <= 0) {
      hp = 0;
      game.gameOver();
    }
  }

  void heal(double amount) {
    hp = (hp + amount).clamp(0, maxHp);
  }

  @override
  void onCollision(Set<Vector2> p, PositionComponent other) {
    super.onCollision(p, other);
    if (other is Mob) takeDamage(other.contactDamage);
  }
}

```

## lib/game/exp_up.dart

```dart
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import 'data.dart';
import 'survivor_game.dart';
import 'player.dart';

/// 원작 ExpUp — 죽은 자리에 가만히 놓이며, 플레이어가 닿으면 획득.
/// 자석(magnet) 아이템을 먹으면 플레이어 쪽으로 끌려온다.
class ExpUp extends SpriteComponent
    with HasGameReference<SurvivorGame>, CollisionCallbacks {
  ExpUp({required this.config, required Vector2 mobPosition})
      : super(
          position: mobPosition.clone()
            ..y += (config.key == 'mobBoss' ? 70 : 30),
          anchor: Anchor.center,
          size: Vector2(16, 16) * 1.5,
        );

  final MobConfig config;
  bool magnetized = false;

  int get value => config.exp;

  @override
  Future<void> onLoad() async {
    sprite = game.gfx.expColors[kExpColorIndex[config.key]!];
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    final toPlayer = game.player.position - position;
    final dist = toPlayer.length;
    // 자석 아이템(전체) 또는 흡수 범위 안이면 끌려온다
    if (magnetized || dist < game.player.pickupRadius) {
      if (dist > 1) {
        toPlayer.normalize();
        final speed = magnetized ? 1000.0 : 320.0;
        position += toPlayer * speed * dt;
      }
    }
  }

  @override
  void onCollisionStart(Set<Vector2> p, PositionComponent other) {
    super.onCollisionStart(p, other);
    if (other is Player) {
      game.audio.pickup();
      game.gainExp(value);
      removeFromParent();
    }
  }
}

```

## lib/game/item.dart

```dart
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import 'survivor_game.dart';
import 'player.dart';
import 'mob.dart';
import 'exp_up.dart';

enum ItemType { magnet, freeze, potion, allkill }

/// 원작 Items — 자석/빙결/물약/전체처치 (드랍률 0.01)
/// 사신에게는 빙결/전체처치가 통하지 않는다.
class ItemDrop extends SpriteComponent
    with HasGameReference<SurvivorGame>, CollisionCallbacks {
  ItemDrop({required Vector2 mobPosition, required this.isBoss})
      : super(
          position: mobPosition.clone()..y += (isBoss ? 100 : 60),
          anchor: Anchor.center,
          size: Vector2(16, 16) * 1.5,
        );

  final bool isBoss;
  late final ItemType type;

  @override
  Future<void> onLoad() async {
    type = ItemType.values[game.rng.nextInt(4)];
    sprite = game.gfx.items[type.index];
    add(CircleHitbox());
  }

  @override
  void onCollisionStart(Set<Vector2> p, PositionComponent other) {
    super.onCollisionStart(p, other);
    if (other is! Player) return;
    game.audio.item();
    switch (type) {
      case ItemType.magnet:
        for (final e in game.world.children.whereType<ExpUp>()) {
          e.magnetized = true;
        }
        break;
      case ItemType.freeze:
        for (final m in game.world.children.whereType<Mob>()) {
          if (m.isReaper) continue;
          m.frozen = true;
          m.add(TimerComponent(
              period: 5,
              repeat: false,
              removeOnFinish: true,
              onTick: () => m.frozen = false));
        }
        break;
      case ItemType.potion:
        game.player.heal(30); // VS 바닥 치킨과 동일한 30 회복
        break;
      case ItemType.allkill:
        for (final m in game.world.children.whereType<Mob>().toList()) {
          if (m.isReaper) continue;
          m.takeDamage(999999);
        }
        break;
    }
    removeFromParent();
  }
}

```

## lib/game/fx.dart

```dart
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'survivor_game.dart';
import 'player.dart';

/// 피해량 숫자 텍스트 (치명타는 노란색 + 큰 글씨)
class DamageText extends TextComponent {
  DamageText(double dmg, Vector2 pos, {bool crit = false})
      : super(
          text: dmg >= 100 ? dmg.round().toString() : dmg.toStringAsFixed(0),
          position: pos + Vector2(0, -20),
          anchor: Anchor.center,
          priority: 60,
          textRenderer: TextPaint(
            style: TextStyle(
              fontSize: crit ? 22 : 14,
              fontWeight: FontWeight.w900,
              color: crit ? const Color(0xFFFFD54F) : Colors.white,
              shadows: const [Shadow(color: Colors.black, blurRadius: 3)],
            ),
          ),
        );

  double _life = 0.5;

  @override
  void update(double dt) {
    super.update(dt);
    position.y -= 55 * dt;
    _life -= dt;
    if (_life <= 0) removeFromParent();
  }
}

/// 보스가 떨어뜨리는 보물상자 — 획득 시 무기 진화/골드 (VS 진화 시스템)
class TreasureChest extends PositionComponent
    with HasGameReference<SurvivorGame>, CollisionCallbacks {
  TreasureChest({required Vector2 position})
      : super(
            position: position,
            size: Vector2.all(44),
            anchor: Anchor.center,
            priority: 8);

  double _bob = 0;

  @override
  Future<void> onLoad() async {
    add(TextComponent(
      text: '🎁',
      anchor: Anchor.center,
      position: size / 2,
      textRenderer: TextPaint(style: const TextStyle(fontSize: 34)),
    ));
    add(CircleHitbox(radius: 26, anchor: Anchor.center)..position = size / 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _bob += dt * 4;
    scale.setValues(1 + 0.06 * _bob.remainder(1), 1 + 0.06 * _bob.remainder(1));
  }

  @override
  void onCollisionStart(Set<Vector2> p, PositionComponent other) {
    super.onCollisionStart(p, other);
    if (other is Player && game.isRunning) {
      removeFromParent();
      game.openChest();
    }
  }
}

/// 금화 — VS의 골드 드랍
class GoldCoin extends PositionComponent
    with HasGameReference<SurvivorGame>, CollisionCallbacks {
  GoldCoin({required Vector2 position, this.value = 1})
      : super(
            position: position,
            size: Vector2.all(22),
            anchor: Anchor.center,
            priority: 6);

  final int value;

  @override
  Future<void> onLoad() async {
    add(TextComponent(
      text: '🪙',
      anchor: Anchor.center,
      position: size / 2,
      textRenderer: TextPaint(style: const TextStyle(fontSize: 16)),
    ));
    add(CircleHitbox(radius: 12, anchor: Anchor.center)..position = size / 2);
  }

  bool _magnet = false;

  @override
  void update(double dt) {
    super.update(dt);
    final d = game.player.position.distanceTo(position);
    if (d < game.player.pickupRadius) _magnet = true;
    if (_magnet && d > 1) {
      final dir = (game.player.position - position)..normalize();
      position += dir * 340 * dt;
    }
  }

  @override
  void onCollisionStart(Set<Vector2> p, PositionComponent other) {
    super.onCollisionStart(p, other);
    if (other is Player) {
      game.gainGold(value);
      removeFromParent();
    }
  }
}

```
