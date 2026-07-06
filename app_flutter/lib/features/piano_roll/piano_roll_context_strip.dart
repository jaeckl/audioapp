import 'package:flutter/material.dart';

import 'piano_roll_theme.dart';

/// Secondary chrome row below the MIDI editor app bar: mode segment + context chips.
class PianoRollContextStrip extends StatelessWidget {
  const PianoRollContextStrip({
    super.key,
    required this.showCompSegment,
    required this.notesMode,
    required this.onModeChanged,
    required this.snapLabel,
    this.scaleLabel,
    required this.onViewTap,
    this.modeChip,
  });

  static const height = 44.0;

  final bool showCompSegment;
  final bool notesMode;
  final ValueChanged<bool> onModeChanged;
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
              if (showCompSegment) ...[
                _ModeSegment(
                  notesMode: notesMode,
                  onChanged: onModeChanged,
                ),
                const SizedBox(width: 8),
              ],
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

class _ModeSegment extends StatelessWidget {
  const _ModeSegment({
    required this.notesMode,
    required this.onChanged,
  });

  final bool notesMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: PianoRollTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3B3B49)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SegmentTab(
            label: 'Notes',
            active: notesMode,
            onTap: () => onChanged(true),
          ),
          _SegmentTab(
            label: 'Comp',
            active: !notesMode,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  const _SegmentTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? PianoRollTheme.dockActive : Colors.transparent,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : PianoRollTheme.labelMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

class _ContextChip extends StatelessWidget {
  const _ContextChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: PianoRollTheme.background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF3B3B49)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: PianoRollTheme.label,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isEdit = label == 'EDIT';
    final color = isEdit ? PianoRollTheme.saveOk : const Color(0xFFFF6D8A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
