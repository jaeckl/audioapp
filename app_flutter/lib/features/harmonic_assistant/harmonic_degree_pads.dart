import 'package:flutter/material.dart';

import '../music_theory/diatonic_harmony.dart';
import '../piano_roll/piano_roll_theme.dart';
import '../play/play_scale.dart';

/// Compact diatonic degree chips for the Harmonic tool panel.
class HarmonicDegreePads extends StatelessWidget {
  const HarmonicDegreePads({
    super.key,
    required this.scale,
    required this.rootPitchClass,
    required this.sevenths,
    required this.armedDegree,
    required this.onDegreeTap,
  });

  final PlayScale scale;
  final int rootPitchClass;
  final bool sevenths;
  final int armedDegree;
  final ValueChanged<int> onDegreeTap;

  @override
  Widget build(BuildContext context) {
    final palette = DiatonicHarmony.palette(
      scale: scale,
      rootPitchClass: rootPitchClass,
      sevenths: sevenths,
    );
    return SizedBox(
      height: 32,
      child: Row(
        children: [
          for (final chord in palette)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: Material(
                  color: chord.degree == armedDegree
                      ? PianoRollTheme.accent
                      : const Color(0xFF2A2A34),
                  borderRadius: BorderRadius.circular(6),
                  child: InkWell(
                    onTap: () => onDegreeTap(chord.degree),
                    borderRadius: BorderRadius.circular(6),
                    child: Center(
                      child: Text(
                        chord.label,
                        style: TextStyle(
                          color: chord.degree == armedDegree
                              ? Colors.white
                              : PianoRollTheme.label,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
