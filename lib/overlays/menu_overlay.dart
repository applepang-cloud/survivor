import 'package:flutter/material.dart';

import '../game/survivor_game.dart';

/// 타이틀 메뉴 — 모드 토글(하이퍼/단축/무한, VS식 해금) + 시작.
class MenuOverlay extends StatefulWidget {
  const MenuOverlay({super.key, required this.game});
  final SurvivorGame game;

  @override
  State<MenuOverlay> createState() => _MenuOverlayState();
}

class _MenuOverlayState extends State<MenuOverlay> {
  SurvivorGame get game => widget.game;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/main.png', fit: BoxFit.cover),
        Container(color: Colors.black.withValues(alpha: 0.35)),
        Align(
          alignment: const Alignment(0, 0.62),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 모드 토글 (해금식, 중첩 가능)
              Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  _modeChip(
                    label: '🔥 하이퍼',
                    active: game.modeHyper,
                    unlocked: game.meta.hyperUnlocked,
                    lockHint: '25분 보스 처치 시 해금',
                    onTap: () =>
                        setState(() => game.modeHyper = !game.modeHyper),
                  ),
                  _modeChip(
                    label: '⏩ 단축',
                    active: game.modeTurbo,
                    unlocked: game.meta.turboUnlocked,
                    lockHint: '한 판 레벨 30 도달 시 해금',
                    onTap: () =>
                        setState(() => game.modeTurbo = !game.modeTurbo),
                  ),
                  _modeChip(
                    label: '♾️ 무한',
                    active: game.modeEndless,
                    unlocked: game.meta.endlessUnlocked,
                    lockHint: '30분 생존 클리어 시 해금',
                    onTap: () =>
                        setState(() => game.modeEndless = !game.modeEndless),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _modeDesc(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFFFFD54F),
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: game.startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF677CED),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 56, vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('게임 시작',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '이동: 방향키/WASD/조이스틱 · 공격 자동 · 30분 생존이 목표\n'
                  '10분 진화 개방 · 25분 보스 · 30분 사신',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _modeDesc() {
    final parts = <String>[];
    if (game.modeHyper) parts.add('하이퍼: 적 +50% 강화, 골드 +50%');
    if (game.modeTurbo) parts.add('단축: 2배속, 경험치 +25%');
    if (game.modeEndless) parts.add('무한: 사신 없음, 30분마다 강해지는 루프');
    return parts.isEmpty ? '기본 모드 (30분 생존)' : parts.join('  ·  ');
  }

  Widget _modeChip({
    required String label,
    required bool active,
    required bool unlocked,
    required String lockHint,
    required VoidCallback onTap,
  }) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: !unlocked
            ? Colors.black.withValues(alpha: 0.55)
            : active
                ? const Color(0xFF8E24AA)
                : Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: !unlocked
              ? Colors.white24
              : active
                  ? const Color(0xFFE1BEE7)
                  : Colors.white54,
          width: active ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            unlocked ? label : '🔒 $label',
            style: TextStyle(
              color: unlocked ? Colors.white : Colors.white38,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (!unlocked)
            Text(lockHint,
                style:
                    const TextStyle(color: Colors.white38, fontSize: 9)),
        ],
      ),
    );
    return unlocked
        ? GestureDetector(onTap: onTap, child: chip)
        : Tooltip(message: lockHint, child: chip);
  }
}
