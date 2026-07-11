import 'package:flutter/material.dart';

import 'play_deck_theme.dart';
import 'play_scale.dart';

part 'octave_panel_section_title.dart';
part 'octave_panel_round_icon_button.dart';
part 'octave_panel_pill.dart';

/// Settings panel for octave / key range / scale.
class OctavePanel extends StatelessWidget {
  const OctavePanel({
    super.key,
    required this.octaveOffset,
    required this.rowCount,
    required this.scaleId,
    required this.inKeyOnly,
    required this.rootName,
    required this.velocityCurve,
    required this.quantize,
    required this.customScales,
    required this.onOctaveDelta,
    required this.onRowCountChanged,
    required this.onScaleChanged,
    required this.onInKeyToggle,
    required this.onVelocityCurveChanged,
    required this.onQuantizeChanged,
    required this.onEditCustomScales,
  });

  final int octaveOffset;
  final int rowCount;
  final String scaleId;
  final bool inKeyOnly;
  final String rootName;
  final VelocityCurve velocityCurve;
  final CaptureQuantize quantize;
  final List<PlayScale> customScales;
  final ValueChanged<int> onOctaveDelta;
  final ValueChanged<int> onRowCountChanged;
  final ValueChanged<String> onScaleChanged;
  final VoidCallback onInKeyToggle;
  final ValueChanged<VelocityCurve> onVelocityCurveChanged;
  final ValueChanged<CaptureQuantize> onQuantizeChanged;
  final VoidCallback onEditCustomScales;

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
          const _SectionTitle(text: 'Octave'),
          Row(
            children: [
              _RoundIconButton(
                  icon: Icons.remove, onTap: () => onOctaveDelta(-1)),
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
              style:
                  const TextStyle(fontSize: 11, color: PlayDeckTheme.railLabel),
            ),
          ),
          const SizedBox(height: 14),
          const _SectionTitle(text: 'Rows (1–3)'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var r = 1; r <= 3; r++)
                _Pill(
                  label: r == 1
                      ? '1 row'
                      : r == 2
                          ? '2 rows'
                          : '3 rows',
                  selected: rowCount == r,
                  onTap: () => onRowCountChanged(r),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const _SectionTitle(text: 'Scale'),
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
              for (final custom in customScales)
                _Pill(
                  label: custom.label,
                  selected: scaleId == custom.id,
                  onTap: () => onScaleChanged(custom.id),
                ),
              _Pill(
                label: 'In key',
                selected: inKeyOnly,
                onTap: onInKeyToggle,
              ),
              _Pill(label: 'Edit', selected: false, onTap: onEditCustomScales),
            ],
          ),
          const SizedBox(height: 14),
          const _SectionTitle(text: 'Velocity curve'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final c in VelocityCurve.values)
                _Pill(
                  label: c.label,
                  selected: velocityCurve == c,
                  onTap: () => onVelocityCurveChanged(c),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const _SectionTitle(text: 'Capture quantize'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final q in CaptureQuantize.values)
                _Pill(
                  label: q.label,
                  selected: quantize == q,
                  onTap: () => onQuantizeChanged(q),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
