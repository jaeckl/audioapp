import 'package:flutter/material.dart';

import 'device_strip_metrics.dart';

/// Centered plus control to insert a device after a chain slot.
class DeviceInsertSlot extends StatelessWidget {
  const DeviceInsertSlot({
    super.key,
    this.onPressed,
    this.accentColor,
  });

  final VoidCallback? onPressed;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final size = DeviceStripMetrics.insertButtonSize;
    final enabled = onPressed != null;
    final button = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accentColor?.withValues(alpha: 0.22) ?? const Color(0xFF25252E),
        border: Border.all(color: accentColor ?? Colors.white24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        Icons.add,
        size: 18,
        color: enabled ? (accentColor ?? Colors.white70) : Colors.white30,
      ),
    );

    return Semantics(
      button: enabled,
      enabled: enabled,
      label: enabled ? 'Add device' : 'Unfreeze track to add devices',
      child: Material(
        color: Colors.transparent,
        child: enabled
            ? InkWell(
                onTap: onPressed,
                customBorder: const CircleBorder(),
                child: button,
              )
            : Opacity(opacity: 0.45, child: button),
      ),
    );
  }
}
