import 'package:flutter/material.dart';

import 'device_strip_theme.dart';

/// Visible card container for one device in the horizontal chain.
class DeviceStripCard extends StatelessWidget {
  const DeviceStripCard({
    super.key,
    required this.deviceType,
    required this.bodyHeight,
    required this.child,
    this.subtitle,
  });

  final String deviceType;
  final double bodyHeight;
  final Widget child;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = DeviceStripTheme.accentForDeviceType(deviceType);
    final label = DeviceStripTheme.labelForDeviceType(deviceType);
    final radius = Radius.circular(DeviceStripTheme.cardRadius);

    const borderSide = BorderSide(
      color: DeviceStripTheme.cardBorder,
      width: DeviceStripTheme.cardBorderWidth,
    );

    final cardRadius = BorderRadius.only(topLeft: radius, topRight: radius);

    return Container(
      decoration: BoxDecoration(
        color: DeviceStripTheme.cardBackground,
        borderRadius: cardRadius,
        border: const Border(
          top: borderSide,
          left: borderSide,
          bottom: borderSide,
        ),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: cardRadius,
        border: const Border(right: borderSide),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColoredBox(
            color: accent,
            child: const SizedBox(width: DeviceStripTheme.accentStripeWidth),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: DeviceStripTheme.headerHeight,
                  color: DeviceStripTheme.cardHeader,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Text(
                        label.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          fontSize: 10,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white38,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
                SizedBox(
                  height: bodyHeight,
                  child: child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
