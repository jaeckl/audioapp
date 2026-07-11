part of 'mood_fx_panels.dart';

class _StutterRateModeBox extends StatefulWidget {
  const _StutterRateModeBox({
    required this.sync,
    required this.rateBeats,
    required this.rateMs,
    required this.accent,
    required this.onSyncChanged,
    required this.onRateBeatsChanged,
    required this.onRateMsChanged,
  });

  final bool sync;
  final double rateBeats;
  final double rateMs;
  final Color accent;
  final ValueChanged<bool> onSyncChanged;
  final ValueChanged<double> onRateBeatsChanged;
  final ValueChanged<double> onRateMsChanged;

  @override
  State<_StutterRateModeBox> createState() => _StutterRateModeBoxState();
}
