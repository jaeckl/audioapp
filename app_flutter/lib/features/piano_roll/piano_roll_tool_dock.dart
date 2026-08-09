import 'package:flutter/material.dart';

import 'piano_roll_metrics.dart';
import 'midi_lane_layout.dart';
import 'piano_roll_theme.dart';

part 'piano_roll_tool_dock_dock_button.dart';

class PianoRollToolDock extends StatelessWidget {
  const PianoRollToolDock({
    super.key,
    required this.tool,
    required this.canUndo,
    required this.canRedo,
    required this.onToolChanged,
    required this.onEditTap,
    required this.onUndo,
    required this.onRedo,
    required this.previewPlaying,
    required this.onPreviewPlayStop,
    required this.editorMode,
    required this.canUseDrumMode,
    required this.onEditorModeChanged,
    required this.onDrawSettings,
    this.hideNoteTools = false,
    this.leading,
  });

  final PianoRollTool tool;
  final bool canUndo;
  final bool canRedo;
  final ValueChanged<PianoRollTool> onToolChanged;
  final VoidCallback onEditTap;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final bool previewPlaying;
  final VoidCallback onPreviewPlayStop;
  final MidiEditorMode editorMode;
  final bool canUseDrumMode;
  final ValueChanged<MidiEditorMode> onEditorModeChanged;
  final VoidCallback onDrawSettings;

  /// When true (Harmonic / Progression), hide Select/Draw/Edit.
  final bool hideNoteTools;

  /// Optional leading strip (e.g. PlayDeck rail in landscape).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: PianoRollTheme.dockBackground,
      child: SizedBox(
        height: PianoRollMetrics.toolDockHeight,
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              Container(width: 1, color: PianoRollTheme.labelMuted.withValues(alpha: 0.25)),
            ],
            if (!hideNoteTools) ...[
              _DockButton(
                icon: Icons.pan_tool_alt_outlined,
                activeIcon: Icons.pan_tool_alt,
                label: 'Select',
                active: tool == PianoRollTool.select,
                onTap: () => onToolChanged(PianoRollTool.select),
              ),
              _DockButton(
                icon: Icons.edit_outlined,
                activeIcon: Icons.edit,
                label: 'Draw',
                active: tool == PianoRollTool.draw,
                onTap: () => onToolChanged(PianoRollTool.draw),
                onLongPress: onDrawSettings,
              ),
              _DockButton(
                icon: Icons.tune_outlined,
                activeIcon: Icons.tune,
                label: 'Edit',
                active: false,
                onTap: onEditTap,
                enabled: editorMode == MidiEditorMode.piano,
              ),
              if (canUseDrumMode)
                _DockButton(
                  icon: editorMode == MidiEditorMode.drums
                      ? Icons.piano
                      : Icons.grid_view_rounded,
                  activeIcon: Icons.grid_view_rounded,
                  label: editorMode == MidiEditorMode.drums ? 'Piano' : 'Drums',
                  active: editorMode == MidiEditorMode.drums,
                  onTap: () => onEditorModeChanged(
                    editorMode == MidiEditorMode.drums
                        ? MidiEditorMode.piano
                        : MidiEditorMode.drums,
                  ),
                ),
            ],
            const Spacer(),
            _DockButton(
              icon: Icons.play_arrow,
              activeIcon: Icons.stop,
              label: previewPlaying ? 'Stop' : 'Preview',
              active: previewPlaying,
              onTap: onPreviewPlayStop,
              showLabel: false,
            ),
            _DockButton(
              icon: Icons.undo,
              activeIcon: Icons.undo,
              label: 'Undo',
              active: false,
              enabled: canUndo,
              onTap: onUndo,
            ),
            _DockButton(
              icon: Icons.redo,
              activeIcon: Icons.redo,
              label: 'Redo',
              active: false,
              enabled: canRedo,
              onTap: onRedo,
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
