import 'package:flutter/material.dart';

import '../sample_library/sample_library_screen.dart';
import 'device_automation_spinner.dart';
import 'modulator_polarity.dart';

/// Strip: loop region only. Editor: trim bounds + optional loop band inside trim.
enum SamplerWaveformDensity { strip, editor }

/// Shared waveform surface for sampler Wave tab (strip + fullscreen).
class SamplerWaveformView extends StatefulWidget {
  const SamplerWaveformView({
    super.key,
    required this.peaks,
    required this.durationSec,
    required this.trimStartSec,
    required this.trimEndSec,
    required this.regionStartSec,
    required this.regionEndSec,
    required this.density,
    required this.waveColor,
    required this.accentColor,
    this.onTrimChanged,
    this.onRegionChanged,
    this.onPreview,
    this.loopRegionEnabled = false,
    this.emptyHint,
    this.onLoadSample,
  });

  final List<double> peaks;
  final double durationSec;
  final double trimStartSec;
  final double trimEndSec;
  final double regionStartSec;
  final double regionEndSec;
  final SamplerWaveformDensity density;
  final Color waveColor;
  final Color accentColor;
  final void Function(double startSec, double endSec)? onTrimChanged;
  final void Function(double startSec, double endSec)? onRegionChanged;
  final VoidCallback? onPreview;
  final bool loopRegionEnabled;
  final String? emptyHint;
  final VoidCallback? onLoadSample;

  bool get hasLoop => regionEndSec > 0;
  bool get showLoopBand => loopRegionEnabled && (hasLoop || onRegionChanged != null);

  @override
  State<SamplerWaveformView> createState() => _SamplerWaveformViewState();
}

class _SamplerWaveformViewState extends State<SamplerWaveformView> {
  /// Visible handle width (bar + grip).
  static const double _handleVisualWidth = 12;
  /// Touch target radius — generous pickup on mobile.
  static const double _handleHitRadius = 28;
  static const double _minSpanSec = 0.02;

  bool get _loopActive => _localRegionEnd > 0;

  late double _localTrimStart;
  late double _localTrimEnd;
  late double _localRegionStart;
  late double _localRegionEnd;
  _WaveformDrag? _drag;

  bool get _showTrimHandles =>
      widget.onTrimChanged != null && !widget.loopRegionEnabled;

  bool get _showLoopHandles {
    if (widget.loopRegionEnabled) {
      return _loopActive || _drag?.affectsRegion == true;
    }
    return !_editor && widget.onRegionChanged != null && _loopActive;
  }

  bool get _showLoopBand => _showLoopHandles;

  static const double _handleVerticalInset = 4.0;

  bool get _editor => widget.density == SamplerWaveformDensity.editor;

  double get _dur => widget.durationSec > 0 ? widget.durationSec : 1.0;

  double get _trimStart => _drag != null && _drag!.affectsTrim
      ? _localTrimStart
      : widget.trimStartSec;
  double get _trimEnd => _drag != null && _drag!.affectsTrim
      ? _localTrimEnd
      : (widget.trimEndSec > 0 ? widget.trimEndSec : _dur);
  double get _regionStart => _drag != null && _drag!.affectsRegion
      ? _localRegionStart
      : widget.regionStartSec;
  double get _regionEnd => _drag != null && _drag!.affectsRegion
      ? _localRegionEnd
      : widget.regionEndSec;

  @override
  void initState() {
    super.initState();
    _syncLocal();
  }

  @override
  void didUpdateWidget(covariant SamplerWaveformView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_drag == null) {
      _syncLocal();
    }
  }

  void _syncLocal() {
    _localTrimStart = widget.trimStartSec.clamp(0, _dur);
    _localTrimEnd =
        widget.trimEndSec > 0 ? widget.trimEndSec.clamp(_localTrimStart + _minSpanSec, _dur) : _dur;
    _localRegionStart = widget.regionStartSec.clamp(0, _dur - _minSpanSec);
    _localRegionEnd = widget.regionEndSec > 0
        ? widget.regionEndSec.clamp(_localRegionStart + _minSpanSec, _dur)
        : 0;
  }

  double _secFromDx(double dx, double width) => (dx / width * _dur).clamp(0, _dur);

  /// Left-boundary handle sits immediately to the right of [boundaryX].
  double _leftHandleLeft(double boundaryX, double width) =>
      boundaryX.clamp(0, width - _handleVisualWidth);

  /// Right-boundary handle sits immediately to the left of [boundaryX].
  double _rightHandleLeft(double boundaryX, double width) =>
      (boundaryX - _handleVisualWidth).clamp(0, width - _handleVisualWidth);

  bool _hitLeftHandle(
    double x,
    double y,
    double boundaryX,
    double width,
    double height,
    double top,
    double bottom,
  ) {
    if (y < top || y > bottom) return false;
    final gripCenterX = boundaryX + _handleVisualWidth / 2;
    return (x - gripCenterX).abs() <= _handleHitRadius;
  }

  bool _hitRightHandle(
    double x,
    double y,
    double boundaryX,
    double width,
    double height,
    double top,
    double bottom,
  ) {
    if (y < top || y > bottom) return false;
    final gripCenterX = boundaryX - _handleVisualWidth / 2;
    return (x - gripCenterX).abs() <= _handleHitRadius;
  }

  void _commitTrim() => widget.onTrimChanged?.call(_localTrimStart, _localTrimEnd);

  void _commitRegion() =>
      widget.onRegionChanged?.call(_localRegionStart, _localRegionEnd);

  _WaveformDrag? _pickHandle(double x, double y, double width, double height) {
    _WaveformDrag? best;
    var bestDist = _handleHitRadius;

    void consider(_WaveformDrag kind, double dist) {
      if (dist < bestDist) {
        bestDist = dist;
        best = kind;
      }
    }

    final trimStartX = _trimStart / _dur * width;
    final trimEndX = _trimEnd / _dur * width;
    final yMin = _handleVerticalInset;
    final yMax = height - _handleVerticalInset;

    if (_showTrimHandles) {
      if (_hitLeftHandle(x, y, trimStartX, width, height, yMin, yMax)) {
        consider(_WaveformDrag.trimStart, (x - (trimStartX + _handleVisualWidth / 2)).abs());
      }
      if (_hitRightHandle(x, y, trimEndX, width, height, yMin, yMax)) {
        consider(_WaveformDrag.trimEnd, (x - (trimEndX - _handleVisualWidth / 2)).abs());
      }
    }

    if (_showLoopHandles) {
      final regionStartX = _regionStart / _dur * width;
      final regionEndX = _regionEnd / _dur * width;
      if (_hitLeftHandle(x, y, regionStartX, width, height, yMin, yMax)) {
        consider(_WaveformDrag.regionStart, (x - (regionStartX + _handleVisualWidth / 2)).abs());
      }
      if (_hitRightHandle(x, y, regionEndX, width, height, yMin, yMax)) {
        consider(_WaveformDrag.regionEnd, (x - (regionEndX - _handleVisualWidth / 2)).abs());
      }
    }

    return best;
  }

  void _onDragStart(double x, double y, double width, double height) {
    if (widget.peaks.isEmpty) {
      return;
    }
    _syncLocal();
    final picked = _pickHandle(x, y, width, height);
    if (picked == null) {
      return;
    }
    setState(() => _drag = picked);
  }

  void _onDragUpdate(double x, double width) {
    if (_drag == null) {
      return;
    }
    setState(() {
      final sec = _secFromDx(x, width);
      switch (_drag!) {
        case _WaveformDrag.trimStart:
          _localTrimStart = sec.clamp(0.0, _localTrimEnd - _minSpanSec);
        case _WaveformDrag.trimEnd:
          _localTrimEnd = sec.clamp(_localTrimStart + _minSpanSec, _dur);
        case _WaveformDrag.regionStart:
          _localRegionStart = sec.clamp(0.0, _localRegionEnd - _minSpanSec);
        case _WaveformDrag.regionEnd:
          _localRegionEnd = sec.clamp(_localRegionStart + _minSpanSec, _dur);
      }
    });
  }

  void _onDragEnd() {
    if (_drag == null) {
      return;
    }
    final drag = _drag!;
    _drag = null;
    if (drag.affectsTrim) {
      _commitTrim();
    } else {
      _commitRegion();
    }
    setState(_syncLocal);
  }

  void _createRegionAt(double tapSec) {
    final halfWidth = _dur * 0.1;
    var start = (tapSec - halfWidth).clamp(0.0, _dur);
    var end = (tapSec + halfWidth).clamp(0.0, _dur);
    if (end - start < 0.05) {
      end = (start + 0.05).clamp(0.0, _dur);
    }
    widget.onRegionChanged?.call(start, end);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.peaks.isEmpty) {
      return _SamplerWaveformEmptyState(
        hint: widget.emptyHint,
        accentColor: widget.accentColor,
        onLoadSample: widget.onLoadSample,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final trimStartX = _trimStart / _dur * w;
        final trimEndX = _trimEnd / _dur * w;
        final regionStartX = _regionStart / _dur * w;
        final regionEndX = _regionEnd / _dur * w;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onLongPress: widget.onPreview,
                onHorizontalDragStart: (d) =>
                    _onDragStart(d.localPosition.dx, d.localPosition.dy, w, h),
                onHorizontalDragUpdate: (d) => _onDragUpdate(d.localPosition.dx, w),
                onHorizontalDragEnd: (_) => _onDragEnd(),
                onTapUp: widget.showLoopBand && !widget.hasLoop && widget.onRegionChanged != null
                    ? (d) => _createRegionAt(_secFromDx(d.localPosition.dx, w))
                    : null,
                child: Stack(
                  fit: StackFit.expand,
                  clipBehavior: Clip.hardEdge,
                  children: [
                    CustomPaint(
                      painter: WaveformPainter(
                        peaks: widget.peaks,
                        color: widget.waveColor,
                        durationSec: _editor ? _dur : null,
                        trimStartSec: _showTrimHandles ? _trimStart : null,
                        trimEndSec: _showTrimHandles ? _trimEnd : null,
                        dimOutsideTrim: _showTrimHandles,
                      ),
                    ),
                    if (_showLoopBand)
                      Positioned(
                        left: regionStartX.clamp(0, w),
                        width: (regionEndX - regionStartX).clamp(0, w),
                        top: 0,
                        bottom: 0,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: widget.accentColor.withValues(alpha: 0.18),
                              border: Border.symmetric(
                                vertical: BorderSide(
                                  color: widget.accentColor.withValues(alpha: 0.75),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (_showTrimHandles) ...[
                      _Handle(
                        left: _leftHandleLeft(trimStartX, w),
                        top: _handleVerticalInset,
                        bottom: _handleVerticalInset,
                        color: widget.waveColor,
                        alignLeft: true,
                      ),
                      _Handle(
                        left: _rightHandleLeft(trimEndX, w),
                        top: _handleVerticalInset,
                        bottom: _handleVerticalInset,
                        color: widget.waveColor,
                        alignLeft: false,
                      ),
                    ],
                    if (_showLoopHandles) ...[
                      _Handle(
                        left: _leftHandleLeft(regionStartX, w),
                        top: _handleVerticalInset,
                        bottom: _handleVerticalInset,
                        color: widget.accentColor,
                        alignLeft: true,
                      ),
                      _Handle(
                        left: _rightHandleLeft(regionEndX, w),
                        top: _handleVerticalInset,
                        bottom: _handleVerticalInset,
                        color: widget.accentColor,
                        alignLeft: false,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_editor && (_showTrimHandles || _showLoopHandles))
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    if (_showTrimHandles)
                      _LegendChip(
                        label: 'TRIM',
                        detail:
                            '${formatSamplerDurationSec(_trimStart)} – ${formatSamplerDurationSec(_trimEnd)}',
                        color: widget.waveColor,
                      ),
                    if (_showLoopHandles && widget.onRegionChanged != null)
                      Expanded(
                        child: _LegendChip(
                          label: 'LOOP',
                          detail:
                              '${formatSamplerDurationSec(_regionStart)} – ${formatSamplerDurationSec(_regionEnd)}',
                          color: widget.accentColor,
                          onClear: widget.loopRegionEnabled
                              ? () => widget.onRegionChanged!(0, 0)
                              : null,
                        ),
                      )
                    else if (widget.loopRegionEnabled && !_loopActive)
                      _LegendChip(
                        label: 'LOOP',
                        detail: 'tap waveform',
                        color: widget.accentColor,
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

enum _WaveformDrag {
  trimStart,
  trimEnd,
  regionStart,
  regionEnd;

  bool get affectsTrim => this == trimStart || this == trimEnd;
  bool get affectsRegion => this == regionStart || this == regionEnd;
}

class _SamplerWaveformEmptyState extends StatelessWidget {
  const _SamplerWaveformEmptyState({
    required this.hint,
    required this.accentColor,
    this.onLoadSample,
  });

  final String? hint;
  final Color accentColor;
  final VoidCallback? onLoadSample;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.graphic_eq_rounded,
                size: 28,
                color: accentColor.withValues(alpha: 0.45),
              ),
              const SizedBox(height: 8),
              Text(
                hint ?? 'Load a sample to edit trim and playback',
                style: theme.textTheme.labelMedium?.copyWith(color: Colors.white38),
                textAlign: TextAlign.center,
              ),
              if (onLoadSample != null) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: onLoadSample,
                  icon: const Icon(Icons.folder_open_rounded, size: 18),
                  label: const Text('Load sample'),
                  style: FilledButton.styleFrom(
                    backgroundColor: accentColor.withValues(alpha: 0.22),
                    foregroundColor: accentColor,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle({
    required this.left,
    required this.top,
    required this.bottom,
    required this.color,
    required this.alignLeft,
  });

  final double left;
  final double top;
  final double bottom;
  final Color color;
  final bool alignLeft;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      bottom: bottom,
      child: IgnorePointer(
        child: Container(
          width: _SamplerWaveformViewState._handleVisualWidth,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              topLeft: alignLeft ? Radius.zero : const Radius.circular(3),
              bottomLeft: alignLeft ? Radius.zero : const Radius.circular(3),
              topRight: alignLeft ? const Radius.circular(3) : Radius.zero,
              bottomRight: alignLeft ? const Radius.circular(3) : Radius.zero,
            ),
            border: Border.all(color: Colors.black.withValues(alpha: 0.35)),
            boxShadow: const [
              BoxShadow(color: Color(0x55000000), blurRadius: 2, offset: Offset(0, 1)),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.drag_handle,
              size: 12,
              color: Colors.black.withValues(alpha: 0.55),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.label,
    required this.detail,
    required this.color,
    this.onClear,
  });

  final String label;
  final String detail;
  final Color color;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            detail,
            style: const TextStyle(color: Colors.white60, fontSize: 10),
          ),
          if (onClear != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onClear,
              child: Icon(Icons.close, size: 12, color: color),
            ),
          ],
        ],
      ),
    );
  }
}

/// Formats seconds for sampler time readouts (e.g. 0.42s).
String formatSamplerDurationSec(double sec) {
  if (sec >= 10) return '${sec.toStringAsFixed(1)}s';
  return '${sec.toStringAsFixed(2)}s';
}

/// Playback window label for the Wave tab footer.
String formatSamplerPlaybackRange({
  required int playbackMode,
  required double durationSec,
  required double trimStartSec,
  required double trimEndSec,
  required double regionStartSec,
  required double regionEndSec,
}) {
  final trimEnd = trimEndSec > 0 ? trimEndSec : durationSec;
  final trimStart = trimStartSec.clamp(0.0, trimEnd).toDouble();
  switch (playbackMode) {
    case 1:
      if (regionEndSec > 0) {
        return 'Loop ${formatSamplerDurationSec(regionStartSec)}–${formatSamplerDurationSec(regionEndSec)}';
      }
      return 'Loop ${formatSamplerDurationSec(trimStart)}–${formatSamplerDurationSec(trimEnd)}';
    case 2:
      return 'Rev ${formatSamplerDurationSec(trimStart)}–${formatSamplerDurationSec(trimEnd)}';
    default:
      return 'Shot ${formatSamplerDurationSec(trimStart)}–${formatSamplerDurationSec(trimEnd)}';
  }
}

/// Formats a MIDI note number as e.g. C3.
String formatSamplerMidiNote(int pitch) {
  const names = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
  final clamped = pitch.clamp(0, 127);
  return '${names[clamped % 12]}${(clamped ~/ 12) - 1}';
}

/// Formats fine tune cents for the identity bar chip.
String formatSamplerFineTune(double cents) {
  final rounded = cents.round().clamp(-100, 100);
  if (rounded == 0) return '0¢';
  if (rounded > 0) return '+$rounded¢';
  return '$rounded¢';
}

/// Modulation + automation wiring for identity-bar spinners.
class SpinnerModulationProps {
  const SpinnerModulationProps({
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
    this.rootPitchPolarity = ModulatorPolarity.bipolar,
    this.rootFineTunePolarity = ModulatorPolarity.bipolar,
  });

  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final void Function(String paramId, double amount)? onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;
  final ModulatorPolarity rootPitchPolarity;
  final ModulatorPolarity rootFineTunePolarity;

  static const none = SpinnerModulationProps();
}

/// Root key stepper — drag or tap ▲/▼ to change MIDI note.
class SamplerRootKeyChip extends StatefulWidget {
  const SamplerRootKeyChip({
    super.key,
    required this.rootPitch,
    required this.accentColor,
    required this.onChanged,
    this.showFooterLabel = true,
    this.fixedHeight,
    this.modulation = SpinnerModulationProps.none,
  });

  final int rootPitch;
  final Color accentColor;
  final ValueChanged<int> onChanged;
  final bool showFooterLabel;
  final double? fixedHeight;
  final SpinnerModulationProps modulation;

  @override
  State<SamplerRootKeyChip> createState() => _SamplerRootKeyChipState();
}

class _SamplerRootKeyChipState extends State<SamplerRootKeyChip> {
  double _dragStartY = 0;
  int _dragStartPitch = 60;

  void _bump(int delta) {
    final next = (widget.rootPitch + delta).clamp(0, 127);
    if (next != widget.rootPitch) {
      widget.onChanged(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = formatSamplerMidiNote(widget.rootPitch);
    final accent = widget.accentColor;
    final muted = accent.withValues(alpha: 0.55);
    final mod = widget.modulation;

    final noteLabel = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (d) {
        _dragStartY = d.localPosition.dy;
        _dragStartPitch = widget.rootPitch;
      },
      onVerticalDragUpdate: (d) {
        final delta = ((_dragStartY - d.localPosition.dy) / 8).round();
        final next = (_dragStartPitch + delta).clamp(0, 127);
        if (next != widget.rootPitch) {
          widget.onChanged(next);
        }
      },
      onDoubleTap: () => widget.onChanged(60),
      child: Text(
        label,
        style: TextStyle(
          color: accent,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          height: 1.0,
        ),
      ),
    );

    Widget inner = widget.fixedHeight != null
        ? Column(
            children: [
              Expanded(
                child: _RootStepHit(
                  icon: Icons.keyboard_arrow_up_rounded,
                  color: muted,
                  onTap: () => _bump(1),
                  expand: true,
                ),
              ),
              noteLabel,
              Expanded(
                child: _RootStepHit(
                  icon: Icons.keyboard_arrow_down_rounded,
                  color: muted,
                  onTap: () => _bump(-1),
                  expand: true,
                ),
              ),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _RootStepHit(
                icon: Icons.keyboard_arrow_up_rounded,
                color: muted,
                onTap: () => _bump(1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: noteLabel,
              ),
              _RootStepHit(
                icon: Icons.keyboard_arrow_down_rounded,
                color: muted,
                onTap: () => _bump(-1),
              ),
            ],
          );

    Widget box;
    if (widget.fixedHeight != null) {
      box = deviceAutomationSpinner(
        paramId: 'rootPitch',
        width: 46,
        height: widget.fixedHeight!,
        accentColor: accent,
        borderAlpha: 0.5,
        modulatedParams: mod.modulatedParams,
        automatedParams: mod.automatedParams,
        modulationAmounts: mod.modulationAmounts,
        modulatorPolarity: mod.rootPitchPolarity,
        connectModeLfoId: mod.connectModeLfoId,
        onModulationAssign: mod.onModulationAssign,
        automationLinkActive: mod.automationLinkActive,
        onAutomationLinkTap: mod.onAutomationLinkTap,
        onAutomateParameter: mod.onAutomateParameter,
        child: inner,
      );
    } else {
      box = Container(
        width: 46,
        decoration: BoxDecoration(
          color: const Color(0xFF14141C),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: accent.withValues(alpha: 0.5)),
        ),
        child: inner,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        box,
        if (widget.showFooterLabel) ...[
          const SizedBox(height: 2),
          Text(
            'ROOT',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ],
    );
  }
}

/// Fine tune stepper — ± cents relative to root key.
class SamplerFineTuneChip extends StatefulWidget {
  const SamplerFineTuneChip({
    super.key,
    required this.rootFineTune,
    required this.accentColor,
    required this.onChanged,
    this.fixedHeight,
    this.modulation = SpinnerModulationProps.none,
  });

  final double rootFineTune;
  final Color accentColor;
  final ValueChanged<double> onChanged;
  final double? fixedHeight;
  final SpinnerModulationProps modulation;

  @override
  State<SamplerFineTuneChip> createState() => _SamplerFineTuneChipState();
}

class _SamplerFineTuneChipState extends State<SamplerFineTuneChip> {
  double _dragStartY = 0;
  double _dragStartCents = 0;

  void _bump(int delta) {
    final next = (widget.rootFineTune + delta).clamp(-100.0, 100.0);
    if (next != widget.rootFineTune) {
      widget.onChanged(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = formatSamplerFineTune(widget.rootFineTune);
    final accent = widget.accentColor;
    final muted = accent.withValues(alpha: 0.55);

    final noteLabel = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (d) {
        _dragStartY = d.localPosition.dy;
        _dragStartCents = widget.rootFineTune;
      },
      onVerticalDragUpdate: (d) {
        final delta = ((_dragStartY - d.localPosition.dy) / 4).round();
        final next = (_dragStartCents + delta).clamp(-100.0, 100.0);
        if (next != widget.rootFineTune) {
          widget.onChanged(next);
        }
      },
      onDoubleTap: () => widget.onChanged(0),
      child: Text(
        label,
        style: TextStyle(
          color: accent.withValues(alpha: 0.9),
          fontSize: 10,
          fontWeight: FontWeight.w800,
          height: 1.0,
        ),
      ),
    );

    final inner = widget.fixedHeight != null
        ? Column(
            children: [
              Expanded(
                child: _RootStepHit(
                  icon: Icons.keyboard_arrow_up_rounded,
                  color: muted,
                  onTap: () => _bump(1),
                  expand: true,
                ),
              ),
              noteLabel,
              Expanded(
                child: _RootStepHit(
                  icon: Icons.keyboard_arrow_down_rounded,
                  color: muted,
                  onTap: () => _bump(-1),
                  expand: true,
                ),
              ),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _RootStepHit(
                icon: Icons.keyboard_arrow_up_rounded,
                color: muted,
                onTap: () => _bump(1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: noteLabel,
              ),
              _RootStepHit(
                icon: Icons.keyboard_arrow_down_rounded,
                color: muted,
                onTap: () => _bump(-1),
              ),
            ],
          );

    if (widget.fixedHeight != null) {
      final mod = widget.modulation;
      return deviceAutomationSpinner(
        paramId: 'rootFineTune',
        width: 40,
        height: widget.fixedHeight!,
        accentColor: accent,
        borderAlpha: 0.35,
        modulatedParams: mod.modulatedParams,
        automatedParams: mod.automatedParams,
        modulationAmounts: mod.modulationAmounts,
        modulatorPolarity: mod.rootFineTunePolarity,
        connectModeLfoId: mod.connectModeLfoId,
        onModulationAssign: mod.onModulationAssign,
        automationLinkActive: mod.automationLinkActive,
        onAutomationLinkTap: mod.onAutomationLinkTap,
        onAutomateParameter: mod.onAutomateParameter,
        child: inner,
      );
    }

    return Container(
      width: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF14141C),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: inner,
    );
  }
}

/// Root + play mode in one strip panel (matches device inset styling).
class SamplerPlaybackIdentityBar extends StatelessWidget {
  const SamplerPlaybackIdentityBar({
    super.key,
    required this.rootPitch,
    required this.rootFineTune,
    required this.playbackMode,
    required this.accentColor,
    required this.onRootPitchChanged,
    required this.onRootFineTuneChanged,
    required this.onPlaybackModeChanged,
    this.onPreview,
    this.previewEnabled = true,
    this.modulation = SpinnerModulationProps.none,
  });

  final int rootPitch;
  final double rootFineTune;
  final int playbackMode;
  final Color accentColor;
  final ValueChanged<int> onRootPitchChanged;
  final ValueChanged<double> onRootFineTuneChanged;
  final ValueChanged<int> onPlaybackModeChanged;
  final VoidCallback? onPreview;
  final bool previewEnabled;
  final SpinnerModulationProps modulation;

  static const controlHeight = 48.0;

  static const _modes = <({int id, IconData icon, String label})>[
    (id: 0, icon: Icons.play_arrow_rounded, label: 'Shot'),
    (id: 1, icon: Icons.loop_rounded, label: 'Loop'),
    (id: 2, icon: Icons.replay_rounded, label: 'Rev'),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF121218),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ROOT',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.38),
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                SamplerRootKeyChip(
                  rootPitch: rootPitch,
                  accentColor: accentColor,
                  onChanged: onRootPitchChanged,
                  showFooterLabel: false,
                  fixedHeight: controlHeight,
                  modulation: modulation,
                ),
              ],
            ),
            const SizedBox(width: 6),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TUNE',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.38),
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                SamplerFineTuneChip(
                  rootFineTune: rootFineTune,
                  accentColor: accentColor,
                  onChanged: onRootFineTuneChanged,
                  fixedHeight: controlHeight,
                  modulation: modulation,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 6, 0),
              child: SizedBox(
                height: controlHeight,
                child: VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'PLAY',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.38),
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: controlHeight,
                    child: _PlaybackModeSegments(
                      playbackMode: playbackMode,
                      accentColor: accentColor,
                      onPlaybackModeChanged: onPlaybackModeChanged,
                    ),
                  ),
                ],
              ),
            ),
            if (onPreview != null)
              SizedBox(
                height: controlHeight,
                width: 40,
                child: IconButton(
                  tooltip: 'Preview at root key',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  onPressed: previewEnabled ? onPreview : null,
                  icon: Icon(
                    Icons.play_arrow_rounded,
                    size: 24,
                    color: previewEnabled ? accentColor : Colors.white24,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlaybackModeSegments extends StatelessWidget {
  const _PlaybackModeSegments({
    required this.playbackMode,
    required this.accentColor,
    required this.onPlaybackModeChanged,
  });

  final int playbackMode;
  final Color accentColor;
  final ValueChanged<int> onPlaybackModeChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF14141C),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < SamplerPlaybackIdentityBar._modes.length; i++) ...[
              if (i > 0)
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              Expanded(
                child: _PlaybackSegment(
                  selected: playbackMode == SamplerPlaybackIdentityBar._modes[i].id,
                  icon: SamplerPlaybackIdentityBar._modes[i].icon,
                  label: SamplerPlaybackIdentityBar._modes[i].label,
                  accentColor: accentColor,
                  onTap: () =>
                      onPlaybackModeChanged(SamplerPlaybackIdentityBar._modes[i].id),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlaybackSegment extends StatelessWidget {
  const _PlaybackSegment({
    required this.selected,
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accentColor.withValues(alpha: 0.2) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected ? accentColor : Colors.white38,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected ? accentColor : Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RootStepHit extends StatelessWidget {
  const _RootStepHit({
    required this.icon,
    required this.color,
    required this.onTap,
    this.expand = false,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: expand
            ? Center(child: Icon(icon, size: 14, color: color))
            : SizedBox(
                width: 46,
                height: 16,
                child: Center(child: Icon(icon, size: 14, color: color)),
              ),
      ),
    );
  }
}
