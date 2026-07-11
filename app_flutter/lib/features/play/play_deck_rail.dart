import 'package:flutter/material.dart';

import 'play_deck_theme.dart';

part 'play_deck_rail_rail_button.dart';

/// Rail with three full-width buttons: Keyboard/Pads, Octave, Perform.
class PlayDeckRail extends StatelessWidget {
  const PlayDeckRail({
    super.key,
    required this.surfaceMode,
    required this.activeView,
    required this.octaveDisplay,
    required this.enabled,
    required this.onSurfaceModeChanged,
    required this.onViewChanged,
  });

  final PlaySurfaceMode surfaceMode;
  final PlayContextView activeView;
  final int octaveDisplay;
  final bool enabled;
  final ValueChanged<PlaySurfaceMode> onSurfaceModeChanged;
  final ValueChanged<PlayContextView> onViewChanged;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: PlayDeckTheme.railBackground,
      child: SizedBox(
        width: PlayDeckTheme.railWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _RailButton(
              icon: surfaceMode == PlaySurfaceMode.pads
                  ? Icons.grid_view_rounded
                  : Icons.view_column_rounded,
              label: surfaceMode == PlaySurfaceMode.pads ? 'Pads' : 'Keys',
              active: activeView == PlayContextView.perform,
              enabled: enabled,
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
              onTap: () => onViewChanged(
                activeView == PlayContextView.performPanel
                    ? PlayContextView.perform
                    : PlayContextView.performPanel,
              ),
            ),
            const Spacer(),
            _RailButton(
              icon: Icons.tune,
              label: 'Perf',
              active: activeView == PlayContextView.performancePanel,
              enabled: enabled,
              onTap: () => onViewChanged(
                activeView == PlayContextView.performancePanel
                    ? PlayContextView.perform
                    : PlayContextView.performancePanel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
