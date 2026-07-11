import 'dart:math' as math;

import 'package:flutter/material.dart';

part 'filter_mode_icons_filter_mode_icon_button.dart';
part 'filter_mode_icons_filter_curve_icon_painter.dart';
part 'filter_mode_icons_filter_mode_icon_grid.dart';

/// Standard biquad filter modes drawn as magnitude-curve icons.
enum FilterCurveMode {
  lowPass,
  highPass,
  bandPass,
  notch,
}

/// Normalised mode values for the standalone Filter FX device.
abstract final class FilterFxModeNorm {
  static const values = <double>[0.125, 0.375, 0.625, 0.875];
}

/// Magnitude-curve icon painter shared by all filter mode selectors.
/// 2×2 grid of filter mode icons (LP/HP top, BP/Notch bottom).
