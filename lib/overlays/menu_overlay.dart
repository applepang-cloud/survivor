import 'package:flutter/material.dart';

import '../game/survivor_game.dart';

class MenuOverlay extends StatelessWidget {
  const MenuOverlay({super.key, required this.game});
  final SurvivorGame game;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/main.png', fit: BoxFit.cover),
        Container(color: Colors.black.withValues(alpha: 0.35)),
        Align(
          alignment: const Alignment(0, 0.55),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: game.startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF677CED),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 56, vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('게임 시작',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '방향키 / WASD / 조이스틱으로 이동 · 공격은 자동\n레벨업마다 새 무기를 얻습니다 (최대 Lv.20)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
