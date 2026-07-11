part of 'curve_editor_screen.dart';

extension _CurveEditorScreenStateGeneratesegmentshape
    on _CurveEditorScreenState {
  List<List<double>> _generateSegmentShape(
    String shapeName,
    double posStart,
    double posEnd,
    double valStart,
    double valEnd, {
    required double floor,
    required double peak,
    required double cycles,
  }) {
    final span = posEnd - posStart;
    if (span <= 1e-6) return [<double>[], <double>[]];

    final lo = math.min(floor, peak);
    final hi = math.max(floor, peak);

    const stepsPerCycle = 16;
    final total = math.max(2, (stepsPerCycle * cycles).round());

    final pos = <double>[];
    final val = <double>[];

    for (var i = 0; i <= total; i++) {
      final t = i / total;
      final phase = (t * cycles) % 1.0;
      double v;
      switch (shapeName) {
        case 'ramp':
          v = lo + (hi - lo) * phase;
        case 'saw':
          v = lo + (hi - lo) * phase;
        case 'tri':
          v = phase < 0.5
              ? lo + (hi - lo) * 2.0 * phase
              : lo + (hi - lo) * (2.0 - 2.0 * phase);
        case 'square':
          v = phase < 0.5 ? hi : lo;
        case 'sine':
        default:
          v = lo + (hi - lo) * (0.5 + 0.5 * math.sin(2 * math.pi * phase));
      }
      pos.add(posStart + t * span);
      val.add(v);
    }

    // Force anchor values exactly.
    pos[0] = posStart;
    val[0] = valStart;
    pos[pos.length - 1] = posEnd;
    val[val.length - 1] = valEnd;

    return [pos, val];
  }
}
