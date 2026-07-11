part of 'sample_editor_screen.dart';

class _SliceSliderRow extends StatelessWidget {
  const _SliceSliderRow({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.onChanged,
  });
  final String label, valueLabel;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Row(children: [
        SizedBox(
          width: 84,
          child: Text(label,
              style: const TextStyle(
                  color: AutomationEditorTheme.labelMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: value.clamp(0.0, 1.0),
              activeColor: ArrangementLoopRegionTheme.color,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 42,
          child: Text(valueLabel,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ),
      ]);
}
