import 'package:flutter/material.dart';

part 'drum_model_tab_bar_tab_cell.dart';

/// Flat bottom tab row for drum model selection (808 / 909 / …).
class DrumModelTabBar extends StatelessWidget {
  const DrumModelTabBar({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.accent,
    required this.isEnabled,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final Color accent;
  final bool Function(int index) isEnabled;
  final ValueChanged<int> onSelected;

  static const double barHeight = 22;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF12121A),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          left: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          right: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
      ),
      child: SizedBox(
        height: barHeight,
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              Expanded(
                child: _TabCell(
                  label: labels[i],
                  selected: i == selectedIndex,
                  enabled: isEnabled(i),
                  accent: accent,
                  theme: theme,
                  showLeftDivider: i > 0,
                  onTap: isEnabled(i) ? () => onSelected(i) : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
