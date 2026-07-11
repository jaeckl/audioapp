part of 'arrangement_playhead_marker.dart';

class ArrangementPlayheadRulerPill extends StatelessWidget {
  const ArrangementPlayheadRulerPill({
    super.key,
    required this.color,
    required this.iconColor,
    required this.playing,
  });

  final Color color;
  final Color iconColor;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        elevation: 4,
        color: color,
        shape: const CircleBorder(),
        child: SizedBox(
          width: ArrangementPlayheadMarkerTheme.pillSize,
          height: ArrangementPlayheadMarkerTheme.pillSize,
          child: Icon(
            playing ? Icons.stop : Icons.play_arrow,
            size: 18,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}
