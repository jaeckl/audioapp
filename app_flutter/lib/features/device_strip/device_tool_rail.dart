import 'package:flutter/material.dart';

import 'device_strip_metrics.dart';
import 'device_strip_theme.dart';

/// Vertical tool buttons attached to the left of an expanded device card.
class DeviceToolRail extends StatelessWidget {
  const DeviceToolRail({
    super.key,
    required this.bypassed,
    required this.showLibrary,
    required this.onBypassToggle,
    this.onLibrary,
  });

  final bool bypassed;
  final bool showLibrary;
  final VoidCallback onBypassToggle;
  final VoidCallback? onLibrary;

  @override
  Widget build(BuildContext context) {
    const borderSide = BorderSide(
      color: DeviceStripTheme.cardBorder,
      width: DeviceStripTheme.cardBorderWidth,
    );
    final leftRadius = Radius.circular(DeviceStripTheme.toolRailRadius);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: DeviceStripTheme.toolRailBackground,
        borderRadius: BorderRadius.only(topLeft: leftRadius, bottomLeft: leftRadius),
        border: const Border(
          top: borderSide,
          left: borderSide,
          bottom: borderSide,
        ),
      ),
      child: SizedBox(
        width: DeviceStripMetrics.toolRailWidth,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ToolRailButton(
              icon: Icons.power_settings_new,
              tooltip: bypassed ? 'Enable device' : 'Bypass device',
              active: !bypassed,
              onPressed: onBypassToggle,
            ),
            if (showLibrary) ...[
              const SizedBox(height: 10),
              _ToolRailButton(
                icon: Icons.library_music_outlined,
                tooltip: 'Open sample library',
                enabled: onLibrary != null,
                onPressed: onLibrary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ToolRailButton extends StatelessWidget {
  const _ToolRailButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.active = true,
    this.enabled = true,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool active;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = !enabled
        ? Colors.white24
        : active
            ? Colors.white70
            : const Color(0xFFE86A6A);

    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 18, color: color),
    );
  }
}
