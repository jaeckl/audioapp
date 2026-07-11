part of 'device_header_tab_bar.dart';

class _DeviceHeaderTab extends StatelessWidget {
  const _DeviceHeaderTab({
    required this.tab,
    required this.selected,
    required this.accentColor,
    required this.onTap,
    required this.compact,
  });

  final DeviceTabSpec tab;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;
  final bool compact;

  static const _topRadius = Radius.circular(8);

  @override
  Widget build(BuildContext context) {
    final labelColor = selected ? Colors.white : Colors.white54;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.only(
          topLeft: _topRadius,
          topRight: _topRadius,
        ),
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 12),
          decoration: BoxDecoration(
            color: selected
                ? Colors.black.withValues(alpha: 0.38)
                : Colors.transparent,
            borderRadius: const BorderRadius.only(
              topLeft: _topRadius,
              topRight: _topRadius,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                tab.icon,
                size: 15,
                color: selected ? accentColor : labelColor,
              ),
              SizedBox(width: compact ? 4 : 5),
              Text(
                tab.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.35,
                  color: labelColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
