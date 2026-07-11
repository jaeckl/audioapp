part of 'transport_bar.dart';

class _SnapGridMenu extends StatefulWidget {
  const _SnapGridMenu({
    required this.snapClips,
    required this.resolution,
    required this.triplet,
    required this.onSnapClipsChanged,
    required this.onResolutionChanged,
    required this.onTripletChanged,
  });

  final bool snapClips;
  final SnapGridResolution resolution;
  final bool triplet;
  final ValueChanged<bool> onSnapClipsChanged;
  final ValueChanged<SnapGridResolution> onResolutionChanged;
  final ValueChanged<bool> onTripletChanged;

  @override
  State<_SnapGridMenu> createState() => _SnapGridMenuState();
}
