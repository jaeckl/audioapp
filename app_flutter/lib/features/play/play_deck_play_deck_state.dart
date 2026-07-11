part of 'play_deck.dart';

class PlayDeckState extends State<PlayDeck> {
  late PlaySurfaceMode _surfaceMode;
  PlayContextView _view = PlayContextView.perform;
  late int _octaveOffset;
  int _keyboardRows = PlayDeckLayout.defaultKeyboardRows;
  int _padBank = 0;
  String _scaleId = PlayScale.major.id;
  bool _inKeyOnly = true;

  ChordQuality _chord = ChordQuality.major;
  ArpMode _arp = ArpMode.off;
  int _octaveSpan = 1;
  int _rateMs = 130;
  int _activeRootOffset = 0;
  final Set<int> _highlightedPitches = {};

  VelocityCurve _velocityCurve = VelocityCurve.linear;
  CaptureQuantize _quantize = CaptureQuantize.quarter;
  final bool _padChokeByColumn = true;
  final bool _padChokeByRow = false;

  bool _latch = false;
  bool _sustain = false;
  bool _repeat = false;
  bool _metronome = false;
  final List<ChordMemory> _chordMemory = [
    ChordMemory(label: 'Maj', quality: ChordQuality.major),
    ChordMemory(label: 'Min', quality: ChordQuality.minor),
    ChordMemory(label: '7', quality: ChordQuality.seventh),
    ChordMemory(label: 'm7', quality: ChordQuality.minor7),
  ];

  final List<PlayScale> _customScales = [];

  double _modulation = 0.0;
  double _pitchBend = 0.0;


  bool get latch => _latch;
  bool get metronome => _metronome;
  CaptureQuantize get quantize => _quantize;

  int get _octaveDisplay => (2 + _octaveOffset).clamp(-2, 8);

  @override
  void initState() {
    super.initState();
    _surfaceMode = widget.initialSurfaceMode ?? PlaySurfaceMode.keys;
    _octaveOffset = widget.initialOctaveOffset;
  }

  @override
  void didUpdateWidget(covariant PlayDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSurfaceMode != null && widget.initialSurfaceMode != oldWidget.initialSurfaceMode) {
      _surfaceMode = widget.initialSurfaceMode!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = PlayScale.byId(_scaleId, custom: _customScales);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showModStrip) ModStrip(modulation: _modulation, pitchBend: _pitchBend),
        ColoredBox(
          color: PlayDeckTheme.deckBackground,
          child: SizedBox(
            height: PlayDeckLayout.deckHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PlayDeckRail(
                  surfaceMode: _surfaceMode,
                  activeView: _view,
                  octaveDisplay: _octaveDisplay,
                  enabled: widget.enabled,
                  onSurfaceModeChanged: _onSurfaceModeChanged,
                  onViewChanged: _onViewChanged,
                ),
                Expanded(child: _buildContextArea(scale)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
