import 'package:flutter/material.dart';

import 'play_deck_theme.dart';

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
              _Pill(label: 'Sustain', selected: sustain, onTap: onSustainToggle),
              _Pill(label: 'Repeat', selected: repeat, onTap: onRepeatToggle),
              _Pill(label: 'Metronome', selected: metronome, onTap: onMetronomeToggle),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          letterSpacing: 1.4,
          color: PlayDeckTheme.railLabel,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? PlayDeckTheme.optionActive : PlayDeckTheme.optionIdle,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: selected ? Colors.black : PlayDeckTheme.optionLabel,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
