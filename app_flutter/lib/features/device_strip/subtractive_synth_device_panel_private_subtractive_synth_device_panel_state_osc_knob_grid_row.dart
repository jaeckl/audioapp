part of 'subtractive_synth_device_panel.dart';

extension _SubtractiveSynthDevicePanelStateOscknobgridrow
    on _SubtractiveSynthDevicePanelState {
  Widget _oscKnobGridRow({
    required double knobScale,
    required List<Widget?> slots,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final slot in slots)
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: slot == null
                  ? const SizedBox.shrink()
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: slot,
                    ),
            ),
          ),
      ],
    );
  }
}
