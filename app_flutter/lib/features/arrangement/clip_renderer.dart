import 'package:flutter/material.dart';

import 'arrangement_clip_theme.dart';

part 'clip_renderer_arrangement_clip_chrome.dart';
part 'clip_renderer_clip_content_painter.dart';

/// Paints condensed clip content inside the arrangement timeline.
abstract class ClipRenderer {
  const ClipRenderer();

  Color get clipBackgroundColor;

  Color get clipContentBackgroundColor;

  Color get clipBorderColor => ArrangementClipTheme.midiClipBorder;

  Color get highlightBorderColor => ArrangementClipTheme.highlightBorder;

  Color get highlightShadowColor => ArrangementClipTheme.highlightShadow;

  /// Paints notes, waveform, or other condensed content inside [contentRect].
  void paintContent(Canvas canvas, Rect contentRect);

  /// Optional label row above the painted content (e.g. sample name).
  String? get headerLabel => null;

  /// Centered fallback when there is nothing to paint in the body.
  String? get emptyPlaceholder => null;

  /// When true, a small loop badge is painted on the clip chrome.
  bool get loopContentEnabled => false;

  /// Optional mode badge (e.g. COMP / EDIT on multi-take MIDI clips).
  String? get contentBadgeLabel => null;
}

/// Shared chrome + [ClipRenderer] body for arrangement clip blocks.
