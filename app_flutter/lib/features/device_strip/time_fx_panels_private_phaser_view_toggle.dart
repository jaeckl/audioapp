part of 'time_fx_panels.dart';

/// Compact MOTION / RESPONSE toggle — top-right of the hero screen.
class _PhaserViewToggle extends StatelessWidget {
  const _PhaserViewToggle({
    required this.view,
    required this.onChanged,
    required this.accent,
  });

  final PhaserViewTab view;
  final ValueChanged<PhaserViewTab> onChanged;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _cell(
              keyName: 'phaser-view-motion',
              icon: Icons.waves,
              selected: view == PhaserViewTab.motion,
              onTap: () => onChanged(PhaserViewTab.motion),
            ),
            _cell(
              keyName: 'phaser-view-response',
              icon: Icons.multiline_chart,
              selected: view == PhaserViewTab.response,
              onTap: () => onChanged(PhaserViewTab.response),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell({
    required String keyName,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: ValueKey(keyName),
      onTap: onTap,
      child: SizedBox(
        width: 28,
        height: 26,
        child: Icon(
          icon,
          size: 14,
          color: selected ? accent : Colors.white.withValues(alpha: 0.40),
        ),
      ),
    );
  }
}
