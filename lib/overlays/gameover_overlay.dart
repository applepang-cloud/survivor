import 'package:flutter/material.dart';

import '../game/survivor_game.dart';

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({super.key, required this.game});
  final SurvivorGame game;

  String _fmt(int t) {
    final m = (t ~/ 60).toString().padLeft(2, '0');
    final s = (t % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.82),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💀 GAME OVER',
                style: TextStyle(
                    color: Color(0xFFEF5350),
                    fontSize: 40,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            _stat('⏱ 생존 시간', _fmt(game.finalTime)),
            _stat('⭐ 레벨', '${game.finalLevel}'),
            _stat('☠ 처치', '${game.finalKills}'),
            _stat('🪙 골드', '${game.finalGold}'),
            const SizedBox(height: 28),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: game.startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF42A5F5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('다시 하기',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 14),
                OutlinedButton(
                  onPressed: game.backToMenu,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('메뉴',
                      style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 17)),
          const SizedBox(width: 16),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
