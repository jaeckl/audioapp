import 'package:flutter/material.dart';

import 'piano_roll_center_mode.dart';
import 'piano_roll_theme.dart';

part 'piano_roll_context_strip_mode_segment.dart';
part 'piano_roll_context_strip_segment_tab.dart';
part 'piano_roll_context_strip_context_chip.dart';
part 'piano_roll_context_strip_mode_chip.dart';

/// Secondary chrome row below the MIDI editor app bar: mode segment + context chips.
class PianoRollContextStrip extends StatelessWidget {
  const PianoRollContextStrip({
    super.key,
    required this.centerMode,
    required this.onCenterModeChanged,
    required this.showCompTab,
    required this.showHarmonicTab,
    required this.snapLabel,
    this.scaleLabel,
    required this.onViewTap,
    this.modeChip,
  });

  static const height = 44.0;

  final PianoRollCenterMode centerMode;
  final ValueChanged<PianoRollCenterMode> onCenterModeChanged;
  final bool showCompTab;
  final bool showHarmonicTab;
  final String snapLabel;
  final String? scaleLabel;
  final VoidCallback onViewTap;

  /// `COMP` or `EDIT` when the clip has a multi-take comp workflow.
  final String? modeChip;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: PianoRollTheme.dockBackground,
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              _ModeSegment(
                centerMode: centerMode,
                showCompTab: showCompTab,
                showHarmonicTab: showHarmonicTab,
                onChanged: onCenterModeChanged,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (modeChip != null) ...[
                        _ModeChip(label: modeChip!),
                        const SizedBox(width: 6),
                      ],
                      if (scaleLabel != null) ...[
                        _ContextChip(
                          label: scaleLabel!,
                          onTap: onViewTap,
                        ),
                        const SizedBox(width: 6),
                      ],
                      _ContextChip(
                        label: snapLabel,
                        onTap: onViewTap,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
