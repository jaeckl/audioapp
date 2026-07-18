import 'package:flutter/material.dart';

import '../piano_roll/piano_roll_theme.dart';
import 'harmonic_assistant_spec.dart';
import 'harmonic_note_ops.dart';

/// Compact voicing chips for Harmonic tool panel.
class HarmonicVariationBar extends StatelessWidget {
  const HarmonicVariationBar({
    super.key,
    required this.params,
    required this.onChanged,
  });

  final HarmonicToolParams params;
  final ValueChanged<HarmonicToolParams> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _pill(
            '7ths',
            params.sevenths,
            () {
              final next = params.copy()..sevenths = !params.sevenths;
              onChanged(next);
            },
          ),
          _pill(
            'Open',
            params.width == HarmonicVoicingWidth.open,
            () {
              final next = params.copy()
                ..width = params.width == HarmonicVoicingWidth.open
                    ? HarmonicVoicingWidth.close
                    : HarmonicVoicingWidth.open;
              onChanged(next);
            },
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, bool active, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: Material(
        color: active ? PianoRollTheme.accent : const Color(0xFF25252C),
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : PianoRollTheme.label,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
