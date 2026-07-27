import 'package:flutter/material.dart';

import '../game/survivor_game.dart';
import '../ui/bitmap_font.dart';

/// 10분 생존 클리어 — 여기서 승리로 끝내거나, 사신을 피하며 기록 도전.
class ClearOverlay extends StatelessWidget {
  const ClearOverlay({super.key, required this.game});
  final SurvivorGame game;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 6),
            const BitmapText('STAGE CLEAR', scale: 2.6, color: Color(0xFFFFD54F)),
            const SizedBox(height: 10),
            const Text('30분을 버텨냈다 — 생존 성공!',
                style: TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 4),
            Text('클리어 보너스 +${SurvivorGame.kClearBonusGold} 🪙',
                style: const TextStyle(
                    color: Color(0xFFFFD54F),
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            if (game.endlessJustUnlocked)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('🔓 무한 모드 해금! (메뉴에서 선택 가능)',
                    style: TextStyle(
                        color: Color(0xFF80DEEA),
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
              ),
            const SizedBox(height: 8),
            const Text('이제 사신은 사라지지 않고 1분마다 늘어난다.',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: game.continueAfterClear,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8E24AA),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 26, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('👊 계속 도전 (무한)',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 14),
                ElevatedButton(
                  onPressed: game.finishRun,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB300),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 26, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('🏁 여기서 승리',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
