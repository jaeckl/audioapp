import 'package:flutter/material.dart';

import 'piano_roll_center_mode.dart';
import 'piano_roll_theme.dart';

part 'piano_roll_context_strip_mode_segment.dart';
part 'piano_roll_context_strip_segment_tab.dart';
part 'piano_roll_context_strip_context_chip.dart';
part 'piano_roll_context_strip_mode_chip.dart';

/// Top chrome for the MIDI editor.
///
/// Portrait: compact Notes|Comp + cutout-height band.
/// Landscape: full mode segment (Notes/Harmonic/…/Comp) at fixed strip height.
class PianoRollContextStrip extends StatelessWidget {
  const PianoRollContextStrip({
    super.key,
    required this.centerMode,
    required this.onCenterModeChanged,
    required this.showCompTab,
    required this.showHarmonicTab,
    this.showDrumTab = false,
    required this.snapLabel,
    this.scaleLabel,
    required this.onViewTap,
    required this.onClose,
    this.landscape = false,
    this.trailing,
  });

  static const double minHeight = 40.0;
  static const double landscapeHeight = 44.0;

  static double heightFor(BuildContext context, {required bool landscape}) {
    if (landscape) return landscapeHeight;
    final top = MediaQuery.viewPaddingOf(context).top;
    return top > minHeight ? top : minHeight;
  }

  final PianoRollCenterMode centerMode;
  final ValueChanged<PianoRollCenterMode> onCenterModeChanged;
  final bool showCompTab;
  final bool showHarmonicTab;
  final bool showDrumTab;
  final String snapLabel;
  final String? scaleLabel;
  final VoidCallback onViewTap;
  final VoidCallback onClose;
  final bool landscape;

  /// Optional trailing control (overflow).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final height = heightFor(context, landscape: landscape);
    return ColoredBox(
      color: PianoRollTheme.dockBackground,
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _ModeSegment(
                      centerMode: centerMode,
                      showCompTab: showCompTab,
                      showHarmonicTab: showHarmonicTab,
                      showDrumTab: showDrumTab,
                      compactPortrait: !landscape,
                      onChanged: onCenterModeChanged,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (scaleLabel != null) ...[
                _ContextLabel(
                  label: scaleLabel!,
                  color: const Color(0xFF7EB8FF),
                  onTap: onViewTap,
                ),
                const SizedBox(width: 8),
              ],
              _ContextLabel(
                label: snapLabel,
                color: const Color(0xFFB8A0FF),
                onTap: onViewTap,
              ),
              const SizedBox(width: 4),
              _FlatCloseLabel(onTap: onClose),
              if (trailing != null) ...[
                const SizedBox(width: 4),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
