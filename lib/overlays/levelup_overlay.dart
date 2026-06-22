import 'package:flutter/material.dart';

import '../game/survivor_game.dart';
import '../ui/bitmap_font.dart';

/// 레벨업 시 3개 중 1개를 선택 (무기 획득/강화 + 패시브).
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
              const SizedBox(height: 18),
              ...options.map((o) => Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 6, horizontal: 16),
                    child: _card(o),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(UpgradeOption o) {
    return SizedBox(
      width: 320,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => game.applyUpgrade(o),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF26323F),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: o.color, width: 2),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: o.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(o.emoji, style: const TextStyle(fontSize: 26)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o.title,
                          style: TextStyle(
                              color: o.color,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(o.desc,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
