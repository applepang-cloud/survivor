import 'package:flutter/material.dart';

import '../game/survivor_game.dart';

/// 우하단 컨트롤 — 일시정지(⏸) + 음소거 토글 (모바일 대응)
class SoundButton extends StatefulWidget {
  const SoundButton({super.key, required this.game});
  final SurvivorGame game;

  @override
  State<SoundButton> createState() => _SoundButtonState();
}

class _SoundButtonState extends State<SoundButton> {
  @override
  Widget build(BuildContext context) {
    final on = widget.game.audio.enabled;
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _round(
                icon: Icons.pause,
                onTap: widget.game.togglePause,
              ),
              const SizedBox(width: 8),
              _round(
                icon: on ? Icons.volume_up : Icons.volume_off,
                onTap: () {
                  setState(() {
                    widget.game.audio.setEnabled(!on);
                    widget.game.meta.muted = on; // 음소거 상태 기억
                    widget.game.meta.save();
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _round({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
