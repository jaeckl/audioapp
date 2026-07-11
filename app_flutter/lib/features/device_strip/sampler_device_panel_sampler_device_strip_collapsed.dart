part of 'sampler_device_panel.dart';

class SamplerDeviceStripCollapsed extends StatelessWidget {
  const SamplerDeviceStripCollapsed({
    super.key,
    required this.sample,
    required this.onExpand,
    this.embeddedInCard = false,
  });

  final SampleLibraryEntrySnapshot? sample;
  final VoidCallback onExpand;
  final bool embeddedInCard;

  @override
  Widget build(BuildContext context) {
    final peaks = sample?.waveformPeaks ?? const <double>[];

    return Material(
      color: embeddedInCard ? Colors.transparent : SamplerDevicePanel.panel,
      child: Padding(
        padding: EdgeInsets.fromLTRB(embeddedInCard ? 10 : 0, 4, 8, 4),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 36,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF121218),
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: peaks.isEmpty
                      ? null
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: CustomPaint(
                            painter: WaveformPainter(
                              peaks: peaks,
                              color: SamplerDevicePanel.wave,
                            ),
                          ),
                        ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Expand device',
              visualDensity: VisualDensity.compact,
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
