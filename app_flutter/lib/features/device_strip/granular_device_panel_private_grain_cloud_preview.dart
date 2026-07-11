part of 'granular_device_panel.dart';

class _GrainCloudPreview extends StatelessWidget {
  const _GrainCloudPreview({
    required this.position,
    required this.size,
    required this.density,
    required this.spray,
    required this.pitch,
  });

  final double position, size, density, spray, pitch;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _GrainCloudPainter(
          position: position,
          grainSize: size,
          density: density,
          spray: spray,
          pitch: pitch,
        ),
      );
}
