import 'package:flutter/material.dart';

part 'daw_shell_nav_daw_shell_nav_edge.dart';
part 'daw_shell_nav_daw_shell_nav_geometry.dart';

/// Where the shell nav bar sits relative to the device (physical bottom edge in portrait).
/// Layout for the nav bar: fixed 64dp strip on the device's portrait-bottom edge.
/// Shell navigation pinned to the device's portrait-bottom edge; icons rotate with the screen.
class DawShellNav extends StatelessWidget {
  const DawShellNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.geometry,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final DawShellNavGeometry geometry;

  static const Color _backgroundColor = Color(0xFF121218);
  static const Color _indicatorColor = Color(0xFF2D2D3A);
  static const Color _selectedColor = Color(0xFFE8E8F0);
  static const Color _unselectedColor = Color(0xFF8A8A9A);

  static const _destinations =
      <({IconData icon, IconData selectedIcon, String label})>[
    (icon: Icons.tune_outlined, selectedIcon: Icons.tune, label: 'Devices'),
    (icon: Icons.piano_outlined, selectedIcon: Icons.piano, label: 'Keys'),
    (
      icon: Icons.graphic_eq_outlined,
      selectedIcon: Icons.graphic_eq,
      label: 'Mixer'
    ),
    (
      icon: Icons.library_music_outlined,
      selectedIcon: Icons.library_music,
      label: 'Library'
    ),
    (
      icon: Icons.folder_open_outlined,
      selectedIcon: Icons.folder_open,
      label: 'Project'
    ),
  ];

  bool get _isVertical =>
      geometry.edge == DawShellNavEdge.left ||
      geometry.edge == DawShellNavEdge.right;

  @override
  Widget build(BuildContext context) {
    final items =
        List<Widget>.generate(_destinations.length, _buildDestination);

    return Material(
      color: _backgroundColor,
      child: _isVertical
          ? Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: items,
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: items,
            ),
    );
  }

  Widget _buildDestination(int index) {
    final destination = _destinations[index];
    final selected = index == selectedIndex;
    final icon = Icon(
      selected ? destination.selectedIcon : destination.icon,
      color: selected ? _selectedColor : _unselectedColor,
    );

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: InkWell(
        onTap: () => onDestinationSelected(index),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: selected
              ? BoxDecoration(
                  color: _indicatorColor,
                  borderRadius: BorderRadius.circular(16),
                )
              : null,
          child: geometry.iconQuarterTurns == 0
              ? icon
              : RotatedBox(
                  quarterTurns: geometry.iconQuarterTurns, child: icon),
        ),
      ),
    );
  }
}

int _effectiveRotation(BuildContext context) {
  final orientation = MediaQuery.orientationOf(context);

  if (orientation == Orientation.portrait) {
    // Portrait always uses the logical bottom bar.
    return 0;
  }

  // Landscape: pin the shell nav to the right edge.
  return 3;
}
