part of 'sample_editor_screen.dart';

class _SampleLanePainter extends CustomPainter {
  const _SampleLanePainter(
      {required this.pixelsPerBeat,
      required this.originX,
      required this.gridStepBeats});
  final double pixelsPerBeat;
  final double originX;
  final double gridStepBeats;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = AutomationEditorTheme.background);
    final step = math.max(.03125, gridStepBeats);
    final firstIndex = ((-originX / pixelsPerBeat) / step).floor();
    final lastIndex = (((size.width - originX) / pixelsPerBeat) / step).ceil();
    for (var index = firstIndex; index <= lastIndex; index++) {
      final beat = index * step;
      final isBar = (beat % 4).abs() < .0001;
      final isBeat = (beat - beat.round()).abs() < .0001;
      canvas.drawLine(
          Offset(originX + beat * pixelsPerBeat, 0),
          Offset(originX + beat * pixelsPerBeat, size.height),
          Paint()
            ..color = isBar
                ? AutomationEditorTheme.gridBar
                : isBeat
                    ? AutomationEditorTheme.gridBeat
                    : AutomationEditorTheme.gridSubdivision
            ..strokeWidth = isBar ? 1 : 0.5);
    }
    canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        Paint()..color = Colors.white.withValues(alpha: .035));
  }

  @override
  bool shouldRepaint(covariant _SampleLanePainter old) =>
      old.pixelsPerBeat != pixelsPerBeat ||
      old.originX != originX ||
      old.gridStepBeats != gridStepBeats;
}
