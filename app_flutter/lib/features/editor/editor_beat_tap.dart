import 'package:flutter/material.dart';

part 'editor_beat_tap_editor_beat_tap_surface_state.dart';

/// Tap a timeline beat without firing on scroll drags or during pinch.
class EditorBeatTapSurface extends StatefulWidget {
  const EditorBeatTapSurface({
    super.key,
    required this.pixelsPerBeat,
    required this.maxBeat,
    required this.enabled,
    required this.onBeat,
    required this.child,
  });

  final double pixelsPerBeat;
  final double maxBeat;
  final bool enabled;
  final ValueChanged<double> onBeat;
  final Widget child;

  static const double tapSlop = 10;

  @override
  State<EditorBeatTapSurface> createState() => _EditorBeatTapSurfaceState();
}
