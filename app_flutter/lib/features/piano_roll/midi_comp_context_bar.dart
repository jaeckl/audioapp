import 'package:flutter/material.dart';

import '../arrangement/arrangement_loop_region_marker.dart';
import 'piano_roll_theme.dart';

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
class MidiCompLockedBar extends StatelessWidget {
  const MidiCompLockedBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: PianoRollTheme.dockBackground,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'EDIT mode — comp markers locked',
                style: TextStyle(
                  color: PianoRollTheme.saveOk,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Re-open comp from ⋯ menu to edit takes and markers.',
                style: TextStyle(
                  color: PianoRollTheme.labelMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplitChip extends StatelessWidget {
  const _SplitChip({required this.beatLabel, required this.onTap});

  final String beatLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ArrangementLoopRegionTheme.color.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.call_split, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                'Split ${beatLabel}b',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoundarySegment extends StatelessWidget {
  const _BoundarySegment({
    required this.holdPrevious,
    required this.onChanged,
  });

  final bool holdPrevious;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      decoration: BoxDecoration(
        color: PianoRollTheme.dockBackground,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF3B3B49)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _seg('CUT', !holdPrevious, () => onChanged(false)),
          _seg('RING', holdPrevious, () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _seg(String label, bool active, VoidCallback onTap) {
    return Material(
      color: active
          ? ArrangementLoopRegionTheme.color.withValues(alpha: 0.28)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : PianoRollTheme.labelMuted,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            icon,
            size: 20,
            color: destructive ? PianoRollTheme.saveError : Colors.white70,
          ),
        ),
      ),
    );
  }
}
