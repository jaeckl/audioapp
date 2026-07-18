part of 'time_fx_panels.dart';

class _PhaserPreview extends StatelessWidget {
  const _PhaserPreview({
    required this.device,
    required this.view,
    required this.automatedParams,
  });

  final PhaserDeviceSnapshot device;
  final PhaserViewTab view;
  final Set<String> automatedParams;

  @override
  Widget build(BuildContext context) => Container(
        key: const ValueKey('phaser-preview'),
        decoration: BoxDecoration(
          color: const Color(0xFF050508),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white10),
        ),
        child: EffectiveParameterValuesBuilder(
          fallbackValues: {
            'waveform': device.phaserWaveform / 3,
            'stereoPhase': device.phaserStereoPhase,
            'phaseOffset': device.phaserPhaseOffset,
            'stages': ((device.phaserStages - 2) / 10).clamp(0, 1),
            'centreFrequencyHz':
                math.log(device.phaserCentreFrequencyHz.clamp(20, 20000) / 20) /
                    math.log(1000),
            'depth': device.phaserDepth,
          },
          activeParameterIds: automatedParams,
          builder: (context, liveValues) => CustomPaint(
            painter: _PhaserPreviewPainter(
              device: device,
              view: view,
              liveValues: liveValues,
            ),
          ),
        ),
      );
}
