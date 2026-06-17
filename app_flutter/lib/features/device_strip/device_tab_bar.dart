import 'package:flutter/material.dart';

/// Segmented tabs for a device panel — one functional group per tab (Note / FLM pattern).
class DeviceTabBar extends StatelessWidget {
  const DeviceTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
    this.accentColor = const Color(0xFFE8A54B),
  });

  final List<DeviceTabSpec> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Row(
        children: List.generate(tabs.length, (index) {
          final tab = tabs[index];
          final selected = index == selectedIndex;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index < tabs.length - 1 ? 4 : 0),
              child: Material(
                color: selected
                    ? accentColor.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                  onTap: () => onSelected(index),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: selected
                            ? accentColor.withValues(alpha: 0.65)
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tab.icon,
                          size: 14,
                          color: selected ? accentColor : Colors.white38,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: selected ? accentColor : Colors.white38,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class DeviceTabSpec {
  const DeviceTabSpec({required this.label, required this.icon});

  final String label;
  final IconData icon;
}
