import 'package:flutter/material.dart';

import 'device_strip_metrics.dart';
import 'device_strip_theme.dart';

/// Vertical tool buttons attached to the left of an expanded device card.
class DeviceToolRail extends StatelessWidget {
  const DeviceToolRail({
    super.key,
    required this.deviceName,
    required this.accentColor,
    required this.bypassed,
    required this.showLibrary,
    required     this.onBypassToggle,
    this.onDelete,
    this.libraryTooltip = 'Open sample library',
    this.onLibrary,
    this.modActive = false,
    this.onModToggle,
  });

  final String deviceName;
  final Color accentColor;
  final bool bypassed;
  final bool showLibrary;
  final VoidCallback onBypassToggle;
  final VoidCallback? onDelete;
  final String libraryTooltip;
  final VoidCallback? onLibrary;
  final bool modActive;
  final VoidCallback? onModToggle;

  @override
  Widget build(BuildContext context) {
    const borderSide = BorderSide(
      color: DeviceStripTheme.cardBorder,
      width: DeviceStripTheme.cardBorderWidth,
    );
    final leftRadius = const Radius.circular(DeviceStripTheme.toolRailRadius);

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
        child: Stack(
          alignment: Alignment.center,
          children: [
            RotatedBox(
              quarterTurns: 3,
              child: Text(
                deviceName.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  height: 1,
                ),
              ),
            ),
            Positioned(
              top: 4,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ToolRailButton(
                    icon: Icons.power_settings_new,
                    tooltip: bypassed ? 'Enable device' : 'Bypass device',
                    active: !bypassed,
                    onPressed: onBypassToggle,
                  ),
                  if (showLibrary)
                    _ToolRailButton(
                      icon: Icons.library_music_outlined,
                      tooltip: libraryTooltip,
                      enabled: onLibrary != null,
                      onPressed: onLibrary,
                    ),
                ],
              ),
            ),
            Positioned(
              bottom: 4,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ModButton(
                    active: modActive,
                    onPressed: onModToggle,
                  ),
                  if (onDelete != null)
                    _ToolRailButton(
                      icon: Icons.delete_outline,
                      tooltip: 'Delete device',
                      active: false,
                      onPressed: onDelete,
                    ),
                ],
              ),
            ),
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
      constraints: const BoxConstraints(minWidth: 28, minHeight: 24),
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 18, color: color),
    );
  }
}

class _ModButton extends StatelessWidget {
  const _ModButton({
    required this.active,
    required this.onPressed,
  });

  final bool active;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Modulation',
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 24),
      onPressed: onPressed,
      icon: Text(
        'Mod',
        style: TextStyle(
          color: active ? const Color(0xFFE8A54B) : Colors.white54,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
