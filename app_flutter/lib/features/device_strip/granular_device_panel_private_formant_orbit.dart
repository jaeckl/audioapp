part of 'granular_device_panel.dart';

class _FormantOrbit extends StatelessWidget {
  const _FormantOrbit({
    required this.x,
    required this.y,
    required this.onChanged,
    required this.xModulated,
    required this.yModulated,
    required this.xAutomated,
    required this.yAutomated,
    required this.connectMode,
    required this.automationLinkMode,
    this.onModulationAssign,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  static const labels = ['A', 'E', 'I', 'AIR', 'U', 'O'];
  final double x, y;
  final void Function(double x, double y) onChanged;
  final bool xModulated, yModulated, xAutomated, yAutomated;
  final bool connectMode, automationLinkMode;
  final void Function(String, double)? onModulationAssign;
  final ValueChanged<String>? onAutomationLinkTap, onAutomateParameter;

  List<Offset> _points(Size size) {
    const normalized = [
      Offset(.5, .05),
      Offset(.88, .25),
      Offset(.88, .75),
      Offset(.5, .95),
      Offset(.12, .75),
      Offset(.12, .25),
    ];
    return [
      for (final point in normalized)
        Offset(point.dx * size.width, point.dy * size.height)
    ];
  }

  String _axisFor(Offset local, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    return (local.dx - center.dx).abs() >= (local.dy - center.dy).abs()
        ? 'formX'
        : 'formY';
  }

  void _interact(Offset local, Size size) {
    final axis = _axisFor(local, size);
    if (connectMode) {
      onModulationAssign?.call(axis, .5);
      return;
    }
    if (automationLinkMode) {
      onAutomationLinkTap?.call(axis);
      return;
    }
    onChanged(
      (local.dx / size.width).clamp(0.0, 1.0),
      (local.dy / size.height).clamp(0.0, 1.0),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) => _interact(details.localPosition, size),
            onPanUpdate: connectMode || automationLinkMode
                ? null
                : (details) => _interact(details.localPosition, size),
            onLongPressStart: (details) => onAutomateParameter
                ?.call(_axisFor(details.localPosition, size)),
            child: CustomPaint(
              painter: _FormantOrbitPainter(
                x: x,
                y: y,
                labels: labels,
                points: _points(size),
                xActive: xModulated || xAutomated,
                yActive: yModulated || yAutomated,
              ),
              size: size,
            ),
          );
        },
      );
}
