import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../content_library/library_theme.dart';
import 'modulation_vertical_bar.dart';
import 'modulator_polarity.dart';

part 'modulatable_spinner_shell_modulatable_spinner_shell_state.dart';
part 'modulatable_spinner_shell_spinner_background_glow_painter.dart';

/// Spinner chrome shared by sampler ROOT/TUNE boxes — supports LFO connect + automation.
class ModulatableSpinnerShell extends StatefulWidget {
  const ModulatableSpinnerShell({
    super.key,
    required this.width,
    required this.height,
    required this.accentColor,
    required this.borderAlpha,
    required this.child,
    this.modulationActive = false,
    this.modulationAmount = 0.0,
    this.liveModulationAmount = 0.0,
    this.modulatorPolarity = ModulatorPolarity.bipolar,
    this.connectModeActive = false,
    this.onModulationAssign,
    this.linkModeActive = false,
    this.automationActive = false,
    this.onLinkTap,
    this.onAutomateRequest,
  });

  final double width;
  final double height;
  final Color accentColor;
  final double borderAlpha;
  final Widget child;
  final bool modulationActive;
  final double modulationAmount;
  final double liveModulationAmount;
  final ModulatorPolarity modulatorPolarity;
  final bool connectModeActive;
  final ValueChanged<double>? onModulationAssign;
  final bool linkModeActive;
  final bool automationActive;
  final VoidCallback? onLinkTap;
  final VoidCallback? onAutomateRequest;

  @override
  State<ModulatableSpinnerShell> createState() =>
      _ModulatableSpinnerShellState();
}

/// Pulsing fill behind the spinner — matches [RotaryKnob] connect-mode glow.
