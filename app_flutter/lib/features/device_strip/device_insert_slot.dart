import 'package:flutter/material.dart';

import 'device_strip_metrics.dart';

/// Centered plus control to insert a device after a chain slot.
class DeviceInsertSlot extends StatelessWidget {
  const DeviceInsertSlot({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final size = DeviceStripMetrics.insertButtonSize;
    return Semantics(
      button: true,
      label: 'Add device',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF25252E),
              border: Border.all(color: Colors.white24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.add, size: 18, color: Colors.white70),
          ),
        ),
      ),
    );
  }
}
