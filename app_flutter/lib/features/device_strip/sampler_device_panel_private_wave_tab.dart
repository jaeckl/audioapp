part of 'sampler_device_panel.dart';

class _WaveTab extends StatelessWidget {
  const _WaveTab({
    required this.device,
    required this.sampleName,
    required this.peaks,
    required this.durationSec,
    required this.onParameterChanged,
    this.onPreview,
    this.onLoadSample,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
    this.lfos = const [],
    this.modEdges = const [],
  });

  final SamplerDeviceSnapshot device;
  final String? sampleName;
  final List<double> peaks;
  final double durationSec;
  final void Function(String parameterId, double value) onParameterChanged;
  final VoidCallback? onPreview;
  final VoidCallback? onLoadSample;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final void Function(String paramId, double amount)? onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;
  final List<LfoSnapshot> lfos;
  final List<ModulationEdgeSnapshot> modEdges;

  SpinnerModulationProps get _spinnerModulation => SpinnerModulationProps(
        modulatedParams: modulatedParams,
        automatedParams: automatedParams,
        modulationAmounts: modulationAmounts,
        connectModeLfoId: connectModeLfoId,
        onModulationAssign: onModulationAssign,
        automationLinkActive: automationLinkActive,
        onAutomationLinkTap: onAutomationLinkTap,
        onAutomateParameter: onAutomateParameter,
        rootPitchPolarity: modulatorPolarityForParam(
          paramId: 'rootPitch',
          deviceId: device.id,
          modEdges: modEdges,
          lfos: lfos,
          connectModeLfoId: connectModeLfoId,
        ),
        rootFineTunePolarity: modulatorPolarityForParam(
          paramId: 'rootFineTune',
          deviceId: device.id,
          modEdges: modEdges,
          lfos: lfos,
          connectModeLfoId: connectModeLfoId,
        ),
      );

  void _setPlaybackMode(int mode) {
    onParameterChanged('playbackMode', mode.toDouble());
    if (mode == 1 && device.regionEndSec <= 0) {
      final dur = durationSec > 0 ? durationSec : 1.0;
      onParameterChanged('regionStartSec', 0);
      onParameterChanged('regionEndSec', (dur * 0.25).clamp(0.05, dur));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF121218),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: SamplerWaveformView(
                  peaks: peaks,
                  durationSec: durationSec,
                  trimStartSec: device.trimStartSec,
                  trimEndSec: device.trimEndSec,
                  regionStartSec: device.regionStartSec,
                  regionEndSec: device.regionEndSec,
                  density: SamplerWaveformDensity.editor,
                  waveColor: SamplerDevicePanel.wave,
                  accentColor: SamplerDevicePanel.accent,
                  loopRegionEnabled: device.playbackMode == 1,
                  onPreview: peaks.isEmpty ? null : onPreview,
                  onLoadSample: onLoadSample,
                  onTrimChanged: (start, end) {
                    onParameterChanged('trimStartSec', start);
                    onParameterChanged('trimEndSec', end);
                  },
                  onRegionChanged: device.playbackMode == 1
                      ? (start, end) {
                          onParameterChanged('regionStartSec', start);
                          onParameterChanged('regionEndSec', end);
                        }
                      : null,
                  emptyHint:
                      'Choose a sample from your library or import audio',
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: onLoadSample == null
                  ? Text(
                      sampleName ?? 'No sample',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onLoadSample,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  sampleName ?? 'No sample',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.folder_open_rounded,
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.38),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
            if (peaks.isNotEmpty)
              Text(
                formatSamplerPlaybackRange(
                  playbackMode: device.playbackMode,
                  durationSec: durationSec,
                  trimStartSec: device.trimStartSec,
                  trimEndSec: device.trimEndSec,
                  regionStartSec: device.regionStartSec,
                  regionEndSec: device.regionEndSec,
                ),
                style:
                    theme.textTheme.labelSmall?.copyWith(color: Colors.white38),
              ),
          ],
        ),
        const SizedBox(height: 4),
        SamplerPlaybackIdentityBar(
          rootPitch: device.rootPitch.round(),
          rootFineTune: device.rootFineTune,
          playbackMode: device.playbackMode,
          accentColor: SamplerDevicePanel.accent,
          previewEnabled: peaks.isNotEmpty,
          onRootPitchChanged: (pitch) =>
              onParameterChanged('rootPitch', pitch.toDouble()),
          onRootFineTuneChanged: (cents) =>
              onParameterChanged('rootFineTune', cents),
          onPlaybackModeChanged: _setPlaybackMode,
          onPreview: onPreview,
          modulation: _spinnerModulation,
        ),
      ],
    );
  }
}
