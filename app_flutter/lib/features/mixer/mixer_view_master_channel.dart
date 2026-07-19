part of 'mixer_view.dart';

class _MasterChannel extends StatelessWidget {
  const _MasterChannel({
    required this.title,
    required this.gain,
    required this.selected,
    required this.onGainChanged,
    required this.onSelect,
  });

  final String title;
  final double gain;
  final bool selected;
  final ValueChanged<double> onGainChanged;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onSelect,
        child: Container(
          width: 104,
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF2E2A1E) : const Color(0xFF28241A),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: selected
                  ? Colors.amber
                  : Colors.amber.withValues(alpha: .35),
            ),
          ),
          child: Column(children: [
            const Icon(Icons.speaker, size: 15, color: Colors.amber),
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 9, color: Colors.white70)),
            Expanded(
              child: RotatedBox(
                quarterTurns: 3,
                child: Slider(
                    value: gain.clamp(0.0, 1.0), onChanged: onGainChanged),
              ),
            ),
            Text('${(gain * 100).round()}%',
                style: const TextStyle(fontSize: 9, color: Colors.white54)),
            const SizedBox(height: 4),
            // Locked: virtual master always feeds the invisible device mix bus.
            Container(
              height: 22,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Text(
                'Device',
                style: TextStyle(fontSize: 9, color: Colors.white54),
              ),
            ),
          ]),
        ),
      );
}
