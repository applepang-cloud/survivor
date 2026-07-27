import 'dart:ui';

/// 서브컬처식 부대 구조 — 플레이어는 '대장', 전투는 대원(소녀)들이 나간다.
/// 대사·캐릭터는 전부 이 프로젝트의 오리지널.

class StoryLine {
  final bool commander; // true = 대장(나)의 대사
  final String text;
  const StoryLine(this.commander, this.text);
}

class Character {
  final String id;
  final String name;
  final String title; // 한 줄 소개
  final String bonusDesc;
  final Color tint; // 인게임 스프라이트/초상화 틴트
  final Color color; // UI 포인트 컬러
  // 캐릭터 보너스 (VS의 캐릭터별 특성)
  final double might;
  final double move;
  final double hpMult;

  // 스토리 대화 (출격 전 / 승리 / 패배)
  final List<StoryLine> intro;
  final List<StoryLine> victory;
  final List<StoryLine> defeat;

  // 전투 중 무전 한마디
  final String talkFirstLevel;
  final String talkEvolution;
  final String talkEncircle;
  final String talkBoss;
  final String talkReaper;
  final String talkLowHp;
  final String talkCycle;

  const Character({
    required this.id,
    required this.name,
    required this.title,
    required this.bonusDesc,
    required this.tint,
    required this.color,
    this.might = 1,
    this.move = 1,
    this.hpMult = 1,
    required this.intro,
    required this.victory,
    required this.defeat,
    required this.talkFirstLevel,
    required this.talkEvolution,
    required this.talkEncircle,
    required this.talkBoss,
    required this.talkReaper,
    required this.talkLowHp,
    required this.talkCycle,
  });
}

const List<Character> kCharacters = [
  Character(
    id: 'sera',
    name: '세라',
    title: '태양처럼 밝은 돌격 에이스',
    bonusDesc: '이동 속도 +10%',
    tint: Color(0xFFFFE8CC),
    color: Color(0xFFFFB74D),
    move: 1.10,
    intro: [
      StoryLine(false, '대장! 오늘도 제가 선봉이에요? 히히, 맡겨만 주세요!'),
      StoryLine(true, '무리하지 마라, 세라. 30분… 길고 긴 밤이 될 거다.'),
      StoryLine(false, '괜찮아요! 대장이 지켜봐 주면 저, 무적이거든요!'),
      StoryLine(true, '…믿는다. 전 부대, 작전 개시.'),
      StoryLine(false, '네! 세라, 출격합니다~!'),
    ],
    victory: [
      StoryLine(false, '해냈어요, 대장! 저 새벽까지 살아남았어요!'),
      StoryLine(true, '잘 싸웠다, 세라. 오늘의 에이스는 너다.'),
      StoryLine(false, '에헤헤… 그럼 보상으로, 머리 쓰다듬어 주기!'),
    ],
    defeat: [
      StoryLine(false, '미안해요, 대장… 조금, 아팠어요…'),
      StoryLine(true, '충분히 잘했다. 돌아와서 쉬어라, 세라.'),
      StoryLine(false, '다음엔… 꼭 새벽까지 버틸게요.'),
    ],
    talkFirstLevel: '벌써 몸이 가벼워졌어요! 다음 장비도 골라 주세요, 대장!',
    talkEvolution: '대장! 상자에서 이상한 빛이…! 이게 진화라는 거죠?!',
    talkEncircle: '우와, 완전 포위됐는데요?! …뚫고 나갈게요!',
    talkBoss: '저, 저거 엄청 큰데요…! 하지만 안 져요!',
    talkReaper: '대장… 뭔가 와요. 소름이 쫙 돋았어요…!',
    talkLowHp: '아야야… 대장, 조금만 더 버틸게요…!',
    talkCycle: '아직 끝이 아니라구요?! 좋아요, 2라운드!',
  ),
  Character(
    id: 'yuna',
    name: '유나',
    title: '얼음처럼 냉정한 베테랑 저격수',
    bonusDesc: '공격력 +10%',
    tint: Color(0xFFCCE0FF),
    color: Color(0xFF64B5F6),
    might: 1.10,
    intro: [
      StoryLine(false, '대장님. 작전 브리핑은 이미 숙지했습니다.'),
      StoryLine(true, '믿음직하군. 이번 밤도 부탁한다, 유나.'),
      StoryLine(false, '…30분. 정확히 버티고 돌아오겠습니다.'),
      StoryLine(true, '무운을 빈다. 작전 개시.'),
    ],
    victory: [
      StoryLine(false, '임무 완료. 생존을 확인했습니다.'),
      StoryLine(true, '완벽했다, 유나.'),
      StoryLine(false, '…대장님의 지휘 덕분입니다. …정말로.'),
    ],
    defeat: [
      StoryLine(false, '…작전 실패. 죄송합니다, 대장님.'),
      StoryLine(true, '데이터는 남았다. 다음엔 이긴다.'),
      StoryLine(false, '…네. 반드시.'),
    ],
    talkFirstLevel: '장비 강화 확인. …선택은 대장님께 맡기겠습니다.',
    talkEvolution: '10분 경과. 진화 병기, 사용 허가를 요청합니다.',
    talkEncircle: '포위망 확인. …돌파 지점은 이미 계산해 뒀습니다.',
    talkBoss: '대형 개체 출현. …조준 개시.',
    talkReaper: '대장님, 미확인 반응 다수. …이건, 격이 다릅니다.',
    talkLowHp: '…피탄. 문제없습니다. 아직은.',
    talkCycle: '다음 주기 진입. 탄약은… 충분합니다.',
  ),
  Character(
    id: 'lize',
    name: '리제',
    title: '겁 많지만 도망치지 않는 방패 소녀',
    bonusDesc: '최대 체력 +20%',
    tint: Color(0xFFFFD6E7),
    color: Color(0xFFF06292),
    hpMult: 1.20,
    intro: [
      StoryLine(false, '대, 대장님… 오늘도 제가 맨 앞에 서는 거죠…?'),
      StoryLine(true, '무섭나, 리제?'),
      StoryLine(false, '무, 무섭지만… 대장님 목소리가 들리면, 버틸 수 있어요.'),
      StoryLine(true, '그럼 계속 말을 걸어주지. 작전 개시다.'),
      StoryLine(false, '네…! 리제, 나갑니다…!'),
    ],
    victory: [
      StoryLine(false, '사, 살았다아… 대장님, 저 해냈어요…!'),
      StoryLine(true, '오늘 밤 제일 용감했던 건 너다, 리제.'),
      StoryLine(false, '…에헤헤. 그 말, 녹음해 두고 싶어요…'),
    ],
    defeat: [
      StoryLine(false, '죄송해요… 방패가… 부서져 버려서…'),
      StoryLine(true, '네 방패 덕에 모두 무사하다. 자랑스럽다.'),
      StoryLine(false, '…다음엔, 더 단단해질게요.'),
    ],
    talkFirstLevel: '조금… 강해진 것 같아요. 대장님, 다음은 뭘 고를까요…?',
    talkEvolution: '저 상자… 열어도 될까요? 굉장한 힘이 느껴져요…',
    talkEncircle: '히익, 둘러싸였어요…! 대장님, 어느 쪽으로 가면…?!',
    talkBoss: '너, 너무 커요…! 그래도… 제가 막을게요!',
    talkReaper: '대장님… 발소리가 들려요. 아주, 무거운 발소리가…',
    talkLowHp: '아파요… 하지만, 아직 설 수 있어요…',
    talkCycle: '또… 오는 거죠? …심호흡, 심호흡…',
  ),
];
