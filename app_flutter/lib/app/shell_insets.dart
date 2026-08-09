import 'package:flutter/material.dart';

/// Shell padding for the transport header.
///
/// System bars are hidden (`SystemUiMode.immersiveSticky`). In portrait the
/// transport card + its controls sit flush at the physical top (cutout /
/// former status-bar strip).
class ShellInsets {
  const ShellInsets._();

  static EdgeInsets headerPadding(BuildContext context) {
    if (transportFlushesTop(context)) {
      return const EdgeInsets.fromLTRB(12, 0, 12, 1);
    }
    final top = MediaQuery.paddingOf(context).top;
    return EdgeInsets.fromLTRB(12, top + 3, 12, 3);
  }

  /// Portrait: pin transport to the physical top edge.
  static bool transportFlushesTop(BuildContext context) {
    return MediaQuery.orientationOf(context) == Orientation.portrait;
  }
}
