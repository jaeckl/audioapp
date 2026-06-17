import 'package:flutter/material.dart';

import 'play_deck_theme.dart';

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
          ],
        ),
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? PlayDeckTheme.railActive
        : enabled
            ? PlayDeckTheme.railInactive
            : PlayDeckTheme.railLabel;
    return Material(
      color: active ? const Color(0xFF2A2A30) : Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: SizedBox(
          height: 56,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
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
