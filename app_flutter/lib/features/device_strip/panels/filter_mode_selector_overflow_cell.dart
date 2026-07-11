part of 'filter_mode_selector.dart';

class _OverflowCell extends StatelessWidget {
  const _OverflowCell({
    required this.accent,
    required this.active,
    required this.label,
    required this.options,
    required this.onSelected,
  });

  final Color accent;
  final bool active;
  final String label;
  final List<FilterModeOverflowOption> options;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: active ? accent.withValues(alpha: 0.18) : Colors.transparent,
        child: PopupMenuButton<int>(
          padding: EdgeInsets.zero,
          tooltip: 'More filter modes',
          onSelected: onSelected,
          itemBuilder: (context) => [
            for (final option in options)
              PopupMenuItem<int>(
                value: option.index,
                height: 32,
                child: Text(
                  option.label,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
          ],
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: active ? accent : Colors.white.withValues(alpha: 0.45),
                fontSize: 9,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
