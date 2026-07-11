part of 'sampler_waveform_view.dart';

class _SamplerWaveformViewState extends State<SamplerWaveformView> {
  /// Visible handle width (bar + grip).

  /// Touch target radius — generous pickup on mobile.

  bool get _loopActive => _localRegionEnd > 0;

  late double _localTrimStart;
  late double _localTrimEnd;
  late double _localRegionStart;
  late double _localRegionEnd;
  _WaveformDrag? _drag;

  bool get _showTrimHandles => widget.onTrimChanged != null && !widget.loopRegionEnabled;

  bool get _showLoopHandles {
    if (widget.loopRegionEnabled) {
      return _loopActive || _drag?.affectsRegion == true;
    }
    return !_editor && widget.onRegionChanged != null && _loopActive;
  }

  bool get _showLoopBand => _showLoopHandles;


  bool get _editor => widget.density == SamplerWaveformDensity.editor;

  double get _dur => widget.durationSec > 0 ? widget.durationSec : 1.0;

  double get _trimStart => _drag != null && _drag!.affectsTrim ? _localTrimStart : widget.trimStartSec;
  double get _trimEnd => _drag != null && _drag!.affectsTrim ? _localTrimEnd : (widget.trimEndSec > 0 ? widget.trimEndSec : _dur);
  double get _regionStart => _drag != null && _drag!.affectsRegion ? _localRegionStart : widget.regionStartSec;
  double get _regionEnd => _drag != null && _drag!.affectsRegion ? _localRegionEnd : widget.regionEndSec;

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

  /// Left-boundary handle sits immediately to the right of [boundaryX].
  /// Right-boundary handle sits immediately to the left of [boundaryX].
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
                onHorizontalDragStart: (d) => _onDragStart(d.localPosition.dx, d.localPosition.dy, w, h),
                onHorizontalDragUpdate: (d) => _onDragUpdate(d.localPosition.dx, w),
                onHorizontalDragEnd: (_) => _onDragEnd(),
                onTapUp: widget.showLoopBand && !widget.hasLoop && widget.onRegionChanged != null ? (d) => _createRegionAt(_secFromDx(d.localPosition.dx, w)) : null,
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
                        detail: '${formatSamplerDurationSec(_trimStart)} – ${formatSamplerDurationSec(_trimEnd)}',
                        color: widget.waveColor,
                      ),
                    if (_showLoopHandles && widget.onRegionChanged != null)
                      Expanded(
                        child: _LegendChip(
                          label: 'LOOP',
                          detail: '${formatSamplerDurationSec(_regionStart)} – ${formatSamplerDurationSec(_regionEnd)}',
                          color: widget.accentColor,
                          onClear: widget.loopRegionEnabled ? () => widget.onRegionChanged!(0, 0) : null,
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
