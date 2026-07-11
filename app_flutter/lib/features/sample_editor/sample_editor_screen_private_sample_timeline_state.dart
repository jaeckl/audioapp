part of 'sample_editor_screen.dart';

class _SampleTimelineState extends State<_SampleTimeline> {
  static const _preRollBeats = 8.0;
  static const _waveformInsetH = 0.0;
  final ScrollController _scroll = ScrollController();
  double? _dragPlayheadBeat;
  bool _draggingPlayhead = false;
  double? _dragSliceValue;
  double? _dragTakeMarkerBeat;

  double get _sourceSpan => math.max(.001, widget.end - widget.start);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        _scroll.jumpTo(_preRollBeats * widget.pixelsPerBeat);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _SampleTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pixelsPerBeat == widget.pixelsPerBeat ||
        !_scroll.hasClients) {
      return;
    }
    final oldOrigin = _preRollBeats * oldWidget.pixelsPerBeat;
    final relativeBeat = (_scroll.offset - oldOrigin) / oldWidget.pixelsPerBeat;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final target = (_preRollBeats + relativeBeat) * widget.pixelsPerBeat;
      _scroll.jumpTo(target.clamp(0.0, _scroll.position.maxScrollExtent));
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildContent(context);

}
