import 'package:flutter/material.dart';

import '../arrangement/arrangement_loop_region_marker.dart';
import 'piano_roll_theme.dart';

part 'midi_comp_context_bar_midi_comp_locked_bar.dart';
part 'midi_comp_context_bar_split_chip.dart';
part 'midi_comp_context_bar_boundary_segment.dart';
part 'midi_comp_context_bar_icon_btn.dart';

/// Slim contextual controls shown above the comp dock in Markers mode.
class MidiCompContextBar extends StatelessWidget {
  const MidiCompContextBar({
    super.key,
    required this.playheadBeat,
    required this.selectedMarkerBeat,
    required this.holdPrevious,
    required this.onSplitAtPlayhead,
    required this.onDeleteSelected,
    required this.onNudgeSelected,
    required this.onMarkerModeChanged,
  });

  final double playheadBeat;
  final double? selectedMarkerBeat;
  final bool? holdPrevious;
  final VoidCallback onSplitAtPlayhead;
  final VoidCallback onDeleteSelected;
  final ValueChanged<int> onNudgeSelected;
  final ValueChanged<bool> onMarkerModeChanged;

  static const _barHeight = 36.0;

  @override
  Widget build(BuildContext context) {
    final hasMarker = selectedMarkerBeat != null;
    return ColoredBox(
      color: PianoRollTheme.background,
      child: SizedBox(
        height: _barHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              _SplitChip(
                beatLabel: playheadBeat.toStringAsFixed(2),
                onTap: onSplitAtPlayhead,
              ),
              if (hasMarker) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Marker ${selectedMarkerBeat!.toStringAsFixed(2)}b',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: PianoRollTheme.labelMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _BoundarySegment(
                  holdPrevious: holdPrevious ?? true,
                  onChanged: onMarkerModeChanged,
                ),
                const SizedBox(width: 4),
                _IconBtn(
                  icon: Icons.chevron_left,
                  onTap: () => onNudgeSelected(-1),
                ),
                _IconBtn(
                  icon: Icons.chevron_right,
                  onTap: () => onNudgeSelected(1),
                ),
                _IconBtn(
                  icon: Icons.delete_outline,
                  destructive: true,
                  onTap: onDeleteSelected,
                ),
              ] else
                const Expanded(
                  child: Text(
                    'Split at playhead to insert marker',
                    style: TextStyle(
                      color: PianoRollTheme.labelMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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

/// Shown when comp is flattened — replaces dock + context bar.
