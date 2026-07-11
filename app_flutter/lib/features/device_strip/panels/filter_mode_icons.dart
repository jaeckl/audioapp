import 'dart:math' as math;

import 'package:flutter/material.dart';

part 'filter_mode_icons_filter_mode_icon_button.dart';
part 'filter_mode_icons_filter_curve_icon_painter.dart';
part 'filter_mode_icons_filter_mode_icon_grid.dart';

part 'filter_mode_icons_filter_fx_mode_norm.dart';
/// Standard biquad filter modes drawn as magnitude-curve icons.
enum FilterCurveMode {
  lowPass,
  highPass,
  bandPass,
  notch,
}

/// Normalised mode values for the standalone Filter FX device.
/// Magnitude-curve icon painter shared by all filter mode selectors.
/// 2×2 grid of filter mode icons (LP/HP top, BP/Notch bottom).
