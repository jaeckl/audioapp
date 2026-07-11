part of 'subtractive_synth_device_panel.dart';

extension _SubtractiveSynthDevicePanelStateEnvelopepanel
    on _SubtractiveSynthDevicePanelState {
  Widget _envelopePanel({
    required String title,
    required double maxKnob,
    required double attack,
    required double decay,
    required double sustain,
    required double release,
    required void Function(String id, double value) onChanged,
    String prefix = '',
  }) {
    return _panelBox(
      variant: PanelVariant.screen,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white30,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          _adsrRow(
            attack: attack,
            decay: decay,
            sustain: sustain,
            release: release,
            onChanged: onChanged,
            prefix: prefix,
            knobScale: maxKnob,
            spacing: 6,
            labelGap: 0,
          ),
        ],
      ),
    );
  }
}
