import 'package:flutter/material.dart';

import '../game/survivor_game.dart';
import '../game/data.dart';
import '../ui/bitmap_font.dart';

class HudOverlay extends StatelessWidget {
  const HudOverlay({super.key, required this.game});
  final SurvivorGame game;

  String _fmt(double t) {
    final m = (t ~/ 60).toString().padLeft(2, '0');
    final s = (t.toInt() % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ValueListenableBuilder<GameStats>(
        valueListenable: game.hud,
        builder: (context, st, _) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 경험치 바 (원작 상단 전체폭, 파란색 0x677ced)
                  Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black, width: 3),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: (st.exp / st.maxExp).clamp(0.0, 1.0),
                        child: Container(color: const Color(0xFF677CED)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _label('KILLED ${st.kills.toString().padLeft(6, '0')}'),
                      _label(_fmt(st.time), size: 22),
                      _label('LVL ${st.level.toString().padLeft(3, '0')}'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // 체력 바
                  Row(
                    children: [
                      const Text('❤️', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor:
                                      (st.hp / st.maxHp).clamp(0.0, 1.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF5350),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Text('${st.hp.ceil()} / ${st.maxHp.toInt()}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final w in st.weapons)
                        _badge(kWeaponEmoji[w]!,
                            w == WeaponType.shield && st.shieldCount > 1
                                ? '×${st.shieldCount}'
                                : null),
                    ],
                  ),
                  const SizedBox(height: 96),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _label(String text, {double size = 16}) {
    // 원작 비트맵 폰트(font.png)로 렌더
    return BitmapText(text, scale: size / 22, color: Colors.white);
  }

  Widget _badge(String emoji, String? sub) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white30),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        if (sub != null)
          Text(sub,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}
