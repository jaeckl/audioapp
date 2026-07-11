part of 'envelope_preview_painter.dart';

class EnvelopePreviewWidget extends StatefulWidget {
  const EnvelopePreviewWidget({
    super.key,
    required this.attack,
    required this.hold,
    required this.decay,
    required this.sustain,
    required this.release,
    required this.curveType,
    required this.onChanged,
    this.delay = 0.0,
    this.attackCurve = 0.5,
    this.decayCurve = 0.5,
    this.releaseCurve = 0.5,
    this.analogMode = 0,
  });

  final double attack;
  final double hold;
  final double decay;
  final double sustain;
  final double release;
  final int curveType;
  final void Function(String param, double value) onChanged;
  final double delay;
  final double attackCurve;
  final double decayCurve;
  final double releaseCurve;
  final int analogMode;

  @override
  State<EnvelopePreviewWidget> createState() => _EnvelopePreviewWidgetState();
}
