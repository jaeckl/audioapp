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
    return Container(
      height: DeviceStripTheme.headerHeight,
      decoration: const BoxDecoration(
        color: DeviceStripTheme.cardHeader,
        border: Border(
          bottom: BorderSide(color: Color(0xFF050508), width: 1.5),
        ),
      ),
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
    );
  }
}
