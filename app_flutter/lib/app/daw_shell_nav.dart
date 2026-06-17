import 'package:flutter/material.dart';

/// Where the shell nav bar sits relative to the device (physical bottom edge in portrait).
enum DawShellNavEdge { bottom, left, right, top }

/// Layout for the nav bar: fixed 64dp strip on the device's portrait-bottom edge.
class DawShellNavGeometry {
  const DawShellNavGeometry({
    required this.edge,
    required this.contentPadding,
    required this.iconQuarterTurns,
  });

  final DawShellNavEdge edge;
  final EdgeInsets contentPadding;
  final int iconQuarterTurns;

  static const double thickness = 64;

  static DawShellNavGeometry of(BuildContext context) {
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final rotation = _effectiveRotation(context);

    switch (rotation) {
      case 1:
        return DawShellNavGeometry(
          edge: DawShellNavEdge.left,
          iconQuarterTurns: 1,
          contentPadding: EdgeInsets.only(left: thickness + viewPadding.left),
        );
      case 3:
        return DawShellNavGeometry(
          edge: DawShellNavEdge.right,
          iconQuarterTurns: 3,
          contentPadding: EdgeInsets.only(right: thickness + viewPadding.right),
        );
      case 2:
        return DawShellNavGeometry(
          edge: DawShellNavEdge.top,
          iconQuarterTurns: 2,
          contentPadding: EdgeInsets.only(top: thickness + viewPadding.top),
        );
      case 0:
      default:
        return DawShellNavGeometry(
          edge: DawShellNavEdge.bottom,
          iconQuarterTurns: 0,
          contentPadding: EdgeInsets.only(bottom: thickness + viewPadding.bottom),
        );
    }
  }

  Widget position({required BuildContext context, required Widget child}) {
    final viewPadding = MediaQuery.viewPaddingOf(context);

    switch (edge) {
      case DawShellNavEdge.left:
        return Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          width: thickness + viewPadding.left,
          child: Padding(
            padding: EdgeInsets.only(left: viewPadding.left),
            child: child,
          ),
        );
      case DawShellNavEdge.right:
        return Positioned(
          top: 0,
          bottom: 0,
          right: 0,
          width: thickness + viewPadding.right,
          child: Padding(
            padding: EdgeInsets.only(right: viewPadding.right),
            child: child,
          ),
        );
      case DawShellNavEdge.top:
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: thickness + viewPadding.top,
          child: Padding(
            padding: EdgeInsets.only(top: viewPadding.top),
            child: child,
          ),
        );
      case DawShellNavEdge.bottom:
        return Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: thickness + viewPadding.bottom,
          child: Padding(
            padding: EdgeInsets.only(bottom: viewPadding.bottom),
            child: child,
          ),
        );
    }
  }
}

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

  static const _destinations = <({IconData icon, IconData selectedIcon, String label})>[
    (icon: Icons.grid_view_outlined, selectedIcon: Icons.grid_view, label: 'Arrangement'),
    (icon: Icons.piano_outlined, selectedIcon: Icons.piano, label: 'Play'),
    (icon: Icons.tune_outlined, selectedIcon: Icons.tune, label: 'Mixer'),
    (icon: Icons.library_music_outlined, selectedIcon: Icons.library_music, label: 'Library'),
    (icon: Icons.folder_open_outlined, selectedIcon: Icons.folder_open, label: 'Project'),
  ];

  bool get _isVertical =>
      geometry.edge == DawShellNavEdge.left || geometry.edge == DawShellNavEdge.right;

  @override
  Widget build(BuildContext context) {
    final items = List<Widget>.generate(_destinations.length, _buildDestination);

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
              : RotatedBox(quarterTurns: geometry.iconQuarterTurns, child: icon),
        ),
      ),
    );
  }
}

int _effectiveRotation(BuildContext context) {
  final orientation = MediaQuery.orientationOf(context);
  final viewPadding = MediaQuery.viewPaddingOf(context);

  if (orientation == Orientation.portrait) {
    // Portrait always uses the logical bottom bar. Do not infer rotation from
    // viewPadding — status bar/notch makes top larger than bottom on most devices.
    return 0;
  }

  // In landscape the portrait-bottom home/gesture inset moves to left or right.
  if (viewPadding.left > viewPadding.right + 4) {
    return 1;
  }
  if (viewPadding.right > viewPadding.left + 4) {
    return 3;
  }
  // Tests and devices without side insets: default to bottom → left (clockwise).
  return 1;
}
