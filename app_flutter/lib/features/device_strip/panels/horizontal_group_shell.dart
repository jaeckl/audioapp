import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

part 'horizontal_group_shell_state.dart';

/// Shared horizontal button-group chrome — LFO connect, automation link,
/// long-press automate, modulation amount line (Bitcrusher / Filter modes).
class HorizontalGroupShell extends StatefulWidget {
  const HorizontalGroupShell({
    super.key,
    required this.width,
    required this.height,
    required this.value,
    required this.maxValue,
    required this.accent,
    required this.modulationActive,
    required this.modulationAmount,
    required this.automationActive,
    required this.connectModeActive,
    required this.linkModeActive,
    required this.child,
    this.onModulationAssign,
    this.onLinkTap,
    this.onAutomateRequest,
    this.flat = false,
  });

  final double width;
  final double height;
  final double value;
  final double maxValue;
  final double modulationAmount;
  final Color accent;
  final bool modulationActive;
  final bool automationActive;
  final bool connectModeActive;
  final bool linkModeActive;
  final Widget child;
  final ValueChanged<double>? onModulationAssign;
  final VoidCallback? onLinkTap;
  final VoidCallback? onAutomateRequest;

  /// No idle border/radius chrome — still shows connect/automation feedback.
  final bool flat;

  @override
  State<HorizontalGroupShell> createState() => _HorizontalGroupShellState();
}
