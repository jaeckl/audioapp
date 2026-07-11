import 'dart:math' as math;

import 'package:flutter/material.dart';

part 'filter_preview_filter_preview_mode.dart';
part 'filter_preview_biquad_coeffs.dart';
part 'filter_preview_shelf_kind.dart';
part 'filter_preview_filter_preview_painter.dart';

part 'filter_preview_biquad_response.dart';
/// Filter modes (mirrors the engine-side `FilterParams::filterMode`).
/// Biquad coefficient set — mirrors `audioapp::BiquadCoeffs`.
/// Reference sample rate for cooking biquads in the preview painter.
///
/// 48 kHz matches the engine offline render rate; the response is normalized
/// (relative to Nyquist) so the magnitude curve at any sampleRate ≈ the
/// magnitude at 48 kHz for musical frequencies.
const double _previewSampleRate = 48000.0;

_BiquadCoeffs _cookBiquad(int mode, double cutoffHz, double q) {
  final clampedCutoff = cutoffHz.clamp(20.0, _previewSampleRate * 0.45);
  final clampedQ = math.max(q, 0.1);
  final omega = 2.0 * math.pi * clampedCutoff / _previewSampleRate;
  final sinOmega = math.sin(omega);
  final cosOmega = math.cos(omega);
  final alpha = sinOmega / (2.0 * clampedQ);

  double b0 = 0, b1 = 0, b2 = 0;
  double a0 = 1, a1 = 0, a2 = 0;

  switch (mode) {
    case 1: // HP
      b0 = (1 + cosOmega) * 0.5;
      b1 = -(1 + cosOmega);
      b2 = (1 + cosOmega) * 0.5;
      a0 = 1 + alpha;
      a1 = -2 * cosOmega;
      a2 = 1 - alpha;
      break;
    case 2: // BP
      b0 = alpha;
      b1 = 0;
      b2 = -alpha;
      a0 = 1 + alpha;
      a1 = -2 * cosOmega;
      a2 = 1 - alpha;
      break;
    case 3: // notch
      b0 = 1;
      b1 = -2 * cosOmega;
      b2 = 1;
      a0 = 1 + alpha;
      a1 = -2 * cosOmega;
      a2 = 1 - alpha;
      break;
    case 0:
    default: // LP
      b0 = (1 - cosOmega) * 0.5;
      b1 = 1 - cosOmega;
      b2 = (1 - cosOmega) * 0.5;
      a0 = 1 + alpha;
      a1 = -2 * cosOmega;
      a2 = 1 - alpha;
      break;
  }

  return _BiquadCoeffs(b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0);
}

/// Biquad magnitude-response helpers shared by FilterPreview + FourBandEqPreview.
///
/// All helpers return **magnitude in dB** for a [frequencyHz] input.
/// Magnitude-response preview for the Filter device.
class FilterPreview extends StatelessWidget {
  const FilterPreview({
    super.key,
    required this.cutoffHz,
    required this.q,
    required this.mode,
    required this.accent,
  });

  final double cutoffHz;
  final double q;
  final FilterPreviewMode mode;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FilterPreviewPainter(
        cutoffHz: cutoffHz,
        q: q,
        mode: mode,
        accent: accent,
      ),
      child: const SizedBox.expand(),
    );
  }
}
