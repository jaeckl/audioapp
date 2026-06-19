import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';

class SampleLibraryScreen extends StatelessWidget {
  const SampleLibraryScreen({
    super.key,
    this.embedded = false,
    this.embeddedTitle,
    required this.samples,
    required this.onPreview,
    required this.onInsert,
    required this.onImport,
  });

  final bool embedded;
  final String? embeddedTitle;
  final List<SampleLibraryEntrySnapshot> samples;
  final ValueChanged<SampleLibraryEntrySnapshot> onPreview;
  final ValueChanged<SampleLibraryEntrySnapshot> onInsert;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final list = samples.isEmpty
        ? Center(
            child: Text(
              'No samples yet',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white38),
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: samples.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final sample = samples[index];
              return _SampleLibraryTile(
                sample: sample,
                onPreview: () => onPreview(sample),
                onInsert: () => onInsert(sample),
              );
            },
          );

    if (embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
            child: Row(
              children: [
                Text(embeddedTitle ?? 'Library', style: theme.textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  tooltip: 'Import audio',
                  onPressed: onImport,
                  icon: const Icon(Icons.upload_file_outlined),
                ),
              ],
            ),
          ),
          Expanded(child: list),
        ],
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A22),
        title: const Text('Sample library'),
        actions: [
          IconButton(
            tooltip: 'Import audio',
            onPressed: onImport,
            icon: const Icon(Icons.upload_file_outlined),
          ),
        ],
      ),
      body: list,
    );
  }
}

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
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      sample.source == 'bundled' ? 'Bundled' : 'Imported',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Preview',
                onPressed: onPreview,
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.white70),
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

class WaveformPainter extends CustomPainter {
  const WaveformPainter({
    required this.peaks,
    this.color = const Color(0xFF7EB6FF),
    this.durationSec,
    this.trimStartSec,
    this.trimEndSec,
    this.dimOutsideTrim = false,
    this.outsideTrimOpacity = 0.35,
  });

  final List<double> peaks;
  final Color color;
  /// When set with [dimOutsideTrim], peak X positions follow sample time.
  final double? durationSec;
  final double? trimStartSec;
  final double? trimEndSec;
  final bool dimOutsideTrim;
  final double outsideTrimOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (peaks.isEmpty) {
      return;
    }
    final midY = size.height / 2;
    final useTimeline = dimOutsideTrim && durationSec != null && durationSec! > 0;
    final dur = useTimeline ? durationSec! : 1.0;
    final trimStart = trimStartSec ?? 0.0;
    final trimEnd = trimEndSec != null && trimEndSec! > 0 ? trimEndSec! : dur;

    final paint = Paint()
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    if (!useTimeline) {
      paint.color = color;
      final step = size.width / peaks.length;
      for (var i = 0; i < peaks.length; i++) {
        final peak = peaks[i].clamp(0.0, 1.0);
        final x = i * step + step / 2;
        final half = peak * midY;
        canvas.drawLine(Offset(x, midY - half), Offset(x, midY + half), paint);
      }
      return;
    }

    for (var i = 0; i < peaks.length; i++) {
      final peak = peaks[i].clamp(0.0, 1.0);
      final timeSec = (i + 0.5) / peaks.length * dur;
      final x = timeSec / dur * size.width;
      final inTrim = timeSec >= trimStart && timeSec <= trimEnd;
      paint.color = color.withValues(alpha: inTrim ? 1.0 : outsideTrimOpacity);
      final half = peak * midY;
      canvas.drawLine(Offset(x, midY - half), Offset(x, midY + half), paint);
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.peaks != peaks ||
        oldDelegate.color != color ||
        oldDelegate.durationSec != durationSec ||
        oldDelegate.trimStartSec != trimStartSec ||
        oldDelegate.trimEndSec != trimEndSec ||
        oldDelegate.dimOutsideTrim != dimOutsideTrim ||
        oldDelegate.outsideTrimOpacity != outsideTrimOpacity;
  }
}

class _WaveformPainter extends WaveformPainter {
  const _WaveformPainter({required super.peaks});
}

/// Bottom-sheet sample picker with live refresh after import.
class SampleLibraryPickerSheet extends StatefulWidget {
  const SampleLibraryPickerSheet({
    super.key,
    required this.initialSamples,
    required this.onPreview,
    required this.onImportSamples,
    required this.onSampleSelected,
  });

  final List<SampleLibraryEntrySnapshot> initialSamples;
  final ValueChanged<SampleLibraryEntrySnapshot> onPreview;
  final Future<List<SampleLibraryEntrySnapshot>> Function() onImportSamples;
  final ValueChanged<SampleLibraryEntrySnapshot> onSampleSelected;

  @override
  State<SampleLibraryPickerSheet> createState() => _SampleLibraryPickerSheetState();
}

class _SampleLibraryPickerSheetState extends State<SampleLibraryPickerSheet> {
  late List<SampleLibraryEntrySnapshot> _samples;

  @override
  void initState() {
    super.initState();
    _samples = widget.initialSamples;
  }

  Future<void> _import() async {
    final updated = await widget.onImportSamples();
    if (!mounted) return;
    setState(() => _samples = updated);
  }

  @override
  Widget build(BuildContext context) {
    return SampleLibraryScreen(
      embedded: true,
      embeddedTitle: 'Insert sample',
      samples: _samples,
      onPreview: widget.onPreview,
      onInsert: widget.onSampleSelected,
      onImport: _import,
    );
  }
}
