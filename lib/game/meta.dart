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
