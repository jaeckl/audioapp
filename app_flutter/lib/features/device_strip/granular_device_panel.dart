import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_automation_knob.dart';
import 'device_knob_sizes.dart';
import 'device_tab_bar.dart';

class GranularDevicePanel extends StatelessWidget {
  const GranularDevicePanel({
    super.key,
    required this.device,
    required this.sample,
    required this.tab,
    required this.playing,
    required this.playheadBeat,
    required this.onChanged,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.lfos = const [],
    this.modEdges = const [],
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  static const double designWidth = 292;
  static const accent = Color(0xFFDA70D6);
  static const containerTabs = [
    DeviceTabSpec(icon: Icons.graphic_eq, label: 'SAMPLE'),
    DeviceTabSpec(icon: Icons.blur_on, label: 'GRAIN'),
    DeviceTabSpec(icon: Icons.record_voice_over, label: 'FORM'),
  ];

  final GranularDeviceSnapshot device;
  final SampleLibraryEntrySnapshot? sample;
  final int tab;
  final bool playing;
  final double playheadBeat;
  final void Function(String, double) onChanged;
  final Set<String> modulatedParams, automatedParams;
  final Map<String, double> modulationAmounts;
  final List<LfoSnapshot> lfos;
  final List<ModulationEdgeSnapshot> modEdges;
  final int? connectModeLfoId;
  final void Function(String, double)? onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap, onAutomateParameter;

  Widget knob(String label, String id, double value,
          [String? display, double size = DeviceKnobSizes.strip]) =>
      deviceAutomationKnob(
        label: label,
        value: value,
        displayValue: display,
        onChanged: (v) => onChanged(id, v),
        paramId: id,
        deviceId: device.id,
        modulatedParams: modulatedParams,
        automatedParams: automatedParams,
        modulationAmounts: modulationAmounts,
        lfos: lfos,
        modEdges: modEdges,
        connectModeLfoId: connectModeLfoId,
        onModulationAssign: onModulationAssign,
        automationLinkActive: automationLinkActive,
        onAutomationLinkTap: onAutomationLinkTap,
        onAutomateParameter: onAutomateParameter,
        accentColor: accent,
        size: size,
      );

  @override
  Widget build(BuildContext context) {
    if (tab == 2) {
      return Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: _FormantOrbit(
                x: device.formX,
                y: device.formY,
                onChanged: (x, y) {
                  onChanged('formX', x);
                  onChanged('formY', y);
                },
                xModulated: modulatedParams.contains('formX'),
                yModulated: modulatedParams.contains('formY'),
                xAutomated: automatedParams.contains('formX'),
                yAutomated: automatedParams.contains('formY'),
                connectMode: connectModeLfoId != null,
                automationLinkMode: automationLinkActive,
                onModulationAssign: onModulationAssign,
                onAutomationLinkTap: onAutomationLinkTap,
                onAutomateParameter: onAutomateParameter,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              knob('Shift', 'formant', device.formant, null,
                  DeviceKnobSizes.compact),
              knob('Color', 'character', device.character, null,
                  DeviceKnobSizes.compact),
              knob('Spread', 'spread', device.spread, null,
                  DeviceKnobSizes.compact),
              knob('Attack', 'attack', device.attack, null,
                  DeviceKnobSizes.compact),
              knob('Release', 'release', device.release, null,
                  DeviceKnobSizes.compact),
            ],
          ),
        ],
      );
    }

    final controls = tab == 0
        ? [
            knob('Position', 'position', device.position),
            knob('Scan', 'scan', device.scan),
            knob(
              'Pitch',
              'grainPitch',
              device.grainPitch,
              '${((device.grainPitch - .5) * 48).round()} st',
            ),
          ]
        : [
            knob('Size', 'grainSize', device.grainSize),
            knob('Density', 'density', device.density),
            knob('Spray', 'spray', device.spray),
          ];
    final regionLength = device.regionEnd - device.regionStart;
    final motion = playing
        ? (device.position + playheadBeat * (device.scan - .5) * .35) % 1.0
        : device.position;
    final livePosition = device.regionStart + motion * regionLength;
    return Column(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(8, 6, 8, 4),
            decoration: BoxDecoration(
              color: const Color(0xFF111119),
              borderRadius: BorderRadius.circular(4),
            ),
            child: tab == 0
                ? _SampleRegionPreview(
                    peaks: sample?.waveformPeaks ?? const [],
                    sampleName: device.sampleId.isEmpty
                        ? 'LOAD SAMPLE'
                        : (sample?.name ?? 'SAMPLE'),
                    regionStart: device.regionStart,
                    regionEnd: device.regionEnd,
                    position: livePosition,
                    scan: device.scan,
                    enabled: sample != null,
                    onPositionChanged: (absolute) => onChanged(
                      'position',
                      ((absolute - device.regionStart) / regionLength)
                          .clamp(0, 1),
                    ),
                    onRegionStartChanged: (value) =>
                        onChanged('regionStart', value),
                    onRegionEndChanged: (value) =>
                        onChanged('regionEnd', value),
                  )
                : _GrainCloudPreview(
                    position: livePosition,
                    size: device.grainSize,
                    density: device.density,
                    spray: device.spray,
                    pitch: device.grainPitch,
                  ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: controls,
        ),
      ],
    );
  }
}

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

class _FormantOrbitPainter extends CustomPainter {
  const _FormantOrbitPainter({
    required this.x,
    required this.y,
    required this.labels,
    required this.points,
    required this.xActive,
    required this.yActive,
  });

  final double x, y;
  final List<String> labels;
  final List<Offset> points;
  final bool xActive, yActive;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final loop = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      loop.lineTo(points[i].dx, points[i].dy);
    }
    loop.close();
    canvas.drawPath(
      loop,
      Paint()
        ..color = GranularDevicePanel.accent.withValues(alpha: .25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final selectedPoint = Offset(x * size.width, y * size.height);
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawLine(
      center,
      selectedPoint,
      Paint()
        ..color = GranularDevicePanel.accent.withValues(alpha: .38)
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(
      center,
      5,
      Paint()..color = GranularDevicePanel.accent.withValues(alpha: .18),
    );
    canvas.drawCircle(
      selectedPoint,
      9,
      Paint()..color = GranularDevicePanel.accent.withValues(alpha: .24),
    );
    canvas.drawCircle(
      selectedPoint,
      3.5,
      Paint()..color = GranularDevicePanel.accent,
    );

    for (var i = 0; i < points.length; i++) {
      final painter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: Colors.white.withValues(alpha: .55),
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        points[i] - Offset(painter.width / 2, painter.height / 2),
      );
    }
    _paintText(
        canvas,
        'X',
        Offset(size.width - 3, size.height - 12),
        xActive ? GranularDevicePanel.accent : Colors.white38,
        8,
        TextAlign.right);
    _paintText(
        canvas,
        'Y',
        const Offset(3, 2),
        yActive ? GranularDevicePanel.accent : Colors.white38,
        8,
        TextAlign.left);
  }

  @override
  bool shouldRepaint(_FormantOrbitPainter oldDelegate) =>
      oldDelegate.x != x ||
      oldDelegate.y != y ||
      oldDelegate.xActive != xActive ||
      oldDelegate.yActive != yActive ||
      oldDelegate.points != points;
}

enum _RegionDrag { start, end, position }

class _SampleRegionPreview extends StatefulWidget {
  const _SampleRegionPreview({
    required this.peaks,
    required this.sampleName,
    required this.regionStart,
    required this.regionEnd,
    required this.position,
    required this.scan,
    required this.enabled,
    required this.onPositionChanged,
    required this.onRegionStartChanged,
    required this.onRegionEndChanged,
  });

  final List<double> peaks;
  final String sampleName;
  final double regionStart, regionEnd, position, scan;
  final bool enabled;
  final ValueChanged<double> onPositionChanged;
  final ValueChanged<double> onRegionStartChanged;
  final ValueChanged<double> onRegionEndChanged;

  @override
  State<_SampleRegionPreview> createState() => _SampleRegionPreviewState();
}

class _SampleRegionPreviewState extends State<_SampleRegionPreview> {
  _RegionDrag? _drag;

  _RegionDrag _target(double x, double width) {
    final start = widget.regionStart * width;
    final end = widget.regionEnd * width;
    if ((x - start).abs() <= 26) return _RegionDrag.start;
    if ((x - end).abs() <= 26) return _RegionDrag.end;
    return _RegionDrag.position;
  }

  void _update(double x, double width) {
    if (!widget.enabled || width <= 0) return;
    final value = (x / width).clamp(0.0, 1.0);
    switch (_drag ?? _RegionDrag.position) {
      case _RegionDrag.start:
        widget.onRegionStartChanged(value.clamp(0.0, widget.regionEnd - .02));
      case _RegionDrag.end:
        widget.onRegionEndChanged(value.clamp(widget.regionStart + .02, 1.0));
      case _RegionDrag.position:
        widget.onPositionChanged(
          value.clamp(widget.regionStart, widget.regionEnd),
        );
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: widget.enabled
              ? (details) {
                  _drag = _RegionDrag.position;
                  _update(details.localPosition.dx, constraints.maxWidth);
                  _drag = null;
                }
              : null,
          onPanStart: widget.enabled
              ? (details) {
                  setState(() => _drag =
                      _target(details.localPosition.dx, constraints.maxWidth));
                  _update(details.localPosition.dx, constraints.maxWidth);
                }
              : null,
          onPanUpdate: widget.enabled
              ? (details) =>
                  _update(details.localPosition.dx, constraints.maxWidth)
              : null,
          onPanEnd: (_) => setState(() => _drag = null),
          onPanCancel: () => setState(() => _drag = null),
          child: CustomPaint(
            painter: _SampleRegionPainter(
              peaks: widget.peaks,
              sampleName: widget.sampleName,
              regionStart: widget.regionStart,
              regionEnd: widget.regionEnd,
              position: widget.position,
              scan: widget.scan,
              activeHandle: _drag,
            ),
          ),
        ),
      );
}

class _SampleRegionPainter extends CustomPainter {
  const _SampleRegionPainter({
    required this.peaks,
    required this.sampleName,
    required this.regionStart,
    required this.regionEnd,
    required this.position,
    required this.scan,
    required this.activeHandle,
  });

  final List<double> peaks;
  final String sampleName;
  final double regionStart, regionEnd, position, scan;
  final _RegionDrag? activeHandle;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final startX = regionStart * size.width;
    final endX = regionEnd * size.width;
    final region = Rect.fromLTRB(startX, 0, endX, size.height);
    canvas.drawRect(
      region,
      Paint()..color = GranularDevicePanel.accent.withValues(alpha: .08),
    );

    final wave = Paint()
      ..color = Colors.white.withValues(alpha: .42)
      ..strokeWidth = 1;
    final count = math.max(peaks.length, 48);
    for (var i = 0; i < count; i++) {
      final x = i / math.max(1, count - 1) * size.width;
      final sourceIndex = peaks.isEmpty
          ? i
          : (i / count * peaks.length).floor().clamp(0, peaks.length - 1);
      final peak = peaks.isEmpty
          ? math.sin(i * .79) * .42
          : peaks[sourceIndex].abs().clamp(0.0, 1.0);
      canvas.drawLine(
        Offset(x, centerY - peak * size.height * .34),
        Offset(x, centerY + peak * size.height * .34),
        wave,
      );
    }
    canvas.drawRect(
      Rect.fromLTRB(0, 0, startX, size.height),
      Paint()..color = Colors.black.withValues(alpha: .58),
    );
    canvas.drawRect(
      Rect.fromLTRB(endX, 0, size.width, size.height),
      Paint()..color = Colors.black.withValues(alpha: .58),
    );

    void handle(double x, String label, bool selected, bool left) {
      final color = selected ? Colors.white : GranularDevicePanel.accent;
      final paint = Paint()
        ..color = color
        ..strokeWidth = selected ? 2.5 : 2;
      canvas.drawLine(Offset(x, 3), Offset(x, size.height - 3), paint);
      final direction = left ? 1.0 : -1.0;
      final path = Path()
        ..moveTo(x, 3)
        ..lineTo(x + direction * 10, 3)
        ..lineTo(x, 13)
        ..close();
      canvas.drawPath(path, paint);
      _paintText(canvas, label, Offset(x + direction * 7, size.height - 15),
          color, 8, TextAlign.center);
    }

    handle(startX, 'S', activeHandle == _RegionDrag.start, true);
    handle(endX, 'E', activeHandle == _RegionDrag.end, false);

    final cursorX = position.clamp(regionStart, regionEnd) * size.width;
    final cursorPaint = Paint()
      ..color = Colors.white.withValues(alpha: .9)
      ..strokeWidth = 1.5;
    canvas.drawLine(
        Offset(cursorX, 8), Offset(cursorX, size.height - 5), cursorPaint);
    canvas.drawCircle(Offset(cursorX, 7), 3, cursorPaint);

    final scanAmount = scan - .5;
    if (scanAmount.abs() > .025 && endX - startX > 12) {
      final direction = scanAmount.sign;
      final arrowEnd = (cursorX + direction * (12 + scanAmount.abs() * 34))
          .clamp(startX + 4, endX - 4);
      canvas.drawLine(Offset(cursorX, 16), Offset(arrowEnd, 16), cursorPaint);
      canvas.drawLine(
        Offset(arrowEnd, 16),
        Offset(arrowEnd - direction * 5, 12),
        cursorPaint,
      );
      canvas.drawLine(
        Offset(arrowEnd, 16),
        Offset(arrowEnd - direction * 5, 20),
        cursorPaint,
      );
    }
    _paintText(canvas, sampleName, Offset(size.width / 2, 4),
        Colors.white.withValues(alpha: .52), 9, TextAlign.center);
  }

  @override
  bool shouldRepaint(_SampleRegionPainter oldDelegate) =>
      oldDelegate.peaks != peaks ||
      oldDelegate.regionStart != regionStart ||
      oldDelegate.regionEnd != regionEnd ||
      oldDelegate.position != position ||
      oldDelegate.scan != scan ||
      oldDelegate.activeHandle != activeHandle;
}

class _GrainCloudPreview extends StatelessWidget {
  const _GrainCloudPreview({
    required this.position,
    required this.size,
    required this.density,
    required this.spray,
    required this.pitch,
  });

  final double position, size, density, spray, pitch;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _GrainCloudPainter(
          position: position,
          grainSize: size,
          density: density,
          spray: spray,
          pitch: pitch,
        ),
      );
}

class _GrainCloudPainter extends CustomPainter {
  const _GrainCloudPainter({
    required this.position,
    required this.grainSize,
    required this.density,
    required this.spray,
    required this.pitch,
  });

  final double position, grainSize, density, spray, pitch;

  @override
  void paint(Canvas canvas, Size size) {
    final count = 4 + (density * 18).round();
    final width = 7 + grainSize * 42;
    final slope = (pitch - .5) * 18;
    final centerY = size.height / 2;
    final axis = Paint()
      ..color = Colors.white.withValues(alpha: .1)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(5, centerY), Offset(size.width - 5, centerY), axis);

    for (var i = 0; i < count; i++) {
      final seed = math.sin((i + 1) * 91.731);
      final normalized = count == 1 ? .5 : i / (count - 1);
      final x = 8 + normalized * (size.width - 16);
      final scatter = seed * spray * size.height * .34;
      final y = centerY + scatter;
      final half = width / 2;
      final alpha = .2 + .5 * (1 - (normalized - position).abs().clamp(0, 1));
      final paint = Paint()
        ..color = GranularDevicePanel.accent.withValues(alpha: alpha)
        ..strokeWidth = 1.4 + grainSize;
      final path = Path();
      for (var step = 0; step <= 10; step++) {
        final t = step / 10;
        final px = x - half + t * width;
        final envelope = math.sin(t * math.pi);
        final py = y + (t - .5) * slope * envelope;
        step == 0 ? path.moveTo(px, py) : path.lineTo(px, py);
      }
      canvas.drawPath(path, paint);
      canvas.drawCircle(Offset(x, y), 1.5 + grainSize, paint);
    }

    final cursorX = 8 + position * (size.width - 16);
    canvas.drawLine(
      Offset(cursorX, 5),
      Offset(cursorX, size.height - 18),
      Paint()
        ..color = Colors.white.withValues(alpha: .55)
        ..strokeWidth = 1,
    );
    _paintText(canvas, '${(12 + grainSize * 180).round()} ms',
        const Offset(8, 5), Colors.white54, 8, TextAlign.left);
    _paintText(
        canvas,
        '${(5 + density * 39).round()} grains/s',
        Offset(size.width / 2, size.height - 14),
        Colors.white54,
        8,
        TextAlign.center);
    _paintText(canvas, '${((pitch - .5) * 48).round()} st',
        Offset(size.width - 8, 5), Colors.white54, 8, TextAlign.right);
  }

  @override
  bool shouldRepaint(_GrainCloudPainter oldDelegate) =>
      oldDelegate.position != position ||
      oldDelegate.grainSize != grainSize ||
      oldDelegate.density != density ||
      oldDelegate.spray != spray ||
      oldDelegate.pitch != pitch;
}

void _paintText(Canvas canvas, String text, Offset anchor, Color color,
    double size, TextAlign align) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: TextStyle(color: color, fontSize: size)),
    textDirection: TextDirection.ltr,
  )..layout();
  final dx = switch (align) {
    TextAlign.center => anchor.dx - painter.width / 2,
    TextAlign.right => anchor.dx - painter.width,
    _ => anchor.dx,
  };
  painter.paint(canvas, Offset(dx, anchor.dy));
}
