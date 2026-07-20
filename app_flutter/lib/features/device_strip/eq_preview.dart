import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'filter_preview.dart';

part 'eq_preview_geometry.dart';
part 'eq_preview_four_band_eq_preview.dart';
part 'eq_preview_eq_preview_painter.dart';
part 'eq_preview_eager_pan.dart';

/// One band of the 4-band EQ preview.
class EqBand {
  const EqBand({
    required this.cutoffHz,
    required this.gainDb,
    required this.q,
    required this.isShelf,
  });

  final double cutoffHz;
  final double gainDb;
  final double q;

  /// True for shelf bands (1 and 4 — low/high shelf); false for peaking bands.
  final bool isShelf;
}

/// Cumulative magnitude-response preview for the 4-band EQ device.
///
/// Band nodes are interactive: drag X→freq, Y→gain (hit ≥28px).
