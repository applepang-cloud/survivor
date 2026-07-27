import 'package:flutter/material.dart';

import '../game/survivor_game.dart';
import '../game/data.dart';
import '../game/stats.dart';
import '../ui/bitmap_font.dart';
import '../ui/portrait.dart';

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
      child: Stack(
        fit: StackFit.expand,
        children: [
          _mainHud(),
          // 대원 무전 (좌측 중단, 자동 소멸)
          Align(
            alignment: const Alignment(-0.98, 0.1),
            child: ValueListenableBuilder<String?>(
              valueListenable: game.radio,
              builder: (context, text, _) {
                if (text == null) return const SizedBox.shrink();
                final c = game.character;
                return Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.68),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: c.color.withValues(alpha: 0.8), width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CharacterPortrait(
                          game: game, character: c, size: 44),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('📻 ${c.name}',
                                style: TextStyle(
                                    color: c.color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(text,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    height: 1.35)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // 중앙 경고 배너 (사신 예고 / 포위 이벤트)
          Align(
            alignment: const Alignment(0, -0.35),
            child: ValueListenableBuilder<String?>(
              valueListenable: game.banner,
              builder: (context, text, _) {
                if (text == null) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFFEF5350), width: 2),
                  ),
                  child: Text(text,
                      style: const TextStyle(
                          color: Color(0xFFFF8A80),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(color: Colors.black, blurRadius: 6)
                          ])),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _mainHud() {
    return ValueListenableBuilder<GameStats>(
        valueListenable: game.hud,
        builder: (context, st, _) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 경험치 바 (원작 상단 전체폭)
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
                      Row(children: [
                        _label('GOLD ${st.gold}'),
                        const SizedBox(width: 10),
                        _label('LVL ${st.level.toString().padLeft(3, '0')}'),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // 체력 바 (대원 이름 표시)
                  Row(
                    children: [
                      Text('${game.character.name} ❤️',
                          style: TextStyle(
                              color: game.character.color,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
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
                  const SizedBox(height: 4),
                  // 인벤토리: 무기 줄 + 장신구 줄 (VS 좌상단 인벤토리)
                  Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    children: [
                      for (final e in st.weapons.entries)
                        _badge(
                          st.evolved.contains(e.key)
                              ? kEvolutions[e.key]!.emoji
                              : kWeaponEmoji[e.key]!,
                          st.evolved.contains(e.key) ? 'MAX' : 'Lv${e.value}',
                          gold: st.evolved.contains(e.key),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    children: [
                      for (final e in st.passives.entries)
                        _badge(kPassives[e.key]!.emoji, 'Lv${e.value}'),
                    ],
                  ),
                  const Spacer(),
                  const SizedBox(height: 96),
                ],
              ),
            ),
          );
        });
  }

  Widget _label(String text, {double size = 16}) {
    // 원작 비트맵 폰트(font.png)로 렌더
    return BitmapText(text, scale: size / 22, color: Colors.white);
  }

  Widget _badge(String emoji, String? sub, {bool gold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: gold ? const Color(0xFFFFD54F) : Colors.white30,
            width: gold ? 1.6 : 1.0),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 17)),
        if (sub != null) ...[
          const SizedBox(width: 3),
          Text(sub,
              style: TextStyle(
                  color: gold ? const Color(0xFFFFD54F) : Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ],
      ]),
    );
  }
}
