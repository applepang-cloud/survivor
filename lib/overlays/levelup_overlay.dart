import 'package:flutter/material.dart';

import '../game/survivor_game.dart';
import '../ui/bitmap_font.dart';

/// 원작은 레벨업 시 "LEVEL UP / Press ESC to continue" 정지 화면 후
/// 정해진 스크립트대로 무기를 획득/강화한다 (선택지 없음).
class LevelUpOverlay extends StatelessWidget {
  const LevelUpOverlay({super.key, required this.game});
  final SurvivorGame game;

  @override
  Widget build(BuildContext context) {
    final next = game.level + 1;
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BitmapText('LEVEL UP', scale: 3.2, color: Color(0xFFFFD54F)),
            const SizedBox(height: 10),
            Text(_unlockText(next),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: game.continueAfterLevelUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF677CED),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 44, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('계속하기',
                  style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  /// 다음 레벨에서 잠금 해제되는 내용 (원작 afterLevelUp 스크립트)
  String _unlockText(int level) {
    switch (level) {
      case 2:
        return '🔗 채찍 획득! 좌우로 휘두른다';
      case 3:
        return '🗡️ 검 획득! 이동 방향으로 던진다';
      case 4:
        return '🛡️ 방패 획득! 주위를 회전한다';
      case 5:
        return '🔥 화염구 획득! 적을 향해 날아간다';
      case 6:
        return '⚡ 번개 획득! 무작위 적을 강타';
      case 7:
        return '🏹 화살 연사 속도 ↑';
      case 8:
        return '🔗 채찍 범위 ↑';
      case 9:
        return '🛡️ 방패 4개로!';
      case 10:
        return '🗡️ 검 연사 속도 ↑';
      case 11:
        return '🔥 화염구 연사 속도 ↑';
      case 12:
        return '⚡ 번개 연사 속도 ↑';
      case 13:
        return '🏹 화살 초고속 연사!';
      case 14:
        return '🔗 채찍 연사 속도 ↑';
      case 15:
        return '🛡️ 방패 8개로!';
      case 16:
        return '🗡️ 검 초고속 연사!';
      case 17:
        return '🔥 화염구 4배 발사!';
      case 18:
        return '⚡ 번개 4배 발사!';
      case 19:
        return '🛡️ 방패 회전 속도 ↑';
      case 20:
        return '💥 화살·검·채찍 데미지 대폭 ↑';
      default:
        return '계속 살아남아라!';
    }
  }
}
