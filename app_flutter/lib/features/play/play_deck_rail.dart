import 'package:flutter/material.dart';

import 'play_deck_theme.dart';

part 'play_deck_rail_rail_button.dart';

/// Rail with Pads/Keys · Octave · Perform · Perf.
/// [Axis.vertical] = side column; [Axis.horizontal] = tool-dock strip.
class PlayDeckRail extends StatelessWidget {
  const PlayDeckRail({
    super.key,
    required this.surfaceMode,
    required this.activeView,
    required this.octaveDisplay,
    required this.enabled,
    required this.onSurfaceModeChanged,
    required this.onViewChanged,
    this.axis = Axis.vertical,
  });

  final PlaySurfaceMode surfaceMode;
  final PlayContextView activeView;
  final int octaveDisplay;
  final bool enabled;
  final ValueChanged<PlaySurfaceMode> onSurfaceModeChanged;
  final ValueChanged<PlayContextView> onViewChanged;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[
      _RailButton(
        icon: surfaceMode == PlaySurfaceMode.pads
            ? Icons.grid_view_rounded
            : Icons.view_column_rounded,
        label: surfaceMode == PlaySurfaceMode.pads ? 'Pads' : 'Keys',
        active: activeView == PlayContextView.perform,
        enabled: enabled,
        compact: axis == Axis.horizontal,
        onTap: () {
          onSurfaceModeChanged(
            surfaceMode == PlaySurfaceMode.pads
                ? PlaySurfaceMode.keys
                : PlaySurfaceMode.pads,
          );
          onViewChanged(PlayContextView.perform);
        },
      ),
      _RailButton(
        icon: Icons.swap_vert,
        label: 'Oct $octaveDisplay',
        active: activeView == PlayContextView.octave,
        enabled: enabled,
        compact: axis == Axis.horizontal,
        onTap: () => onViewChanged(
          activeView == PlayContextView.octave
              ? PlayContextView.perform
              : PlayContextView.octave,
        ),
      ),
      _RailButton(
        icon: Icons.auto_awesome,
        label: 'Perform',
        active: activeView == PlayContextView.performPanel,
        enabled: enabled,
        compact: axis == Axis.horizontal,
        onTap: () => onViewChanged(
          activeView == PlayContextView.performPanel
              ? PlayContextView.perform
              : PlayContextView.performPanel,
        ),
      ),
      _RailButton(
        icon: Icons.tune,
        label: 'Perf',
        active: activeView == PlayContextView.performancePanel,
        enabled: enabled,
        compact: axis == Axis.horizontal,
        onTap: () => onViewChanged(
          activeView == PlayContextView.performancePanel
              ? PlayContextView.perform
              : PlayContextView.performancePanel,
        ),
      ),
    ];

    if (axis == Axis.horizontal) {
      return ColoredBox(
        color: PlayDeckTheme.railBackground,
        child: Row(mainAxisSize: MainAxisSize.min, children: buttons),
      );
    }

    return ColoredBox(
      color: PlayDeckTheme.railBackground,
      child: SizedBox(
        width: PlayDeckTheme.railWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            buttons[0],
            buttons[1],
            buttons[2],
            const Spacer(),
            buttons[3],
          ],
        ),
      ),
    );
  }
}
