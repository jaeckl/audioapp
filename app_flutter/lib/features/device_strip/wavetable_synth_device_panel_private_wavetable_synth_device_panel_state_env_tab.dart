part of 'wavetable_synth_device_panel.dart';

extension _WavetableSynthDevicePanelStateEnvtab
    on _WavetableSynthDevicePanelState {
  Widget _envTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight =
              constraints.maxHeight.isFinite ? constraints.maxHeight : 240.0;
          final gap = availableHeight < 230 ? 4.0 : 6.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                  child: _envelopePanel(title: 'AMP ENV', isFilter: false)),
              SizedBox(height: gap),
              Expanded(
                  child: _envelopePanel(title: 'FILTER ENV', isFilter: true)),
            ],
          );
        },
      ),
    );
  }
}
