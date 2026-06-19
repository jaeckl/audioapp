import 'dart:math' as math;

import '../piano_roll/piano_roll_metrics.dart';

/// Layout tokens for the automation timeline editor.
abstract final class AutomationEditorMetrics {
  static const double valueColumnWidth = PianoRollMetrics.keyColumnWidth;
  static const double rulerHeight = PianoRollMetrics.rulerHeight;
  static const double toolDockHeight = PianoRollMetrics.toolDockHeight;
  static const double shapePanelHeight = 280;

  static const double pixelsPerBeat = PianoRollMetrics.pixelsPerBeat;
  static const double minPixelsPerBeat = PianoRollMetrics.minPixelsPerBeat;
  static const double maxPixelsPerBeat = PianoRollMetrics.maxPixelsPerBeat;

  static const double clipEndHitWidth = PianoRollMetrics.clipEndHitWidth;
  static const double nodeHitRadius = 18;
  static const double nodeRadius = 7;

  /// Top/bottom inset so 0% / 100% nodes and labels are not clipped.
  static const double valueAxisPadding = 28;

  static const double minPlotHeight = 120;
  static const double minValueAxisHeight = minPlotHeight + valueAxisPadding * 2;
  static const double maxValueAxisScale = 4.0;

  static double gridWidth(double lengthBeats, double pixelsPerBeat) =>
      PianoRollMetrics.gridWidth(lengthBeats, pixelsPerBeat);

  static double virtualLengthBeats(double clipLengthBeats) =>
      PianoRollMetrics.virtualLengthBeats(clipLengthBeats);

  static double beatFromDx(double dx, double pixelsPerBeat) => dx / pixelsPerBeat;

  static double plotHeight(double totalHeight) =>
      math.max(1.0, totalHeight - valueAxisPadding * 2);

  static double valueFromDy(double dy, double totalHeight) {
    final plot = plotHeight(totalHeight);
    final local = (dy - valueAxisPadding).clamp(0.0, plot);
    return (1.0 - local / plot).clamp(0.0, 1.0);
  }

  static double dyFromValue(double value, double totalHeight) {
    final plot = plotHeight(totalHeight);
    return valueAxisPadding + (1.0 - value.clamp(0.0, 1.0)) * plot;
  }

  static double dxFromBeat(double beat, double pixelsPerBeat) => beat * pixelsPerBeat;

  static double clampValueAxisHeight(double height, double viewportHeight) {
    final minH =
        viewportHeight > minValueAxisHeight ? viewportHeight : minValueAxisHeight;
    final maxH = viewportHeight * maxValueAxisScale;
    return height.clamp(minH, maxH);
  }
}

enum AutomationEditorTool { select, draw, multiErase }
