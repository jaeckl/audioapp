import 'package:flutter/material.dart';

import 'piano_roll_metrics.dart';
import 'piano_roll_theme.dart';

class PianoRollGridSheet extends StatelessWidget {
  const PianoRollGridSheet({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  final PianoRollGridSettings settings;
  final ValueChanged<PianoRollGridSettings> onChanged;

  static Future<void> show(
    BuildContext context, {
    required PianoRollGridSettings settings,
    required ValueChanged<PianoRollGridSettings> onChanged,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: PianoRollTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => PianoRollGridSheet(
        settings: settings,
        onChanged: (next) {
          onChanged(next);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Grid',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          const _SectionTitle('Snap'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final snap in PianoRollSnap.values)
                _Pill(
                  label: snap.shortLabel,
                  active: settings.snap == snap,
                  onTap: () => onChanged(settings.copyWith(snap: snap)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const _SectionTitle('Triplet'),
          const SizedBox(height: 8),
          Row(
            children: [
              _Pill(
                label: 'Off',
                active: !settings.triplet,
                onTap: () => onChanged(settings.copyWith(triplet: false)),
              ),
              const SizedBox(width: 6),
              _Pill(
                label: 'On',
                active: settings.triplet,
                onTap: () => onChanged(settings.copyWith(triplet: true)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _SectionTitle('Default note length'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _Pill(
                label: '1/4',
                active: settings.defaultNoteBeats == 0.25,
                onTap: () => onChanged(settings.copyWith(defaultNoteBeats: 0.25)),
              ),
              _Pill(
                label: '1/2',
                active: settings.defaultNoteBeats == 0.5,
                onTap: () => onChanged(settings.copyWith(defaultNoteBeats: 0.5)),
              ),
              _Pill(
                label: '1 bar',
                active: settings.defaultNoteBeats == 4.0,
                onTap: () => onChanged(settings.copyWith(defaultNoteBeats: 4.0)),
              ),
              _Pill(
                label: '2 bars',
                active: settings.defaultNoteBeats == 8.0,
                onTap: () => onChanged(settings.copyWith(defaultNoteBeats: 8.0)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: PianoRollTheme.label,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
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
      color: active ? const Color(0xFF3A3A50) : const Color(0xFF22222C),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : PianoRollTheme.labelMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
