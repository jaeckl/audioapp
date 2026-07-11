part of 'mixer_view.dart';

class _MasterChannel extends StatelessWidget {
  const _MasterChannel(
      {required this.title, required this.gain, required this.onGainChanged});
  final String title;
  final double gain;
  final ValueChanged<double> onGainChanged;

  @override
  Widget build(BuildContext context) => Container(
        width: 74,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF28241A),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Colors.amber.withValues(alpha: .35)),
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
              child:
                  Slider(value: gain.clamp(0.0, 1.0), onChanged: onGainChanged),
            ),
          ),
          Text('${(gain * 100).round()}%',
              style: const TextStyle(fontSize: 9, color: Colors.white54)),
        ]),
      );
}
