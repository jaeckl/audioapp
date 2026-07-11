part of 'transport_bar.dart';

class _SnapGridMenuState extends State<_SnapGridMenu> {
  late bool _snapClips = widget.snapClips;
  late SnapGridResolution _resolution = widget.resolution;
  late bool _triplet = widget.triplet;

  void _setSnapClips(bool enabled) {
    setState(() => _snapClips = enabled);
    widget.onSnapClipsChanged(enabled);
  }

  void _setResolution(SnapGridResolution resolution) {
    setState(() => _resolution = resolution);
    widget.onResolutionChanged(resolution);
  }

  void _setTriplet(bool triplet) {
    setState(() => _triplet = triplet);
    widget.onTripletChanged(triplet);
  }

  Widget _pill({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Material(
      color: active
          ? TransportBarTheme.menuPillActiveFill
          : TransportBarTheme.menuPillIdle,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active
                  ? TransportBarTheme.menuPillActiveText
                  : TransportBarTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolutions = SnapGridResolution.values.skip(1).toList();
    return SizedBox(
      width: 260,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Grid',
            style: TextStyle(
              color: TransportBarTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          const _SnapGridSectionTitle('Clip snap'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _pill(
                  label: 'Off',
                  active: !_snapClips,
                  onTap: () => _setSnapClips(false),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _pill(
                  label: 'On',
                  active: _snapClips,
                  onTap: () => _setSnapClips(true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _SnapGridSectionTitle('Resolution'),
          const SizedBox(height: 8),
          _pill(
            label: 'Adaptive',
            active: _resolution == SnapGridResolution.adaptive,
            onTap: () => _setResolution(SnapGridResolution.adaptive),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final resolution in resolutions)
                _pill(
                  label: resolution.label,
                  active: _resolution == resolution,
                  onTap: () => _setResolution(resolution),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const _SnapGridSectionTitle('Triplet'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _pill(
                  label: 'Straight',
                  active: !_triplet,
                  onTap: () => _setTriplet(false),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _pill(
                  label: 'Triplets',
                  active: _triplet,
                  onTap: () => _setTriplet(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
