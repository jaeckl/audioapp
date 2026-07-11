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
