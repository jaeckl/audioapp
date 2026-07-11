import 'package:flutter/material.dart';

import 'play_deck_theme.dart';

part 'mod_strip_label.dart';
part 'mod_strip_hint.dart';
part 'mod_strip_readout.dart';
part 'mod_strip_readout_painter.dart';

/// Visual-only readout for live modulation and pitch bend.
///
/// Mod and bend are no longer dragged from a strip — the user drags
/// horizontally / vertically while holding a key or pad (see
/// `PlayKeyboard` and `MpcPadGrid`). This widget only mirrors the
/// current values so the musician can see what they're doing.
class ModStrip extends StatelessWidget {
  const ModStrip({
    super.key,
    required this.modulation,
    required this.pitchBend,
  });

  final double modulation;
  final double pitchBend;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: ColoredBox(
        color: PlayDeckTheme.stripBackground,
        child: Row(
          children: [
            const SizedBox(width: 8),
            const _Label('MOD'),
            const SizedBox(width: 4),
            _Readout(
              value: modulation,
              color: const Color(0xFF7AB8E0),
            ),
            const SizedBox(width: 16),
            const _Label('BEND'),
            const SizedBox(width: 4),
            _Readout(
              value: pitchBend,
              color: const Color(0xFFE87B8A),
              center: true,
            ),
            const Spacer(),
            const _Hint('drag on a key'),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
