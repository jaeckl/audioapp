part of 'drum_machine_device_panel.dart';

class _PadMinimapPainter extends CustomPainter {
  const _PadMinimapPainter({required this.device, required this.bankStart});
  final DrumMachineDeviceSnapshot device;
  final int bankStart;

  @override
  void paint(Canvas canvas, Size size) {
    const columns = 4;
    const rows = 32;
    final cellW = size.width / columns;
    final cellH = size.height / rows;
    final empty = Paint()..color = const Color(0xFF30303A);
    final set = Paint()..color = const Color(0xFF8B7CF6);
    for (var note = 0; note < 128; note++) {
      final column = note % 4;
      final row = 31 - note ~/ 4;
      final rect = Rect.fromLTWH(column * cellW + 0.7, row * cellH + 0.45,
          cellW - 1.4, (cellH - 0.9).clamp(1, cellH));
      canvas.drawRect(
          rect, device.padForNote(note).devices.isEmpty ? empty : set);
    }
    final firstRow = 28 - bankStart ~/ 4;
    final viewport =
        Rect.fromLTWH(0.5, firstRow * cellH, size.width - 1, cellH * 4);
    canvas.drawRect(
        viewport,
        Paint()
          ..color = const Color(0xFFCEC6FF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(covariant _PadMinimapPainter oldDelegate) =>
      oldDelegate.device != device || oldDelegate.bankStart != bankStart;
}
