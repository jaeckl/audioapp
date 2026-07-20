part of 'mood_fx_panels.dart';

/// Direction mode picker (engine discrete 0..4) — sits in Shape tab plate.
class _StutterDirectionPicker extends StatelessWidget {
  const _StutterDirectionPicker({
    required this.direction,
    required this.accent,
    required this.onChanged,
  });

  final double direction;
  final Color accent;
  final ValueChanged<double> onChanged;

  static const _modes = <(double, String)>[
    (0, 'FWD'),
    (1, 'REV'),
    (2, 'ALT'),
    (3, 'FLIP'),
    (4, 'RAND'),
  ];

  @override
  Widget build(BuildContext context) {
    final selected = direction.round().clamp(0, 4);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'DIRECTION',
          textAlign: TextAlign.center,
          style: DevicePanelTheme.sectionLabel,
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 42,
          child: Row(
            children: [
              for (var i = 0; i < _modes.length; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: _StutterMiniToggle(
                    label: _modes[i].$2,
                    active: selected == _modes[i].$1.round(),
                    accent: accent,
                    onTap: () => onChanged(_modes[i].$1),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
