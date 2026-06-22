# SURVIVOR (Flutter + Flame)

뱀파이어 서바이버즈류 탑다운 생존 액션 게임. 원작 [pieceofcakey/Survivor](https://github.com/pieceofcakey/Survivor)(Phaser 3, JavaScript)를 **Flutter + Flame** 으로 충실 포팅했습니다.

🎮 **플레이: https://applepang-cloud.github.io/survivor/**

## 특징
- 원작의 스프라이트·비트맵 폰트를 그대로 사용한 1:1 그래픽
- 무기 6종(화살·채찍·검·방패·화염구·번개) 자동 공격
- 원작과 동일한 레벨업 스크립트(Lv2 채찍 … Lv20 데미지 강화)
- 시간대별 몹 스폰 스케줄, 보스, 아이템(자석·빙결·물약·전체처치)
- 직접 합성한 효과음(원작에는 없음), 음소거 토글

## 조작
- 이동: 방향키 / WASD / 좌하단 가상 조이스틱
- 공격은 자동 — 회피에 집중하세요

## 개발
```bash
flutter run -d chrome          # 실행
flutter test                   # 로직 테스트
dart run tool/gen_audio.dart   # 효과음 재생성
```

원작은 사운드가 없어 `tool/gen_audio.dart`로 효과음 WAV를 합성해 추가했습니다.
HUD/타이틀은 원작 `font.png`(AngelCode 비트맵 폰트)를 직접 렌더링합니다.

## 크레딧
- 원작 게임 디자인·에셋: [pieceofcakey/Survivor](https://github.com/pieceofcakey/Survivor)
- Flutter/Flame 포팅
