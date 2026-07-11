part of 'time_fx_panels.dart';

class _PhaserPreview extends StatelessWidget {
  const _PhaserPreview({required this.device, required this.view});

  final PhaserDeviceSnapshot device;
  final PhaserViewTab view;

  @override
  Widget build(BuildContext context) => Container(
        key: const ValueKey('phaser-preview'),
        decoration: BoxDecoration(
          color: const Color(0xFF050508),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white10),
        ),
        child: CustomPaint(
          painter: _PhaserPreviewPainter(device: device, view: view),
        ),
      );
}
