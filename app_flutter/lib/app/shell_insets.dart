import 'package:flutter/material.dart';

/// Edge-to-edge shell padding for the status header only.
///
/// Horizontal insets are omitted so arrangement/device strip fill cutout areas.
/// Transport extends into the bottom gesture area (see TransportBar).
class ShellInsets {
  const ShellInsets._();

  static EdgeInsets headerPadding(BuildContext context) {
    final top = MediaQuery.viewPaddingOf(context).top;
    return EdgeInsets.fromLTRB(12, top + 3, 12, 3);
  }
}
