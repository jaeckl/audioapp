part of 'device_vu_meter.dart';

class _DeviceVuMeterState extends State<DeviceVuMeter>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _displayLevel = 0;
  final _rng = math.Random(7);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    if (widget.active) _ticker.start();
  }

  @override
  void didUpdateWidget(DeviceVuMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_ticker.isActive) {
      _ticker.start();
    } else if (!widget.active && _ticker.isActive) {
      _ticker.stop();
      if (_displayLevel > 0.02) {
        setState(() => _displayLevel = 0.02);
      }
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    final target = widget.active
        ? (widget.level > 0
            ? widget.level.clamp(0.0, 1.0)
            : (0.18 + _rng.nextDouble() * 0.55) * widget.gain.clamp(0.0, 1.0))
        : 0.02;
    final next = _displayLevel + (target - _displayLevel) * 0.28;
    if ((next - _displayLevel).abs() > 0.002) {
      setState(() => _displayLevel = next.clamp(0.0, 1.0));
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DeviceVuMeterPainter(level: _displayLevel),
      child: const SizedBox.expand(),
    );
  }
}
