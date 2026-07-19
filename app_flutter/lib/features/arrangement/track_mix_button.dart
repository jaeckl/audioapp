import 'package:flutter/material.dart';

import 'arrangement_theme.dart';

/// Mix control chip for track headers (record / solo / mute / freeze).
class TrackMixButton extends StatelessWidget {
  const TrackMixButton({
    super.key,
    required this.active,
    required this.onTap,
    required this.color,
    this.label,
    this.icon,
    this.height = 32,
    this.tooltip,
  }) : assert(label != null || icon != null);

  final String? label;
  final IconData? icon;
  final bool active;
  final VoidCallback onTap;
  final Color color;
  final double height;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final fg = active ? Colors.black : ArrangementTheme.textPrimary;
    final button = Material(
      color: active ? color : ArrangementTheme.mixButtonIdle,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Center(
            child: icon != null
                ? Icon(icon, size: height * 0.55, color: fg)
                : Text(
                    label!,
                    style: TextStyle(
                      fontSize: height * 0.38,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
          ),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}
