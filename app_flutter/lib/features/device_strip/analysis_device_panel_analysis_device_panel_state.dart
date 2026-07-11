part of 'analysis_device_panel.dart';

class _AnalysisDevicePanelState extends State<AnalysisDevicePanel> {
  bool _frozen = false;
  DeviceMeterReading? _held;
  DeviceMeterReading? _displayReading;
  double _integrated = -70;
  int _samples = 0;

  @override
  void didUpdateWidget(covariant AnalysisDevicePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final reading = widget.reading;
    if (!_frozen && reading != null) {
      _displayReading = _smooth(_displayReading, reading);
      _held = _displayReading;
    }
    if (widget.type == 'loudness_meter' &&
        reading != null &&
        reading.loudnessLufs > -69) {
      _integrated =
          (_integrated * _samples + reading.loudnessLufs) / (_samples + 1);
      _samples++;
    }
  }

  DeviceMeterReading _smooth(
      DeviceMeterReading? previous, DeviceMeterReading next) {
    if (previous == null) return next;
    double lerp(double a, double b, double amount) => a + (b - a) * amount;
    final wave = <double>[
      for (var i = 0; i < next.waveform.length; i++)
        lerp(i < previous.waveform.length ? previous.waveform[i] : 0.0,
            next.waveform[i], .55),
    ];
    final spectrum = <double>[
      for (var i = 0; i < next.spectrum.length; i++)
        (() {
          final old = i < previous.spectrum.length ? previous.spectrum[i] : 0.0;
          return lerp(
              old, next.spectrum[i], next.spectrum[i] >= old ? .65 : .16);
        })(),
    ];
    return DeviceMeterReading(
      deviceId: next.deviceId,
      gainReductionDb: next.gainReductionDb,
      inputLevel: next.inputLevel >= previous.inputLevel
          ? next.inputLevel
          : previous.inputLevel * .88,
      loudnessLufs: lerp(previous.loudnessLufs, next.loudnessLufs, .28),
      correlation: lerp(previous.correlation, next.correlation, .25),
      waveform: wave,
      spectrum: spectrum,
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = DeviceStripTheme.accentForDeviceType(widget.type);
    final reading = _frozen ? _held : (_displayReading ?? widget.reading);
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
        child: Column(children: [
          Expanded(
              child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: CustomPaint(
              painter: _AnalysisPainter(
                  type: widget.type,
                  reading: reading,
                  accent: accent,
                  integrated: _integrated),
              child: const SizedBox.expand(),
            ),
          )),
          const SizedBox(height: 6),
          SizedBox(
              height: 30,
              child: Row(children: [
                _chip(
                    widget.type == 'spectrum_analyzer'
                        ? 'SMOOTH'
                        : widget.type == 'loudness_meter'
                            ? 'RESET'
                            : 'FREEZE',
                    onTap: () => setState(() {
                          if (widget.type == 'loudness_meter') {
                            _integrated = -70;
                            _samples = 0;
                          } else {
                            _frozen = !_frozen;
                            if (_frozen) _held = widget.reading;
                          }
                        }),
                    active: _frozen),
                const Spacer(),
                Text(_status(reading),
                    style: TextStyle(
                        color: accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ])),
        ]),
      ),
    );
  }

  String _status(DeviceMeterReading? r) => switch (widget.type) {
        'oscilloscope' => '±1.0',
        'spectrum_analyzer' => '20 Hz — 20 kHz',
        'loudness_meter' => '${r?.loudnessLufs.toStringAsFixed(1) ?? '—'} LUFS',
        _ => 'CORR ${r?.correlation.toStringAsFixed(2) ?? '—'}',
      };

  Widget _chip(String text,
          {required VoidCallback onTap, bool active = false}) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9),
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: active
                    ? Colors.white12
                    : Colors.white.withValues(alpha: .04),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white12)),
            child: Text(text,
                style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 9,
                    fontWeight: FontWeight.w700))),
      );
}
