import 'package:flutter/material.dart';

import 'piano_roll_theme.dart';

part 'piano_roll_edit_sheet_section_title.dart';
part 'piano_roll_edit_sheet_action_tile.dart';
part 'piano_roll_edit_sheet_nudge_button.dart';

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
                  _NudgeButton(
                      icon: Icons.keyboard_arrow_down, onTap: onNudgeDown),
                ],
              ),
              const SizedBox(width: 8),
              _NudgeButton(
                  icon: Icons.keyboard_arrow_right, onTap: onNudgeRight),
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
