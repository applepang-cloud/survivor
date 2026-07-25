import 'package:flutter/material.dart';

import '../game/survivor_game.dart';
import '../ui/bitmap_font.dart';

/// 보물상자 개봉 결과 — 무기 진화 / 골드
class ChestOverlay extends StatelessWidget {
  const ChestOverlay({super.key, required this.game});
  final SurvivorGame game;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.78),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎁', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 8),
            const BitmapText('TREASURE!', scale: 2.2, color: Color(0xFFFFD54F)),
            const SizedBox(height: 16),
            ...game.chestLines.map((line) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(line,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: line.startsWith('무기 진화')
                            ? const Color(0xFFFFD54F)
                            : Colors.white,
                        fontSize: line.startsWith('무기 진화') ? 20 : 16,
                        fontWeight: line.startsWith('무기 진화')
                            ? FontWeight.w900
                            : FontWeight.normal,
                      )),
                )),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: game.closeChest,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF677CED),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('확인',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
