import 'package:flutter/material.dart';

import 'play_deck_theme.dart';

part 'performance_panel_section_title.dart';
part 'performance_panel_pill.dart';

class PerformancePanel extends StatelessWidget {
  const PerformancePanel({
    super.key,
    required this.latch,
    required this.sustain,
    required this.repeat,
    required this.metronome,
    required this.chordMemory,
    required this.onLatchToggle,
    required this.onSustainToggle,
    required this.onRepeatToggle,
    required this.onMetronomeToggle,
    required this.onStoreChord,
    required this.onRecallChord,
  });

  final bool latch;
  final bool sustain;
  final bool repeat;
  final bool metronome;
  final List<ChordMemory> chordMemory;
  final VoidCallback onLatchToggle;
  final VoidCallback onSustainToggle;
  final VoidCallback onRepeatToggle;
  final VoidCallback onMetronomeToggle;
  final VoidCallback onStoreChord;
  final ValueChanged<int> onRecallChord;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: PlayDeckTheme.panelBackground,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        children: [
          const _SectionTitle(text: 'Performance'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _Pill(label: 'Latch', selected: latch, onTap: onLatchToggle),
              _Pill(
                  label: 'Sustain', selected: sustain, onTap: onSustainToggle),
              _Pill(label: 'Repeat', selected: repeat, onTap: onRepeatToggle),
              _Pill(
                  label: 'Metronome',
                  selected: metronome,
                  onTap: onMetronomeToggle),
            ],
          ),
          const SizedBox(height: 14),
          const _SectionTitle(text: 'Chord memory'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < chordMemory.length; i++)
                _Pill(
                  label: '${i + 1}: ${chordMemory[i].quality.label}',
                  selected: false,
                  onTap: () => onRecallChord(i),
                ),
              _Pill(label: 'Save current', selected: true, onTap: onStoreChord),
            ],
          ),
        ],
      ),
    );
  }
}
