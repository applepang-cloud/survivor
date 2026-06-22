import 'package:flutter/material.dart';

import '../game/survivor_game.dart';

/// 우측 상단 음소거 토글 버튼 (항상 표시).
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
          child: Material(
            color: Colors.black54,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                setState(() => widget.game.audio.enabled = !on);
              },
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(on ? Icons.volume_up : Icons.volume_off,
                    color: Colors.white, size: 22),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
