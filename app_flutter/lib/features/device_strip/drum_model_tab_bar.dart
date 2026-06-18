import 'package:flutter/material.dart';

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

class _TabCell extends StatelessWidget {
  const _TabCell({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.accent,
    required this.theme,
    required this.showLeftDivider,
    this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final Color accent;
  final ThemeData theme;
  final bool showLeftDivider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected
        ? accent
        : enabled
            ? Colors.white60
            : Colors.white.withValues(alpha: 0.28);

    return Material(
      color: selected ? accent.withValues(alpha: 0.12) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              left: showLeftDivider
                  ? BorderSide(color: Colors.white.withValues(alpha: 0.08))
                  : BorderSide.none,
              bottom: selected
                  ? BorderSide(color: accent, width: 2)
                  : BorderSide.none,
            ),
          ),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: fg,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 9,
                letterSpacing: 0.35,
                height: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
