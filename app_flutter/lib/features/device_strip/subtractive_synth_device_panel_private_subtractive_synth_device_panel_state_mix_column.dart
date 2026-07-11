part of 'subtractive_synth_device_panel.dart';

extension _SubtractiveSynthDevicePanelStateMixcolumn
    on _SubtractiveSynthDevicePanelState {
  Widget _mixColumn({
    required String title,
    required Widget row1,
    required Widget row2,
    required Widget row3,
  }) {
    return Expanded(
      child: _panelBox(
        variant: PanelVariant.elevated,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Column(
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
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [row1, row2, row3],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
