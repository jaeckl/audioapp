part of 'live_instrument_panel.dart';

class _LiveInstrumentPanelState extends State<LiveInstrumentPanel> {
  GlobalKey<PlayDeckState> _deckKey = GlobalKey();
  PlaySurfaceMode? _preferredSurfaceMode;

  @override
  void initState() {
    super.initState();
    _syncModeFromTrack();
  }

  @override
  void didUpdateWidget(covariant LiveInstrumentPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.snapshot.selectedTrackId != widget.snapshot.selectedTrackId) {
      _deckKey = GlobalKey();
      _syncModeFromTrack();
      setState(() {});
    }
  }

  void _syncModeFromTrack() {
    final track = widget.snapshot.selectedTrack;
    PlaySurfaceMode? mode;
    if (track?.oscillatorDevice != null) {
      mode = PlaySurfaceMode.keys;
    } else if (track?.samplerDevice != null) {
      mode = PlaySurfaceMode.pads;
    }
    if (mode != _preferredSurfaceMode) {
      setState(() => _preferredSurfaceMode = mode);
      _deckKey.currentState?.setSurfaceMode(mode ?? PlaySurfaceMode.pads);
    }
  }

  Future<void> _setRecordArmed(bool armed) async {
    try {
      await widget.onRecordArmed(armed);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.snapshot.selectedTrack;
    final hasTrack = track != null;
    final armed = widget.snapshot.recordArmed;
    final deck = _deckKey.currentState;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasTrack)
          _CaptureStrip(
            armed: armed,
            recordWriteMode: widget.recordWriteMode,
            quantize: deck?.quantize ?? CaptureQuantize.quarter,
            latch: deck?.latch ?? false,
            metronome: deck?.metronome ?? false,
            onArmToggle: () => _setRecordArmed(!armed),
            onRecordWriteModeChanged: widget.onRecordWriteModeChanged,
            onLatchToggle: () {
              _deckKey.currentState?.toggleLatch();
              setState(() {});
            },
            onMetronomeToggle: () {
              _deckKey.currentState?.toggleMetronome();
              setState(() {});
            },
          ),
        PlayDeck(
          key: _deckKey,
          bridge: widget.bridge,
          enabled: hasTrack,
          showModStrip: hasTrack,
          initialSurfaceMode: _preferredSurfaceMode,
          padPitchBase: track?.drumAnchorPitch,
          onPerformanceChanged: () => setState(() {}),
        ),
      ],
    );
  }
}
