import 'package:flutter/material.dart';

/// Bottom tab bar that stays pinned to the bottom in landscape (icons rotate, labels hidden).
class DawBottomNavBar extends StatelessWidget {
  const DawBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  static const double _barHeight = 64;

  @override
  Widget build(BuildContext context) {
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final isLandscape = MediaQuery.orientationOf(context) == Orientation.landscape;

    final edgePadding = isLandscape
        ? EdgeInsets.only(left: viewPadding.left, right: viewPadding.right)
        : EdgeInsets.only(bottom: viewPadding.bottom);

    return Padding(
      padding: edgePadding,
      child: NavigationBar(
        backgroundColor: const Color(0xFF121218),
        indicatorColor: const Color(0xFF2D2D3A),
        selectedIndex: selectedIndex,
        height: _barHeight,
        labelBehavior: isLandscape
            ? NavigationDestinationLabelBehavior.alwaysHide
            : NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: onDestinationSelected,
        destinations: [
          _destination(
            isLandscape: isLandscape,
            icon: Icons.grid_view_outlined,
            selectedIcon: Icons.grid_view,
            label: 'Arrangement',
          ),
          _destination(
            isLandscape: isLandscape,
            icon: Icons.tune_outlined,
            selectedIcon: Icons.tune,
            label: 'Mixer',
          ),
          _destination(
            isLandscape: isLandscape,
            icon: Icons.library_music_outlined,
            selectedIcon: Icons.library_music,
            label: 'Library',
          ),
          _destination(
            isLandscape: isLandscape,
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings,
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  NavigationDestination _destination({
    required bool isLandscape,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    return NavigationDestination(
      icon: _orientedIcon(icon, isLandscape),
      selectedIcon: _orientedIcon(selectedIcon, isLandscape),
      label: label,
    );
  }

  Widget _orientedIcon(IconData icon, bool isLandscape) {
    final child = Icon(icon);
    if (!isLandscape) {
      return child;
    }
    return RotatedBox(quarterTurns: 1, child: child);
  }
}
