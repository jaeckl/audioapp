import 'package:flutter/material.dart';

import 'piano_roll_metrics.dart';
import 'piano_roll_theme.dart';

class PianoRollToolDock extends StatelessWidget {
  const PianoRollToolDock({
    super.key,
    required this.tool,
    required this.gridLabel,
    required this.canUndo,
    required this.canRedo,
    required this.onToolChanged,
    required this.onGridTap,
    required this.onEditTap,
    required this.onUndo,
    required this.onRedo,
    required this.previewPlaying,
    required this.onPreviewPlayStop,
  });

  final PianoRollTool tool;
  final String gridLabel;
  final bool canUndo;
  final bool canRedo;
  final ValueChanged<PianoRollTool> onToolChanged;
  final VoidCallback onGridTap;
  final VoidCallback onEditTap;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final bool previewPlaying;
  final VoidCallback onPreviewPlayStop;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: PianoRollTheme.dockBackground,
      child: SizedBox(
        height: PianoRollMetrics.toolDockHeight,
        child: Row(
            children: [
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
              ),
              _DockButton(
                icon: Icons.grid_on_outlined,
                activeIcon: Icons.grid_on,
                label: gridLabel,
                active: false,
                onTap: onGridTap,
              ),
              _DockButton(
                icon: Icons.tune_outlined,
                activeIcon: Icons.tune,
                label: 'Edit',
                active: false,
                onTap: onEditTap,
              ),
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

class _DockButton extends StatelessWidget {
  const _DockButton({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
    this.enabled = true,
    this.showLabel = false,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final bool enabled;
  final bool showLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? PianoRollTheme.dockActive : Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: showLabel ? 72 : 52,
          height: PianoRollMetrics.toolDockHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                active ? activeIcon : icon,
                size: 22,
                color: enabled
                    ? (active ? PianoRollTheme.dockIconActive : PianoRollTheme.dockIcon)
                    : PianoRollTheme.labelMuted,
              ),
              if (showLabel) ...[
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: enabled ? PianoRollTheme.dockIcon : PianoRollTheme.labelMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
