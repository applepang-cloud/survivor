import 'dart:ui';

/// 서브컬처식 부대 구조 — 플레이어는 '대장', 전투는 대원(소녀)들이 나간다.
/// 대사·캐릭터는 전부 이 프로젝트의 오리지널.
///
/// 2지선다: StoryLine.choice(...) 를 만나면 대장의 답변 2개 중 하나를 고르고,
/// 고른 답변 + 대원의 반응이 대화에 끼워진다.

class StoryChoice {
  final String a; // 대장 선택지 1
  final String b; // 대장 선택지 2
  final String reactA; // 대원 반응 1
  final String reactB; // 대원 반응 2
  const StoryChoice({
    required this.a,
    required this.b,
    required this.reactA,
    required this.reactB,
  });
}

class StoryLine {
  final bool commander; // true = 대장(나)의 대사
  final String text;
  final StoryChoice? choice; // non-null 이면 2지선다
  const StoryLine(this.commander, this.text) : choice = null;
  const StoryLine.choose(this.choice)
      : commander = true,
        text = '(뭐라고 답할까…)';
}

class Character {
  final String id;
  final String name;
  final String title; // 한 줄 소개
  final String bonusDesc;
  final Color tint; // 인게임 스프라이트 틴트
  final Color color; // UI 포인트 컬러

  /// 캐릭터 일러스트 경로 (없거나 로드 실패 시 스프라이트 초상으로 폴백)
  String get illust => 'assets/portraits/$id.png';

  // 캐릭터 보너스 (VS의 캐릭터별 특성) — 곱연산 배율 / 가산치
  final double might;
  final double move;
  final double hpMult;
  final double cooldown; // ×0.92 등 (낮을수록 빠름)
  final double area;
  final double luck;
  final double growth;
  final double magnet; // +px
  final double armor; // +고정감소
  final double recovery; // +초당회복
  final int amount; // +투사체

  // 스토리 대화 (출격 전 / 승리 / 패배)
  final List<StoryLine> intro;
  final List<StoryLine> victory;
  final List<StoryLine> defeat;

  /// 격전 중 짧은 대화 — 레벨업(스킬 선택) 2회에 1번 순환 재생
  final List<List<StoryLine>> banter;

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
    this.cooldown = 1,
    this.area = 1,
    this.luck = 1,
    this.growth = 1,
    this.magnet = 0,
    this.armor = 0,
    this.recovery = 0,
    this.amount = 0,
    required this.intro,
    required this.victory,
    required this.defeat,
    this.banter = const [],
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
  // 1 ──────────────────────────────────────────────
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
      StoryLine.choose(StoryChoice(
        a: '무리하지 마라, 세라.',
        b: '오늘 밤 에이스는 너다.',
        reactA: '괜찮아요! 대장이 지켜봐 주면 저, 무적이거든요!',
        reactB: '헤헤, 그렇게 나오시면… 진짜로 다 쓸어버린다?!',
      )),
      StoryLine(true, '…믿는다. 전 부대, 작전 개시.'),
      StoryLine(false, '네! 세라, 출격합니다~!'),
    ],
    victory: [
      StoryLine(false, '해냈어요, 대장! 저 새벽까지 살아남았어요!'),
      StoryLine.choose(StoryChoice(
        a: '잘 싸웠다. 오늘의 에이스다.',
        b: '약속대로, 머리 쓰다듬기다.',
        reactA: '에헤헤… 그 말 들으려고 끝까지 뛰었어요!',
        reactB: '우와아, 기억하고 있었구나! …살살요, 살살!',
      )),
      StoryLine(false, '내일도 세라가 일등으로 달릴게요!'),
    ],
    defeat: [
      StoryLine(false, '미안해요, 대장… 조금, 아팠어요…'),
      StoryLine(true, '충분히 잘했다. 돌아와서 쉬어라, 세라.'),
      StoryLine(false, '다음엔… 꼭 새벽까지 버틸게요.'),
    ],
    banter: [
      [
        StoryLine(false, '대장, 방금 그거 봤어요?! 저 좀 멋있었죠?'),
        StoryLine(true, '봤다. 다음 것도 기대하지.'),
      ],
      [
        StoryLine(false, '이 기세면 새벽까지 금방이에요!'),
        StoryLine(true, '방심은 금물이다, 세라.'),
      ],
      [
        StoryLine(false, '히히, 점점 강해지는 게 느껴져요!'),
        StoryLine(true, '그 웃음이 부대의 사기다.'),
      ],
      [
        StoryLine(false, '대장! 끝나면 라면 먹으러 가요!'),
        StoryLine(true, '…살아서 돌아오면.'),
      ],
    ],
    talkFirstLevel: '벌써 몸이 가벼워졌어요! 다음 장비도 골라 주세요, 대장!',
    talkEvolution: '대장! 상자에서 이상한 빛이…! 이게 진화라는 거죠?!',
    talkEncircle: '우와, 완전 포위됐는데요?! …뚫고 나갈게요!',
    talkBoss: '저, 저거 엄청 큰데요…! 하지만 안 져요!',
    talkReaper: '대장… 뭔가 와요. 소름이 쫙 돋았어요…!',
    talkLowHp: '아야야… 대장, 조금만 더 버틸게요…!',
    talkCycle: '아직 끝이 아니라구요?! 좋아요, 2라운드!',
  ),
  // 2 ──────────────────────────────────────────────
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
      StoryLine.choose(StoryChoice(
        a: '무리는 금물이다, 유나.',
        b: '너라면 초과 달성하겠지.',
        reactA: '…배려, 감사합니다. 하지만 임무가 우선입니다.',
        reactB: '…기대에는, 결과로 답하겠습니다.',
      )),
      StoryLine(true, '무운을 빈다. 작전 개시.'),
      StoryLine(false, '…30분. 정확히 버티고 돌아오겠습니다.'),
    ],
    victory: [
      StoryLine(false, '임무 완료. 생존을 확인했습니다.'),
      StoryLine.choose(StoryChoice(
        a: '완벽했다, 유나.',
        b: '오늘은 좀 웃어도 된다.',
        reactA: '…대장님의 지휘 덕분입니다. …정말로.',
        reactB: '……(입꼬리가 아주 살짝, 올라갔다.)',
      )),
      StoryLine(false, '다음 임무도, 대기하겠습니다.'),
    ],
    defeat: [
      StoryLine(false, '…작전 실패. 죄송합니다, 대장님.'),
      StoryLine(true, '데이터는 남았다. 다음엔 이긴다.'),
      StoryLine(false, '…네. 반드시.'),
    ],
    banter: [
      [
        StoryLine(false, '…강화 완료. 명중률이 오르고 있습니다.'),
        StoryLine(true, '숫자가 널 따라오는군.'),
      ],
      [
        StoryLine(false, '탄도 계산, 갱신했습니다.'),
        StoryLine(true, '믿고 맡기지.'),
      ],
      [
        StoryLine(false, '…집중력, 유지 중입니다.'),
        StoryLine(true, '너무 조이지 마라. 어깨에 힘 빼고.'),
      ],
      [
        StoryLine(false, '이 정도 화력이면… 충분합니다.'),
        StoryLine(true, '네 「충분」은 늘 과잉이었지.'),
      ],
    ],
    talkFirstLevel: '장비 강화 확인. …선택은 대장님께 맡기겠습니다.',
    talkEvolution: '10분 경과. 진화 병기, 사용 허가를 요청합니다.',
    talkEncircle: '포위망 확인. …돌파 지점은 이미 계산해 뒀습니다.',
    talkBoss: '대형 개체 출현. …조준 개시.',
    talkReaper: '대장님, 미확인 반응 다수. …이건, 격이 다릅니다.',
    talkLowHp: '…피탄. 문제없습니다. 아직은.',
    talkCycle: '다음 주기 진입. 탄약은… 충분합니다.',
  ),
  // 3 ──────────────────────────────────────────────
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
      StoryLine.choose(StoryChoice(
        a: '무섭나, 리제?',
        b: '네 방패가 제일 믿음직하다.',
        reactA: '무, 무섭지만… 대장님 목소리가 들리면, 버틸 수 있어요.',
        reactB: '…! 헤헤… 그런 말 들으면, 방패가 더 단단해져요.',
      )),
      StoryLine(true, '계속 말을 걸어주지. 작전 개시다.'),
      StoryLine(false, '네…! 리제, 나갑니다…!'),
    ],
    victory: [
      StoryLine(false, '사, 살았다아… 대장님, 저 해냈어요…!'),
      StoryLine.choose(StoryChoice(
        a: '오늘 밤 제일 용감했다.',
        b: '수고했다. 코코아 타주지.',
        reactA: '…에헤헤. 그 말, 녹음해 두고 싶어요…',
        reactB: '코, 코코아…! 마시멜로도 얹어 주실 거죠…?',
      )),
      StoryLine(false, '다음에도… 제가 지킬게요.'),
    ],
    defeat: [
      StoryLine(false, '죄송해요… 방패가… 부서져 버려서…'),
      StoryLine(true, '네 방패 덕에 모두 무사하다. 자랑스럽다.'),
      StoryLine(false, '…다음엔, 더 단단해질게요.'),
    ],
    banter: [
      [
        StoryLine(false, '바, 방패가 점점 가벼워져요…!'),
        StoryLine(true, '네가 강해진 거다, 리제.'),
      ],
      [
        StoryLine(false, '대장님, 저… 잘하고 있나요?'),
        StoryLine(true, '누구보다.'),
      ],
      [
        StoryLine(false, '심장이 두근두근해요… 무서워서가 아니라…!'),
        StoryLine(true, '그건 성장통이다.'),
      ],
      [
        StoryLine(false, '다, 달아나지 않았어요, 저!'),
        StoryLine(true, '알고 있다. 계속 그거면 된다.'),
      ],
    ],
    talkFirstLevel: '조금… 강해진 것 같아요. 대장님, 다음은 뭘 고를까요…?',
    talkEvolution: '저 상자… 열어도 될까요? 굉장한 힘이 느껴져요…',
    talkEncircle: '히익, 둘러싸였어요…! 대장님, 어느 쪽으로 가면…?!',
    talkBoss: '너, 너무 커요…! 그래도… 제가 막을게요!',
    talkReaper: '대장님… 발소리가 들려요. 아주, 무거운 발소리가…',
    talkLowHp: '아파요… 하지만, 아직 설 수 있어요…',
    talkCycle: '또… 오는 거죠? …심호흡, 심호흡…',
  ),
  // 4 ──────────────────────────────────────────────
  Character(
    id: 'hana',
    name: '하나',
    title: '부대의 무기를 책임지는 정비반장',
    bonusDesc: '무기 쿨타임 −8%',
    tint: Color(0xFFE8F5CC),
    color: Color(0xFFAED581),
    cooldown: 0.92,
    intro: [
      StoryLine(false, '대장! 무기 정비 끝! 오늘은 총알이 두 배로 잘 나갈 거야.'),
      StoryLine.choose(StoryChoice(
        a: '믿음직하다, 하나.',
        b: '또 밤샘 정비했나? 무리하지 마라.',
        reactA: '헤헤, 이 맛에 정비하지! 자, 가자!',
        reactB: '어… 들켰네. 그래도 기계 만질 때가 제일 신나는걸!',
      )),
      StoryLine(true, '출격이다. 정비 값은 전장에서 확인하지.'),
      StoryLine(false, '오케이! 풀스로틀로 간다~!'),
    ],
    victory: [
      StoryLine(false, '거봐! 정비발 제대로 받았지?'),
      StoryLine.choose(StoryChoice(
        a: '네 손끝 덕분이다.',
        b: '다음엔 내 무기도 부탁한다.',
        reactA: '…칭찬 저금해 둘게. 나중에 이자 붙여서 받는다?',
        reactB: '맡겨줘! 대장 전용으로 반짝반짝하게 만들어줄게!',
      )),
      StoryLine(false, '돌아가서 오버홀 하자~ 다들 수고했어!'),
    ],
    defeat: [
      StoryLine(false, '미안… 정비가 부족했나 봐…'),
      StoryLine(true, '장비 탓이 아니다. 다음 판을 준비하자.'),
      StoryLine(false, '…응! 나사 두 배로 조여 올게!'),
    ],
    banter: [
      [
        StoryLine(false, '부품 맞물리는 소리 들려? 완벽해!'),
        StoryLine(true, '정비반장 귀는 못 속이는군.'),
      ],
      [
        StoryLine(false, '화력 출력 20% 상승~!'),
        StoryLine(true, '너무 올리다 터뜨리지는 마라.'),
      ],
      [
        StoryLine(false, '대장 무기도 하나 만들어줄까?'),
        StoryLine(true, '…전장 끝나고 부탁하지.'),
      ],
      [
        StoryLine(false, '기름칠한 보람이 있네!'),
        StoryLine(true, '네 손이 부대의 심장이다.'),
      ],
    ],
    talkFirstLevel: '레벨업! 나사 하나 더 조였다~ 다음 부품 골라줘, 대장!',
    talkEvolution: '10분 경과! 진화 파츠 장착 가능! 크크, 이거 물건이야!',
    talkEncircle: '빙 둘러싸였네?! 출력 최대로 올린다!',
    talkBoss: '저 덩치… 분해해 보고 싶다! 가자!',
    talkReaper: '…대장, 계기판이 전부 빨간불이야.',
    talkLowHp: '장갑이 너덜너덜… 그래도 엔진은 살아있어!',
    talkCycle: '한 바퀴 더? 연료는 가득이야!',
  ),
  // 5 ──────────────────────────────────────────────
  Character(
    id: 'miko',
    name: '미코',
    title: '어둠을 베어 정화하는 무녀',
    bonusDesc: '공격 범위 +15%',
    tint: Color(0xFFFFD0D0),
    color: Color(0xFFE57373),
    area: 1.15,
    intro: [
      StoryLine(false, '대장님. 오늘 밤의 별자리는… 피의 냄새를 알리고 있사옵니다.'),
      StoryLine.choose(StoryChoice(
        a: '길흉은 어느 쪽이지?',
        b: '별보다 네 검무를 믿는다.',
        reactA: '반흉반길… 하오나 대장님이 곁에 계시니, 길로 기울 것입니다.',
        reactB: '…! 그 말씀, 어떤 부적보다 든든하옵니다.',
      )),
      StoryLine(true, '가자, 미코. 밤을 정화한다.'),
      StoryLine(false, '예. 부정한 것들을… 베어 흩뿌리겠나이다.'),
    ],
    victory: [
      StoryLine(false, '새벽의 방울 소리가 들리옵니다. …끝났습니다.'),
      StoryLine.choose(StoryChoice(
        a: '훌륭한 검무였다.',
        b: '다치지는 않았나?',
        reactA: '대장님께 바치는 춤이었으니까요.',
        reactB: '옷자락만 조금… 걱정해 주시는 것만으로 다 나았사옵니다.',
      )),
      StoryLine(false, '돌아가면 정화의 차를 올리겠습니다.'),
    ],
    defeat: [
      StoryLine(false, '부정이… 너무 깊었사옵니다…'),
      StoryLine(true, '네 탓이 아니다. 달이 나빴을 뿐이다.'),
      StoryLine(false, '…다음 보름에는, 반드시.'),
    ],
    banter: [
      [
        StoryLine(false, '가호가 한 겹 더해졌사옵니다.'),
        StoryLine(true, '든든하군.'),
      ],
      [
        StoryLine(false, '칼끝이 맑아졌사옵니다…'),
        StoryLine(true, '네 마음처럼.'),
      ],
      [
        StoryLine(false, '방금, 대장님의 무운을 빌었사옵니다.'),
        StoryLine(true, '…고맙다. 효과가 있는 것 같군.'),
      ],
      [
        StoryLine(false, '부정이 조금씩 옅어지고 있사옵니다.'),
        StoryLine(true, '새벽이 가까워진다는 뜻이지.'),
      ],
    ],
    talkFirstLevel: '힘이 맑아졌사옵니다. 다음 가호를 골라주소서.',
    talkEvolution: '봉인된 상자가 눈을 떴사옵니다…!',
    talkEncircle: '사방이 부정한 기운…! 결계를 펼치겠나이다!',
    talkBoss: '커다란 원념이옵니다… 물러서지 않겠습니다.',
    talkReaper: '…죽음 그 자체가, 걸어오고 있사옵니다.',
    talkLowHp: '피가… 하오나 무녀는 쓰러지지 않사옵니다.',
    talkCycle: '밤이 다시 깊어지옵니다…',
  ),
  // 6 ──────────────────────────────────────────────
  Character(
    id: 'roro',
    name: '로로',
    title: '반짝이는 건 다 줍는 트레저헌터',
    bonusDesc: '행운 +20%',
    tint: Color(0xFFFFF2B8),
    color: Color(0xFFFFD54F),
    luck: 1.20,
    intro: [
      StoryLine(false, '대장~! 오늘 보물 냄새가 진하게 나는데? 내 코는 못 속여!'),
      StoryLine.choose(StoryChoice(
        a: '보물보다 목숨이 먼저다.',
        b: '제일 큰 상자는 네 몫이다.',
        reactA: '칫~ 알았어. 목숨 먼저, 보물은 두 번째! …세 번째쯤?',
        reactB: '오예!! 대장 최고! 사랑해도 돼?!',
      )),
      StoryLine(true, '간다. 발밑 조심해라, 로로.'),
      StoryLine(false, '고고! 반짝이는 건 전부 내 거야~!'),
    ],
    victory: [
      StoryLine(false, '봤어봤어?! 나 오늘 완전 잘했지?!'),
      StoryLine.choose(StoryChoice(
        a: '오늘의 MVP는 너다.',
        b: '…주머니에 뭘 그렇게 넣었나.',
        reactA: '에헤헤~ 그럼 보너스도 두둑하게 부탁해!',
        reactB: '이, 이건 전리품! 정당한 노동의 대가라구!',
      )),
      StoryLine(false, '다음엔 더 큰 금고를 털자~!'),
    ],
    defeat: [
      StoryLine(false, '으엥… 보물 코앞에서 넘어졌어…'),
      StoryLine(true, '목숨이 제일 큰 보물이다. 무사해서 다행이다.'),
      StoryLine(false, '…흑. 다음엔 꼭 들고 돌아올게.'),
    ],
    banter: [
      [
        StoryLine(false, '이거 완전 레어템 각이야!'),
        StoryLine(true, '욕심은 반만 부려라.'),
      ],
      [
        StoryLine(false, '대장, 나 방금 3연속 회피! 봤지?!'),
        StoryLine(true, '운도 실력이다. 인정하지.'),
      ],
      [
        StoryLine(false, '이 근처에서 금화 냄새가 나~'),
        StoryLine(true, '…냄새로 아는 게 더 신기하다.'),
      ],
      [
        StoryLine(false, '끝나면 전리품 정산하자!'),
        StoryLine(true, '네 몫이 제일 클 거다.'),
      ],
    ],
    talkFirstLevel: '레벨업~! 럭키! 다음 것도 좋은 걸로 골라줘, 대장!',
    talkEvolution: '저 상자, 완전 명품 냄새 나!',
    talkEncircle: '포위?! 내 도주 루트 어디 갔어…!',
    talkBoss: '보스는 드랍이 짭짤하지! 가보자고!',
    talkReaper: '…대장, 쟤는 훔칠 것도 없어 보여. 도망치자?',
    talkLowHp: '아야… 행운의 동전아, 일해라 좀…!',
    talkCycle: '2회차 보너스 스테이지다~!',
  ),
  // 7 ──────────────────────────────────────────────
  Character(
    id: 'arin',
    name: '아린',
    title: '전장을 실험실 삼는 천재 연구원',
    bonusDesc: '경험치 +15%',
    tint: Color(0xFFCCF2EC),
    color: Color(0xFF4DB6AC),
    growth: 1.15,
    intro: [
      StoryLine(false, '대장님, 오늘의 가설: 제 화력은 어제보다 12.7% 상승했습니다.'),
      StoryLine.choose(StoryChoice(
        a: '근거는?',
        b: '실험은 실전에서 증명해라.',
        reactA: '어젯밤 시뮬레이션 342회! …잠은 좀 못 잤지만요.',
        reactB: '맞는 말씀! 전장이 곧 제 실험실이죠!',
      )),
      StoryLine(true, '그럼 검증을 시작하지. 출격.'),
      StoryLine(false, '데이터 수집, 개시합니다~!'),
    ],
    victory: [
      StoryLine(false, '가설 채택! 생존율 100% 달성입니다!'),
      StoryLine.choose(StoryChoice(
        a: '네 이론이 옳았다.',
        b: '이제 가서 자라, 아린.',
        reactA: '후후, 논문 제목은 「대장과 함께한 30분」으로 하죠.',
        reactB: '자, 잘 수 없어요! 이 데이터가 식기 전에 정리해야…!',
      )),
      StoryLine(false, '다음 실험이 벌써 기대되네요!'),
    ],
    defeat: [
      StoryLine(false, '…변수가, 너무 많았어요…'),
      StoryLine(true, '실패도 데이터다. 잘 싸웠다.'),
      StoryLine(false, '…네. 다음 가설은, 더 완벽하게.'),
    ],
    banter: [
      [
        StoryLine(false, '출력 상승 곡선, 이론치와 일치!'),
        StoryLine(true, '네 계산대로군.'),
      ],
      [
        StoryLine(false, '새로운 변수 확보! 흥미로워요!'),
        StoryLine(true, '전장에서 눈이 반짝이는 건 너뿐이다.'),
      ],
      [
        StoryLine(false, '기록 중… 대장님 지휘도 데이터에 넣을게요.'),
        StoryLine(true, '…좋은 쪽으로 부탁하지.'),
      ],
      [
        StoryLine(false, '가설이 점점 확신이 되어가요!'),
        StoryLine(true, '결론은 생존으로 증명해라.'),
      ],
    ],
    talkFirstLevel: '성장 곡선 정상! 다음 변수를 선택해 주세요!',
    talkEvolution: '진화 조건 충족 확인! 이론대로예요!',
    talkEncircle: '포위 대형… 탈출 벡터 계산 중!',
    talkBoss: '거대 샘플 등장! 관측하고 싶지만… 일단 격파!',
    talkReaper: '측정 불가 수치… 대장님, 이건 이론 밖이에요.',
    talkLowHp: '출혈량이 임계치… 그래도 실험은 계속해요!',
    talkCycle: '2회차 데이터, 수집 시작!',
  ),
  // 8 ──────────────────────────────────────────────
  Character(
    id: 'noa',
    name: '노아',
    title: '잠이 모자란 천재 전술가',
    bonusDesc: '획득 반경 +40',
    tint: Color(0xFFE0D4F7),
    color: Color(0xFFB39DDB),
    magnet: 40,
    intro: [
      StoryLine(false, '…대장, 안녕. 작전도는 다 그려놨어. …하암.'),
      StoryLine.choose(StoryChoice(
        a: '또 밤샜군. 오늘은 내가 지휘한다.',
        b: '네 작전이라면 눈 감고도 이기겠지.',
        reactA: '…고마워. 그럼 반쯤 자면서 싸울게.',
        reactB: '…응. 실제로 반쯤 감고 싸울 예정이야.',
      )),
      StoryLine(true, '가자. 끝나면 재워주지.'),
      StoryLine(false, '…그 말, 계약서에 적어줘.'),
    ],
    victory: [
      StoryLine(false, '…계획대로. 하암… 이제 자도 돼?'),
      StoryLine.choose(StoryChoice(
        a: '수고했다. 어깨 빌려주지.',
        b: '보고서가 먼저다.',
        reactA: '…따뜻해. 5분만…',
        reactB: '…너무해. 꿈에서 쓸게…',
      )),
      StoryLine(false, '…다음 작전은, 자고 일어나서 생각할래.'),
    ],
    defeat: [
      StoryLine(false, '…계산이 어긋났어. …졸려서가 아니야.'),
      StoryLine(true, '알고 있다. 다음 수를 두자.'),
      StoryLine(false, '…응. 이번엔 커피 마실게.'),
    ],
    banter: [
      [
        StoryLine(false, '…예정보다 3% 빨라. 좋은 페이스야.'),
        StoryLine(true, '네 계산은 여전하군.'),
      ],
      [
        StoryLine(false, '…하암. 아직 안 졸려. 진짜야.'),
        StoryLine(true, '그 말, 오늘만 세 번째다.'),
      ],
      [
        StoryLine(false, '…대장 목소리 들으면, 잠이 깨.'),
        StoryLine(true, '…그럼 계속 말해주지.'),
      ],
      [
        StoryLine(false, '…다음 웨이브, 서쪽이 얇아.'),
        StoryLine(true, '접수했다.'),
      ],
    ],
    talkFirstLevel: '…강해졌네. 다음 선택은, 대장 취향대로.',
    talkEvolution: '…10분. 예정대로 상자가 열려.',
    talkEncircle: '…포위됐어. 북동쪽이 제일 얇아.',
    talkBoss: '…큰 게 와. 작전 B로 전환.',
    talkReaper: '…여기부터는 작전이 의미 없어. 도망쳐.',
    talkLowHp: '…아파. 잠 깼어. 완전히 깼어.',
    talkCycle: '…연장전? …커피…',
  ),
  // 9 ──────────────────────────────────────────────
  Character(
    id: 'kaya',
    name: '카야',
    title: '말수 적은 백전노장 용병',
    bonusDesc: '방어 +1 · 초당 회복 +0.2',
    tint: Color(0xFFD4E2E8),
    color: Color(0xFF90A4AE),
    armor: 1,
    recovery: 0.2,
    intro: [
      StoryLine(false, '…의뢰 내용은 들었다. 30분 생존. 그뿐인가?'),
      StoryLine.choose(StoryChoice(
        a: '살아서 돌아오는 것까지가 의뢰다.',
        b: '네 등은 내가 봐주지.',
        reactA: '…이상한 고용주군. 보수는 생존으로 갚지.',
        reactB: '…필요 없다, 고 말하고 싶지만. …부탁한다.',
      )),
      StoryLine(true, '계약 성립이다. 출격.'),
      StoryLine(false, '…간다.'),
    ],
    victory: [
      StoryLine(false, '…의뢰 완료다.'),
      StoryLine.choose(StoryChoice(
        a: '너 없인 못 했을 거다.',
        b: '상처를 보여봐라.',
        reactA: '…그런 말을 하는 고용주는, 네가 처음이다.',
        reactB: '…스쳤을 뿐이다. …고맙다.',
      )),
      StoryLine(false, '…다음 의뢰도, 네 밑에서 받지.'),
    ],
    defeat: [
      StoryLine(false, '…실수했다. 계약 불이행이군.'),
      StoryLine(true, '위약금은 없다. 네가 무사하면 됐다.'),
      StoryLine(false, '……정말, 이상한 고용주다.'),
    ],
    banter: [
      [
        StoryLine(false, '…무기가 손에 익는군.'),
        StoryLine(true, '네 실력이다.'),
      ],
      [
        StoryLine(false, '…고용주. 다음 지시는?'),
        StoryLine(true, '지금처럼. 살아있어라.'),
      ],
      [
        StoryLine(false, '…이 부대, 나쁘지 않다.'),
        StoryLine(true, '너답지 않게 솔직하군.'),
      ],
      [
        StoryLine(false, '…등 뒤는 맡겨라.'),
        StoryLine(true, '믿고 있다.'),
      ],
    ],
    talkFirstLevel: '장비 갱신. …나쁘지 않군.',
    talkEvolution: '새 무기인가. …써주지.',
    talkEncircle: '포위 따위, 몇 번째인지 기억도 안 난다.',
    talkBoss: '큰 놈이군. …보수에 포함이냐?',
    talkReaper: '…저건 베어도 죽지 않아. 거리를 둬라.',
    talkLowHp: '…이 정도, 상처 축에도 못 든다.',
    talkCycle: '…연장 근무다. 수당은 챙겨둬라.',
  ),
  // 10 ─────────────────────────────────────────────
  Character(
    id: 'ciel',
    name: '시엘',
    title: '한 몸에 두 목소리, 쌍둥이 마법사',
    bonusDesc: '투사체 +1 · 체력 −10%',
    tint: Color(0xFFD6EFFF),
    color: Color(0xFF4FC3F7),
    amount: 1,
    hpMult: 0.90,
    intro: [
      StoryLine(false, '안녕, 대장. 나는 시엘. …그리고 이쪽 목소리는 동생 노엘. 「안녕!」'),
      StoryLine.choose(StoryChoice(
        a: '둘 다 잘 부탁한다.',
        b: '…몸은 하나 아닌가?',
        reactA: '「우와, 둘 다래!」 …기뻐하네. 나도야.',
        reactB: '마법의 세계에선 흔한 일이야. 「신경 쓰면 지는 거야~」',
      )),
      StoryLine(true, '…그래. 셋이서 출격이다.'),
      StoryLine(false, '주문 영창 준비 완료. 「가자가자~!」'),
    ],
    victory: [
      StoryLine(false, '생존 확인. 「우리가 제일 많이 쐈지?!」'),
      StoryLine.choose(StoryChoice(
        a: '마법 두 배는 확실히 강하군.',
        b: '둘이 싸우지는 말고.',
        reactA: '당연해. 우린 언제나 2인분이니까. 「브이!」',
        reactB: '「언니가 먼저 시비 걸었어!」 …그건 네 착각이야, 노엘.',
      )),
      StoryLine(false, '다음 밤도 둘이서… 「셋이서!」 …그래, 대장이랑 셋이서.'),
    ],
    defeat: [
      StoryLine(false, '마력이… 바닥났어… 「언니, 괜찮아…?」'),
      StoryLine(true, '둘 다 잘 버텼다. 돌아가자.'),
      StoryLine(false, '…응. 「다음엔 세 배로 쏠 거야…」'),
    ],
    banter: [
      [
        StoryLine(false, '마력 충전 완료! 「가득가득~」'),
        StoryLine(true, '둘 다 준비됐군.'),
      ],
      [
        StoryLine(false, '「언니보다 내가 더 쐈어!」 …아니야, 내가 더 쐈어.'),
        StoryLine(true, '…둘 다 잘했다.'),
      ],
      [
        StoryLine(false, '대장, 우리 호흡 좋지? 「척척!」'),
        StoryLine(true, '셋이서 한 팀이지.'),
      ],
      [
        StoryLine(false, '「끝나면 간식!」 …나도 찬성이야.'),
        StoryLine(true, '…협상 성립이다.'),
      ],
    ],
    talkFirstLevel: '새 마력 회로 개방! 「다음엔 어떤 거 고를 거야?」',
    talkEvolution: '금단의 상자가 공명하고 있어… 「열어보자!」',
    talkEncircle: '포위 마법진…! 「우리 걸로 덮어쓰자!」',
    talkBoss: '대형 마수 감지. 「영창 개시~!」',
    talkReaper: '…저건 마법이 안 통해. 「도, 도망치자…」',
    talkLowHp: '방어막 붕괴… 「언니, 뒤로!」',
    talkCycle: '「한 판 더~!」 …체력 관리 부탁해, 대장.',
  ),
];
