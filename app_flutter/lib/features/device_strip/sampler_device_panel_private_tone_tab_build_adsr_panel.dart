part of 'sampler_device_panel.dart';

extension _ToneTabBuildadsrpanel on _ToneTab {
  Widget _buildAdsrPanel(bool editor) {
    const labels = ['A', 'D', 'S', 'R'];
    const labelStripHeight = 14.0;
    final maxKnob = editor ? DeviceKnobSizes.editor : DeviceKnobSizes.strip;

    final aegKnobs = <({
      String paramId,
      double value,
      String display,
      ValueChanged<double> onChanged
    })>[
      (
        paramId: 'attack',
        value: device.attack,
        display: SamplerDevicePanel.formatPercent(device.attack),
        onChanged: (v) => onParameterChanged('attack', v),
      ),
      (
        paramId: 'decay',
        value: device.decay,
        display: SamplerDevicePanel.formatPercent(device.decay),
        onChanged: (v) => onParameterChanged('decay', v),
      ),
      (
        paramId: 'sustain',
        value: device.sustain,
        display: SamplerDevicePanel.formatPercent(device.sustain),
        onChanged: (v) => onParameterChanged('sustain', v),
      ),
      (
        paramId: 'release',
        value: device.release,
        display: SamplerDevicePanel.formatPercent(device.release),
        onChanged: (v) => onParameterChanged('release', v),
      ),
    ];

    final fegKnobs = <({
      String paramId,
      double value,
      String display,
      ValueChanged<double> onChanged
    })>[
      (
        paramId: 'filterAttack',
        value: device.filterAttack,
        display: SamplerDevicePanel.formatPercent(device.filterAttack),
        onChanged: (v) => onParameterChanged('filterAttack', v),
      ),
      (
        paramId: 'filterDecay',
        value: device.filterDecay,
        display: SamplerDevicePanel.formatPercent(device.filterDecay),
        onChanged: (v) => onParameterChanged('filterDecay', v),
      ),
      (
        paramId: 'filterSustain',
        value: device.filterSustain,
        display: SamplerDevicePanel.formatPercent(device.filterSustain),
        onChanged: (v) => onParameterChanged('filterSustain', v),
      ),
      (
        paramId: 'filterRelease',
        value: device.filterRelease,
        display: SamplerDevicePanel.formatPercent(device.filterRelease),
        onChanged: (v) => onParameterChanged('filterRelease', v),
      ),
    ];

    Widget knobRow({
      required double knobSize,
      required List<
              ({
                String paramId,
                double value,
                String display,
                ValueChanged<double> onChanged
              })>
          specs,
      Color accentColor = SamplerDevicePanel.accent,
    }) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final fitSize = math
              .min(
                knobSize,
                math.min(
                    constraints.maxHeight - 2, constraints.maxWidth / 4 - 2),
              )
              .clamp(28.0, maxKnob);
          return Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final spec in specs)
                    _knob(
                      label: spec.paramId,
                      paramId: spec.paramId,
                      value: spec.value,
                      displayValue: spec.display,
                      onChanged: spec.onChanged,
                      size: fitSize,
                      showLabel: false,
                      accentColor: accentColor,
                    ),
                ],
              ),
            ),
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final rowHeight = (constraints.maxHeight - labelStripHeight) / 2;
        final colWidth = constraints.maxWidth / 4;
        final knobSize =
            (math.min(rowHeight, colWidth) - 6).clamp(28.0, maxKnob);

        return ClipRect(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: rowHeight,
                child: knobRow(knobSize: knobSize, specs: aegKnobs),
              ),
              const SizedBox(
                height: labelStripHeight,
                child: _AdsrLabelStrip(labels: labels),
              ),
              SizedBox(
                height: rowHeight,
                child: knobRow(
                    knobSize: knobSize,
                    specs: fegKnobs,
                    accentColor: SamplerDevicePanel.wave),
              ),
            ],
          ),
        );
      },
    );
  }
}
