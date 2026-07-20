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
  Widget build(BuildContext context) => KeyedSubtree(
        key: const ValueKey('phaser-preview'),
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
          builder: (context, liveValues) => IgnorePointer(
            child: CustomPaint(
              painter: _PhaserPreviewPainter(
                device: device,
                view: view,
                liveValues: liveValues,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );
}
