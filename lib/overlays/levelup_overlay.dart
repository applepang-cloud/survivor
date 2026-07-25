import 'package:flutter/material.dart';

import '../game/survivor_game.dart';
import '../ui/bitmap_font.dart';

/// 레벨업 선택 — 3개(행운으로 4개) 중 1개 선택.
/// 하단에 새로고침/건너뛰기, 카드마다 지우기(🚫) 버튼.
class LevelUpOverlay extends StatelessWidget {
  const LevelUpOverlay({super.key, required this.game});
  final SurvivorGame game;

  @override
  Widget build(BuildContext context) {
    final options = game.pendingUpgrades;
    return Container(
      color: Colors.black.withValues(alpha: 0.72),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BitmapText('LEVEL UP', scale: 2.8, color: Color(0xFFFFD54F)),
              const SizedBox(height: 6),
              const Text('하나를 선택하세요',
                  style: TextStyle(color: Colors.white70, fontSize: 15)),
              const SizedBox(height: 14),
              ...options.map((o) => Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
                    child: _card(o),
                  )),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _actionBtn('🎲 새로고침 ×${game.rerollsLeft}',
                      game.rerollsLeft > 0 ? game.rerollUpgrades : null),
                  const SizedBox(width: 10),
                  _actionBtn('⏭️ 건너뛰기 ×${game.skipsLeft}',
                      game.skipsLeft > 0 ? game.skipUpgrade : null),
                ],
              ),
              if (game.banishesLeft > 0)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text('🚫 = 이번 판에서 그 선택지를 다시 보지 않기',
                      style: TextStyle(color: Colors.white38, fontSize: 11)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionBtn(String label, VoidCallback? onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white24,
        side: BorderSide(
            color: onTap == null ? Colors.white12 : Colors.white54),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 14)),
    );
  }

  Widget _card(UpgradeOption o) {
    return SizedBox(
      width: 340,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => game.applyUpgrade(o),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF26323F),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: o.color, width: 2),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: o.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(o.emoji, style: const TextStyle(fontSize: 25)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o.title,
                          style: TextStyle(
                              color: o.color,
                              fontSize: 17,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(o.desc,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                if (game.banishesLeft > 0)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: '지우기 (×${game.banishesLeft})',
                    onPressed: () => game.banishUpgrade(o),
                    icon: const Text('🚫', style: TextStyle(fontSize: 16)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
