import 'package:flutter/material.dart';

import '../content_library/library_theme.dart';
import '../piano_roll/piano_roll_theme.dart';

/// Automation editor chrome — piano-roll layout with automation accent.
abstract final class AutomationEditorTheme {
  static const accent = LibraryTheme.accentAutomation;
  static const background = PianoRollTheme.background;
  static const surface = PianoRollTheme.surface;
  static const rulerBackground = PianoRollTheme.rulerBackground;
  static const valueColumnBackground = PianoRollTheme.keyColumnBackground;
  static const gridBar = PianoRollTheme.gridBar;
  static const gridBeat = PianoRollTheme.gridBeat;
  static const gridValue = Color(0x14FFFFFF);
  static const clipRegionFill = Color(0x0AB48CFF);
  static const outsideClipDim = PianoRollTheme.outsideClipDim;
  static const clipBoundary = accent;
  static const dockBackground = PianoRollTheme.dockBackground;
  static const dockActive = PianoRollTheme.dockActive;
  static const dockIcon = PianoRollTheme.dockIcon;
  static const dockIconActive = accent;
  static const labelMuted = PianoRollTheme.labelMuted;
  static const label = PianoRollTheme.label;
  static const nodeFill = accent;
  static const nodeSelected = Colors.white;
  static const curveStroke = accent;
  static const saveOk = PianoRollTheme.saveOk;
  static const saveError = PianoRollTheme.saveError;
  static const panelBackground = LibraryTheme.panelBackground;
}
