part of 'perform_panel.dart';

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.trailing,
    required this.onChanged,
  });
  final String label;
  final double value;
  final double min;
  final double max;
  final String trailing;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 11, color: PlayDeckTheme.railLabel)),
        ),
        Expanded(
          child: SliderTheme(
            data: const SliderThemeData(
              trackHeight: 2,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child:
                Slider(value: value, min: min, max: max, onChanged: onChanged),
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(trailing,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 11, color: PlayDeckTheme.railLabel)),
        ),
      ],
    );
  }
}
