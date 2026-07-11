part of 'device_strip_card.dart';

class _ContainerTabHeader extends StatelessWidget {
  const _ContainerTabHeader({
    required this.tabs,
    required this.selectedTabIndex,
    required this.accent,
    required this.onTabSelected,
    this.actions,
  });

  final List<DeviceTabSpec> tabs;
  final int selectedTabIndex;
  final Color accent;
  final ValueChanged<int>? onTabSelected;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DeviceStripTheme.headerHeight,
      child: ColoredBox(
        color: DeviceStripTheme.cardHeader,
        child: Row(
          children: [
            if (tabs.isNotEmpty)
              Expanded(
                child: DeviceHeaderTabBar(
                  tabs: tabs,
                  selectedIndex: selectedTabIndex,
                  accentColor: accent,
                  compact: actions != null,
                  onSelected: onTabSelected ?? (_) {},
                ),
              ),
            if (actions != null)
              if (tabs.isEmpty) Expanded(child: actions!) else actions!,
          ],
        ),
      ),
    );
  }
}
