part of 'wavetable_synth_device_panel.dart';

extension _WavetableSynthDevicePanelStateEnvelopepanel
    on _WavetableSynthDevicePanelState {
  Widget _envelopePanel({
    required String title,
    required bool isFilter,
  }) {
    final attack = isFilter ? widget.device.filterAttack : widget.device.attack;
    final decay = isFilter ? widget.device.filterDecay : widget.device.decay;
    final sustain =
        isFilter ? widget.device.filterSustain : widget.device.sustain;
    final release =
        isFilter ? widget.device.filterRelease : widget.device.release;

    return _panelBox(
      padding: const EdgeInsets.fromLTRB(6, 5, 6, 5),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : WavetableSynthDevicePanel.designWidth;
          final compact = availableWidth < 350;
          final previewWidth = compact
              ? 76.0
              : (availableWidth * 0.30).clamp(96.0, 132.0).toDouble();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white30,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: previewWidth,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SamplerEnvelopePreview(
                          attack: attack,
                          decay: decay,
                          sustain: sustain,
                          release: release,
                          accent: WavetableSynthDevicePanel.accent,
                          label: isFilter ? 'FILTER' : 'AMP',
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Center(
                        child: _adsrRow(
                          attack: attack,
                          decay: decay,
                          sustain: sustain,
                          release: release,
                          spacing: compact ? 3 : 5,
                          onChanged: isFilter
                              ? (id, v) => widget.onParameterChanged(id, v)
                              : widget.onParameterChanged,
                          prefix: isFilter ? 'filter' : '',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
