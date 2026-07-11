part of 'curve_editor_screen.dart';

enum CurveEditorTool {
  /// Select & drag existing breakpoints. Tap to select (max 2).
  /// With 2 selected, shape-insert button becomes active.
  select,

  /// Freehand draw — drag across canvas to replace breakpoints in the drawn X-range.
  draw,

  /// Tap a breakpoint to delete it. Endpoints cannot be deleted.
  erase,
}
