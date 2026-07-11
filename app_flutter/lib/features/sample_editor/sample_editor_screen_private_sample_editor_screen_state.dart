part of 'sample_editor_screen.dart';

class _SampleEditorScreenState extends State<SampleEditorScreen>
    with TickerProviderStateMixin {
  late double start = widget.clip.sourceStart;
  late double end = widget.clip.sourceEnd;
  late double gain = widget.clip.gain;
  late double fadeIn = widget.clip.fadeIn;
  late double fadeOut = widget.clip.fadeOut;
  late double fadeInCurve = widget.clip.fadeInCurve;
  late double fadeOutCurve = widget.clip.fadeOutCurve;
  double pixelsPerBeat = 64;
  double zoomStart = 64;
  bool clipInteracting = false;
  bool pinchInteracting = false;
  _SampleTool tool = _SampleTool.navigate;
  SampleEditSnapSettings editSnap = const SampleEditSnapSettings();
  late bool reversed = widget.clip.reversed;
  late bool loopContent = widget.clip.loopContent;
  late bool warpRepitch = widget.clip.warpRepitch;
  late List<double> sliceMarkers = List.of(widget.clip.sliceMarkers);
  double transientSensitivity = .5;
  double sliceMinGap = .04;
  bool sliceReplaceExisting = true;
  _SliceAutoMode sliceAutoMode = _SliceAutoMode.transient;
  int sliceEvenDivisions = 8;
  SampleEditSnap sliceGridDivision = SampleEditSnap.sixteenth;
  int sliceFirstNote = 36;
  int? selectedSlice;
  int? selectedMarker;
  String? sliceStatus;
  late List<SampleClipTakeRegionSnapshot> takeRegions =
      List.of(widget.clip.activeTakeRegions);
  int? selectedTakeMarker;
  bool saving = false;
  late final ClipEditorTransportController transport;
  Timer? saveDebounce;

  double get _playbackContentLengthBeats =>
      widget.clip.playbackContentLengthBeats(
        sourceStart: start,
        sourceEnd: end,
        warpRepitch: warpRepitch,
      );

  List<double> get _displayWaveformPeaks {
    if (widget.clip.takes.isEmpty || takeRegions.isEmpty) {
      return widget.clip.waveformPeaks;
    }
    final samplesById = {
      for (final sample in widget.samples) sample.id: sample
    };
    final takesById = {for (final take in widget.clip.takes) take.id: take};
    final outputCount = math.max(widget.clip.waveformPeaks.length, 256);
    if (widget.clip.lengthBeats <= 0 || outputCount <= 1) {
      return widget.clip.waveformPeaks;
    }
    double peakAt(List<double> peaks, double position) {
      if (peaks.isEmpty) return 0;
      final source = position.clamp(0.0, 1.0) * (peaks.length - 1);
      final lo = source.floor();
      final hi = math.min(peaks.length - 1, lo + 1);
      final t = source - lo;
      return (peaks[lo] + (peaks[hi] - peaks[lo]) * t).abs();
    }

    final result = List<double>.filled(outputCount, 0);
    var regionIndex = 0;
    for (var i = 0; i < outputCount; i++) {
      final beat = i / (outputCount - 1) * widget.clip.lengthBeats;
      while (regionIndex + 1 < takeRegions.length &&
          beat >= takeRegions[regionIndex].endBeat) {
        regionIndex++;
      }
      final region = takeRegions[regionIndex];
      if (beat < region.startBeat || beat > region.endBeat) continue;
      final take = takesById[region.takeId];
      if (take == null || take.lengthBeats <= 0) continue;
      final sample = samplesById[take.sampleId];
      final sourceBeat = region.sourceStart + beat - region.startBeat;
      result[i] = peakAt(sample?.waveformPeaks ?? const [],
          sourceBeat / math.max(0.001, take.lengthBeats));
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    transport = ClipEditorTransportController(
        bridge: widget.bridge,
        clipStartBeat: widget.clip.startBeat,
        savedArrangementPlayhead: widget.savedArrangementPlayhead,
        vsync: this,
        maxClipBeat: widget.clip.playbackContentLengthBeats(
          sourceStart: start,
          sourceEnd: end,
          warpRepitch: warpRepitch,
        ));
    transport.addListener(_transportChanged);
    unawaited(widget.bridge.enterPlayMode());
  }

  @override
  void dispose() {
    saveDebounce?.cancel();
    transport.removeListener(_transportChanged);
    unawaited(transport.disposePreview());
    super.dispose();
  }

  List<double> get _takeMarkerBeats =>
      takeRegions.skip(1).map((region) => region.startBeat).toList();

  String get _snapLabel => editSnap.snap.shortLabel;

  @override
  Widget build(BuildContext context) => _buildContent(context);

}
