part of 'oscillator_device_panel.dart';

class OscillatorDeviceStripCollapsed extends StatelessWidget {
  const OscillatorDeviceStripCollapsed({
    super.key,
    required this.onExpand,
    this.embeddedInCard = false,
  });

  final VoidCallback onExpand;
  final bool embeddedInCard;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: embeddedInCard ? Colors.transparent : OscillatorDevicePanel.panel,
      child: Padding(
        padding: EdgeInsets.fromLTRB(embeddedInCard ? 10 : 0, 4, 8, 4),
        child: Row(
          children: [
            if (!embeddedInCard)
              Container(
                  width: 4,
                  height: double.infinity,
                  color: OscillatorDevicePanel.accent),
            if (!embeddedInCard) const SizedBox(width: 10),
            const Spacer(),
            IconButton(
              tooltip: 'Expand device',
              onPressed: onExpand,
              icon: const Icon(Icons.unfold_more,
                  size: 20, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}
