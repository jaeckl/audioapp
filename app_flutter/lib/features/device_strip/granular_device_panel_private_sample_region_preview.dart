part of 'granular_device_panel.dart';

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
