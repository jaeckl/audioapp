import 'dart:math' as math;

import 'package:flutter/material.dart';

part 'editor_pinch_zoom_editor_pinch_zoom_state.dart';

/// Raw two-finger pinch scale for timeline editors (horizontal zoom).
class EditorPinchZoom extends StatefulWidget {
  const EditorPinchZoom({
    super.key,
    required this.child,
    required this.onStart,
    required this.onScale,
    required this.onPinchChanged,
  });

  final Widget child;
  final ValueChanged<Offset> onStart;
  final ValueChanged<double> onScale;
  final ValueChanged<bool> onPinchChanged;

  @override
  State<EditorPinchZoom> createState() => _EditorPinchZoomState();
}
