import 'package:flutter/material.dart';

import '../game/survivor_game.dart';
import '../ui/portrait.dart';

/// VN식 스토리 대화 — 하단 대화창, 탭하면 다음 줄 (니케/블루아카식 브리핑 연출).
class StoryOverlay extends StatelessWidget {
  const StoryOverlay({super.key, required this.game});
  final SurvivorGame game;

  @override
  Widget build(BuildContext context) {
    if (game.storyLines.isEmpty) return const SizedBox.shrink();
    final line = game.storyLines[game.storyIndex.clamp(
        0, game.storyLines.length - 1)];
    final c = game.character;
    final isCmd = line.commander;
    final nameColor = isCmd ? const Color(0xFFFFD54F) : c.color;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: game.advanceStory,
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        child: Column(
          children: [
            const Spacer(),
            // 대화 박스
            Container(
              margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              padding: const EdgeInsets.all(14),
              constraints: const BoxConstraints(maxWidth: 760),
              decoration: BoxDecoration(
                color: const Color(0xF01A2230),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: nameColor, width: 2),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 화자: 대원은 초상화, 대장은 계급장 아이콘
                  isCmd
                      ? Container(
                          width: 72,
                          height: 72,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0xFFFFD54F), width: 2),
                          ),
                          child: const Text('🎖️',
                              style: TextStyle(fontSize: 34)),
                        )
                      : CharacterPortrait(game: game, character: c),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 이름표
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: nameColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isCmd ? '대장 (나)' : c.name,
                            style: TextStyle(
                                color: nameColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(line.text,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                height: 1.5)),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            game.storyIndex < game.storyLines.length - 1
                                ? '탭하여 계속 ▶'
                                : '탭하여 시작 ▶▶',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
