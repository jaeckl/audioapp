import 'package:flutter/material.dart';

import 'midi_comp_tool.dart';
import 'piano_roll_metrics.dart';
import 'piano_roll_theme.dart';

part 'midi_comp_tool_dock_dock_button.dart';

/// Bottom tool dock for MIDI comp mode — two editing modes + preview.
class MidiCompToolDock extends StatelessWidget {
  const MidiCompToolDock({
    super.key,
    required this.tool,
    required this.previewPlaying,
    required this.onToolChanged,
    required this.onPreviewPlayStop,
    this.compFlattened = false,
    this.onFlatten,
    this.onReopen,
  });

  final MidiCompTool tool;
  final bool previewPlaying;
  final ValueChanged<MidiCompTool> onToolChanged;
  final VoidCallback onPreviewPlayStop;
  final bool compFlattened;
  final VoidCallback? onFlatten;
  final VoidCallback? onReopen;

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
              if (!compFlattened && onFlatten != null)
                _DockButton(
                  icon: Icons.layers_clear_outlined,
                  activeIcon: Icons.layers_clear,
                  label: 'FLAT',
                  tooltip: 'Flatten comp into editable notes',
                  active: false,
                  compact: true,
                  onTap: onFlatten!,
                ),
              if (compFlattened && onReopen != null)
                _DockButton(
                  icon: Icons.lock_open_outlined,
                  activeIcon: Icons.lock_open,
                  label: 'OPEN',
                  tooltip: 'Re-open comp takes and markers',
                  active: false,
                  compact: true,
                  onTap: onReopen!,
                ),
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
