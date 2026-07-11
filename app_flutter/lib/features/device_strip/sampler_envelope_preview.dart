import 'package:flutter/material.dart';

part 'sampler_envelope_preview_sampler_envelope_painter.dart';

/// Maps UI-normalized ADSR (0..1) to seconds — matches engine `adsrNormalizedToSeconds`.
double samplerAdsrStageSec(double normalized, double maxSeconds) =>
    0.001 + normalized.clamp(0.0, 1.0) * maxSeconds;

/// Amp envelope gain at elapsed time (display-only mirror of engine ADSR).
double samplerAdsrDisplayGain(
  double elapsedSec,
  double noteDurationSec, {
  required double attackSec,
  required double decaySec,
  required double sustainLevel,
  required double releaseSec,
}) {
  if (elapsedSec < 0) return 0;
  final sustain = sustainLevel.clamp(0.0, 1.0);

  if (elapsedSec < attackSec) {
    return attackSec > 0 ? elapsedSec / attackSec : 1.0;
  }
  var t = elapsedSec - attackSec;

  if (t < decaySec) {
    return decaySec <= 0 ? sustain : 1.0 - (1.0 - sustain) * (t / decaySec);
  }
  t -= decaySec;

  if (t < noteDurationSec) return sustain;

  final releaseElapsed = t - noteDurationSec;
  if (releaseElapsed < releaseSec) {
    return releaseSec > 0 ? sustain * (1.0 - releaseElapsed / releaseSec) : 0.0;
  }
  return 0.0;
}

/// Compact ADSR curve for the sampler Tone tab.
class SamplerEnvelopePreview extends StatelessWidget {
  const SamplerEnvelopePreview({
    super.key,
    required this.attack,
    required this.decay,
    required this.sustain,
    required this.release,
    required this.accent,
    this.label = 'AMP',
  });

  final double attack;
  final double decay;
  final double sustain;
  final double release;
  final Color accent;
  final String label;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SamplerEnvelopePainter(
        attack: attack,
        decay: decay,
        sustain: sustain,
        release: release,
        accent: accent,
        label: label,
      ),
      child: const SizedBox.expand(),
    );
  }
}
