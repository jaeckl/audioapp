import 'package:flutter/material.dart';

import 'midi_comp_tool.dart';
import 'piano_roll_metrics.dart';
import 'piano_roll_theme.dart';

/// Bottom tool dock for MIDI comp mode — two editing modes + preview.
class MidiCompToolDock extends StatelessWidget {
  const MidiCompToolDock({
    super.key,
    required this.tool,
    required this.previewPlaying,
    required this.onToolChanged,
    required this.onPreviewPlayStop,
  });

  final MidiCompTool tool;
  final bool previewPlaying;
  final ValueChanged<MidiCompTool> onToolChanged;
  final VoidCallback onPreviewPlayStop;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: PianoRollTheme.dockBackground,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: PianoRollMetrics.toolDockHeight,
          child: Row(
            children: [
              _DockButton(
                icon: Icons.layers_outlined,
                activeIcon: Icons.layers,
                label: 'COMP',
                tooltip: 'Drag markers and tap lanes to assign takes',
                active: tool == MidiCompTool.comp,
                onTap: () => onToolChanged(MidiCompTool.comp),
              ),
              _DockButton(
                icon: Icons.call_split,
                activeIcon: Icons.call_split,
                label: 'SPLIT',
                tooltip: 'Insert markers and split at playhead',
                active: tool == MidiCompTool.markers,
                onTap: () => onToolChanged(MidiCompTool.markers),
              ),
              const Spacer(),
              _DockButton(
                icon: Icons.play_arrow,
                activeIcon: Icons.stop,
                tooltip: previewPlaying ? 'Stop preview' : 'Preview comp',
                active: previewPlaying,
                compact: true,
                onTap: onPreviewPlayStop,
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  const _DockButton({
    required this.icon,
    required this.activeIcon,
    required this.tooltip,
    required this.active,
    required this.onTap,
    this.label,
    this.compact = false,
  });

  final IconData icon;
  final IconData activeIcon;
  final String tooltip;
  final String? label;
  final bool active;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: active ? PianoRollTheme.dockActive : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: compact ? 44 : 56,
            height: PianoRollMetrics.toolDockHeight,
            child: label == null
                ? Icon(
                    active ? activeIcon : icon,
                    size: 22,
                    color: active
                        ? PianoRollTheme.dockIconActive
                        : PianoRollTheme.dockIcon,
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        active ? activeIcon : icon,
                        size: 18,
                        color: active
                            ? PianoRollTheme.dockIconActive
                            : PianoRollTheme.dockIcon,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label!,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: active
                              ? PianoRollTheme.dockIconActive
                              : PianoRollTheme.dockIcon,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
