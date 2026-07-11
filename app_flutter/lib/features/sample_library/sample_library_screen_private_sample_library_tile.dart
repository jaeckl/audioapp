part of 'sample_library_screen.dart';

class _SampleLibraryTile extends StatelessWidget {
  const _SampleLibraryTile({
    required this.sample,
    required this.onPreview,
    required this.onInsert,
  });

  final SampleLibraryEntrySnapshot sample;
  final VoidCallback onPreview;
  final VoidCallback onInsert;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1A1A22),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onInsert,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 96,
                height: 36,
                child: CustomPaint(
                  painter: _WaveformPainter(peaks: sample.waveformPeaks),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sample.name,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      sample.source == 'bundled' ? 'Bundled' : 'Imported',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Preview',
                onPressed: onPreview,
                icon:
                    const Icon(Icons.play_arrow_rounded, color: Colors.white70),
              ),
              FilledButton.tonal(
                onPressed: onInsert,
                child: const Text('Insert'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
