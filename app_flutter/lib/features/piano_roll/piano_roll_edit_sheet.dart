import 'package:flutter/material.dart';

import 'piano_roll_theme.dart';

class PianoRollEditSheet extends StatelessWidget {
  const PianoRollEditSheet({
    super.key,
    required this.hasSelection,
    required this.noteCount,
    required this.onQuantizeSelection,
    required this.onQuantizeAll,
    required this.onNudgeLeft,
    required this.onNudgeRight,
    required this.onNudgeUp,
    required this.onNudgeDown,
    required this.onDeleteSelected,
  });

  final bool hasSelection;
  final int noteCount;
  final VoidCallback onQuantizeSelection;
  final VoidCallback onQuantizeAll;
  final VoidCallback onNudgeLeft;
  final VoidCallback onNudgeRight;
  final VoidCallback onNudgeUp;
  final VoidCallback onNudgeDown;
  final VoidCallback onDeleteSelected;

  static Future<void> show(
    BuildContext context, {
    required bool hasSelection,
    required int noteCount,
    required VoidCallback onQuantizeSelection,
    required VoidCallback onQuantizeAll,
    required VoidCallback onNudgeLeft,
    required VoidCallback onNudgeRight,
    required VoidCallback onNudgeUp,
    required VoidCallback onNudgeDown,
    required VoidCallback onDeleteSelected,
    double bottomInset = 0,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: PianoRollTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: PianoRollEditSheet(
        hasSelection: hasSelection,
        noteCount: noteCount,
        onQuantizeSelection: () {
          onQuantizeSelection();
          Navigator.pop(context);
        },
        onQuantizeAll: () {
          onQuantizeAll();
          Navigator.pop(context);
        },
        onNudgeLeft: onNudgeLeft,
        onNudgeRight: onNudgeRight,
        onNudgeUp: onNudgeUp,
        onNudgeDown: onNudgeDown,
        onDeleteSelected: () {
          onDeleteSelected();
          Navigator.pop(context);
        },
        ),
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
            'Edit notes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          const _SectionTitle('Quantize'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  icon: Icons.graphic_eq,
                  label: 'Selection',
                  enabled: hasSelection,
                  onTap: onQuantizeSelection,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionTile(
                  icon: Icons.select_all,
                  label: 'All ($noteCount)',
                  enabled: noteCount > 0,
                  onTap: onQuantizeAll,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _SectionTitle('Nudge'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _NudgeButton(icon: Icons.keyboard_arrow_left, onTap: onNudgeLeft),
              const SizedBox(width: 8),
              Column(
                children: [
                  _NudgeButton(icon: Icons.keyboard_arrow_up, onTap: onNudgeUp),
                  const SizedBox(height: 8),
                  _NudgeButton(icon: Icons.keyboard_arrow_down, onTap: onNudgeDown),
                ],
              ),
              const SizedBox(width: 8),
              _NudgeButton(icon: Icons.keyboard_arrow_right, onTap: onNudgeRight),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Left / right: grid step · Up / down: semitone',
            textAlign: TextAlign.center,
            style: TextStyle(color: PianoRollTheme.labelMuted, fontSize: 11),
          ),
          const SizedBox(height: 16),
          _ActionTile(
            icon: Icons.delete_outline,
            label: 'Delete selected',
            enabled: hasSelection,
            destructive: true,
            onTap: onDeleteSelected,
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

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = !enabled
        ? PianoRollTheme.labelMuted
        : destructive
            ? PianoRollTheme.saveError
            : Colors.white;
    return Material(
      color: const Color(0xFF22222C),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NudgeButton extends StatelessWidget {
  const _NudgeButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF22222C),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
