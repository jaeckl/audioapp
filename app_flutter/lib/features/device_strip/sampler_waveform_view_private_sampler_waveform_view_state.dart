part of 'sampler_waveform_view.dart';

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
    _localTrimEnd = widget.trimEndSec > 0
        ? widget.trimEndSec.clamp(_localTrimStart + _minSpanSec, _dur)
        : _dur;
    _localRegionStart = widget.regionStartSec.clamp(0, _dur - _minSpanSec);
    _localRegionEnd = widget.regionEndSec > 0
        ? widget.regionEndSec.clamp(_localRegionStart + _minSpanSec, _dur)
        : 0;
  }

  double _secFromDx(double dx, double width) =>
      (dx / width * _dur).clamp(0, _dur);

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

  void _commitTrim() =>
      widget.onTrimChanged?.call(_localTrimStart, _localTrimEnd);

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
        consider(_WaveformDrag.trimStart,
            (x - (trimStartX + _handleVisualWidth / 2)).abs());
      }
      if (_hitRightHandle(x, y, trimEndX, width, height, yMin, yMax)) {
        consider(_WaveformDrag.trimEnd,
            (x - (trimEndX - _handleVisualWidth / 2)).abs());
      }
    }

    if (_showLoopHandles) {
      final regionStartX = _regionStart / _dur * width;
      final regionEndX = _regionEnd / _dur * width;
      if (_hitLeftHandle(x, y, regionStartX, width, height, yMin, yMax)) {
        consider(_WaveformDrag.regionStart,
            (x - (regionStartX + _handleVisualWidth / 2)).abs());
      }
      if (_hitRightHandle(x, y, regionEndX, width, height, yMin, yMax)) {
        consider(_WaveformDrag.regionEnd,
            (x - (regionEndX - _handleVisualWidth / 2)).abs());
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
                onHorizontalDragUpdate: (d) =>
                    _onDragUpdate(d.localPosition.dx, w),
                onHorizontalDragEnd: (_) => _onDragEnd(),
                onTapUp: widget.showLoopBand &&
                        !widget.hasLoop &&
                        widget.onRegionChanged != null
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
                                  color: widget.accentColor
                                      .withValues(alpha: 0.75),
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
