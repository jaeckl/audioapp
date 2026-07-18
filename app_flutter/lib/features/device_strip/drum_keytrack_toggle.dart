import 'package:flutter/material.dart';

class DrumKeyTrackToggle extends StatelessWidget {
  const DrumKeyTrackToggle({
    super.key,
    required this.active,
    required this.accent,
    required this.onChanged,
  });

  final bool active;
  final Color accent;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final color = active ? accent : Colors.white38;
    return Tooltip(
      message: active
          ? 'Pitch follows incoming MIDI notes'
          : 'Use the fixed pitch knob value',
      child: Material(
        color: active
            ? accent.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(5),
        child: InkWell(
          key: const ValueKey('drum-keytrack-toggle'),
          onTap: () => onChanged(!active),
          borderRadius: BorderRadius.circular(5),
          child: SizedBox.square(
            dimension: 30,
            child: Icon(Icons.piano, size: 20, color: color),
          ),
        ),
      ),
    );
  }
}

String percussionPitchLabel(double normalized) {
  final semitones = ((normalized.clamp(0.0, 1.0) - 0.5) * 48).round();
  if (semitones == 0) return '0 st';
  return '${semitones > 0 ? '+' : ''}$semitones st';
}
