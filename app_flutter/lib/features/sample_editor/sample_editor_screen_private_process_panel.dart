part of 'sample_editor_screen.dart';

class _ProcessPanel extends StatefulWidget {
  const _ProcessPanel({
    required this.gain,
    required this.loop,
    required this.repitch,
    required this.reversed,
    required this.onGainChanged,
    required this.onLoop,
    required this.onRepitch,
    required this.onReverse,
    required this.onNormalize,
  });
  final double gain;
  final bool loop, repitch, reversed;
  final ValueChanged<double> onGainChanged;
  final VoidCallback onLoop, onRepitch, onReverse, onNormalize;

  @override
  State<_ProcessPanel> createState() => _ProcessPanelState();
}
