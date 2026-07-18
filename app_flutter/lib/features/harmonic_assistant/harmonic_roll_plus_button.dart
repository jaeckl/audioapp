import 'package:flutter/material.dart';

import '../piano_roll/piano_roll_theme.dart';

/// Floating + on the piano roll for Harmonic / Progression insert.
class HarmonicRollPlusButton extends StatelessWidget {
  const HarmonicRollPlusButton({
    super.key,
    required this.onTap,
    this.tooltip = 'Insert after last chord',
  });

  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PianoRollTheme.accent,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: const SizedBox(
            width: 48,
            height: 48,
            child: Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}
