// 이매소녀(사용자 자체 프로젝트) 캐릭터 일러스트를 초상화용으로 리사이즈.
// `dart run tool/prep_portraits.dart` — 높이 900px PNG로 assets/portraits/ 에 저장.
// ※ 상용 아트: 공개 repo에는 커밋하지 않는다 (.gitignore).
import 'dart:io';
import 'package:image/image.dart' as img;

const src = r'C:\imae\game\Assets\Graphic\Art_Common\Illust\Character';

// 대원 id → 원본 일러스트 파일
const map = {
  'sera': 'character_01_illust.png',
  'yuna': 'character_00_illust.png', // 뿔·붉은 눈 — 냉정한 저격수
  'lize': 'character_02_illust.png',
  'hana': 'character_03_illust.png',
  'miko': 'character_10_illust.png', // 흰 구미호 — 무녀
  'roro': 'character_04_illust.png',
  'arin': 'character_05_illust.png',
  'noa': 'character_06_illust.png',
  'kaya': 'character_11_illust.png',
  'ciel': 'character_12_illust.png',
};

void main() {
  Directory('assets/portraits').createSync(recursive: true);
  for (final e in map.entries) {
    final bytes = File('$src\\${e.value}').readAsBytesSync();
    final im = img.decodePng(bytes)!;
    const h = 900;
    final w = (im.width * h / im.height).round();
    final r = img.copyResize(im,
        width: w, height: h, interpolation: img.Interpolation.average);
    final out = File('assets/portraits/${e.key}.png');
    out.writeAsBytesSync(img.encodePng(r, level: 9));
    stdout.writeln(
        '${e.key}.png  ${w}x$h  ${(out.lengthSync() / 1024).round()}KB');
  }
  stdout.writeln('done');
}
