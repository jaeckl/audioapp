import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

part 'device_landscape_shell_device_landscape_shell_state.dart';

/// Fullscreen device editor: locks landscape and scales a fixed-design panel uniformly.
class DeviceLandscapeShell extends StatefulWidget {
  const DeviceLandscapeShell({
    super.key,
    required this.title,
    required this.designWidth,
    required this.designHeight,
    required this.child,
    this.actions = const [],
    this.onClose,
  });

  final String title;
  final double designWidth;
  final double designHeight;
  final Widget child;
  final List<Widget> actions;
  final VoidCallback? onClose;

  @override
  State<DeviceLandscapeShell> createState() => _DeviceLandscapeShellState();
}
