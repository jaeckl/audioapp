import 'package:flutter/material.dart';

import 'play_deck_theme.dart';

/// Settings panel for octave / key range / scale.
class OctavePanel extends StatelessWidget {
  const OctavePanel({
    super.key,
    required this.octaveOffset,
    required this.rowCount,
    required this.scaleId,
    required this.inKeyOnly,
    required this.rootName,
    required this.onOctaveDelta,
    required this.onRowCountChanged,
    required this.onScaleChanged,
    required this.onInKeyToggle,
  });

  final int octaveOffset;
  final int rowCount;
  final String scaleId;
  final bool inKeyOnly;
  final String rootName;
  final ValueChanged<int> onOctaveDelta;
  final ValueChanged<int> onRowCountChanged;
  final ValueChanged<String> onScaleChanged;
  final VoidCallback onInKeyToggle;

  static const _scaleOptions = [
    {'id': 'chromatic', 'label': 'Chrom'},
    {'id': 'major', 'label': 'Major'},
    {'id': 'minor', 'label': 'Minor'},
    {'id': 'pentatonic', 'label': 'Penta'},
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: PlayDeckTheme.panelBackground,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        children: [
          _SectionTitle(text: 'Octave'),
          Row(
            children: [
              _RoundIconButton(icon: Icons.remove, onTap: () => onOctaveDelta(-1)),
              Expanded(
                child: Center(
                  child: Text(
                    '${octaveOffset >= 0 ? '+' : ''}$octaveOffset',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w300,
                      color: PlayDeckTheme.railActive,
                    ),
                  ),
                ),
              ),
              _RoundIconButton(icon: Icons.add, onTap: () => onOctaveDelta(1)),
            ],
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Key region: $rootName$octaveOffset',
              style: const TextStyle(fontSize: 11, color: PlayDeckTheme.railLabel),
            ),
          ),
          const SizedBox(height: 14),
          _SectionTitle(text: 'Rows (1–3)'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var r = 1; r <= 3; r++)
                _Pill(
                  label: r == 1 ? '1 row' : r == 2 ? '2 rows' : '3 rows',
                  selected: rowCount == r,
                  onTap: () => onRowCountChanged(r),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _SectionTitle(text: 'Scale'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final opt in _scaleOptions)
                _Pill(
                  label: opt['label']!,
                  selected: scaleId == opt['id'],
                  onTap: () => onScaleChanged(opt['id']!),
                ),
              _Pill(
                label: 'In key',
                selected: inKeyOnly,
                onTap: onInKeyToggle,
              ),
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

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: PlayDeckTheme.optionIdle,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: PlayDeckTheme.railActive, size: 18),
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
