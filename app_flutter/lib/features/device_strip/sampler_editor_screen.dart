import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../sample_library/sample_library_screen.dart';
import 'sampler_device_strip.dart';

/// Fullscreen sampler editor (waveform trim in US-07-02).
class SamplerEditorScreen extends StatelessWidget {
  const SamplerEditorScreen({
    super.key,
    required this.trackName,
    required this.device,
    required this.sample,
    required this.onGainChanged,
    required this.onLoadSample,
  });

  final String trackName;
  final DeviceSnapshot device;
  final SampleLibraryEntrySnapshot? sample;
  final ValueChanged<double> onGainChanged;
  final VoidCallback onLoadSample;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sampleName = sample?.name ?? 'No sample loaded';
    final peaks = sample?.waveformPeaks ?? const <double>[];

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A22),
        title: Text(sampleName),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Load sample',
            onPressed: onLoadSample,
            icon: const Icon(Icons.folder_open_outlined),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              '$trackName · Sampler',
              style: theme.textTheme.labelLarge?.copyWith(color: Colors.white54),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF121218),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: peaks.isEmpty
                    ? Center(
                        child: Text(
                          'Load a sample from the library',
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white38),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CustomPaint(
                          painter: WaveformPainter(peaks: peaks),
                          child: const SizedBox.expand(),
                        ),
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Row(
              children: [
                const Text('Gain'),
                Expanded(
                  child: Slider(
                    min: 0,
                    max: 1,
                    value: device.gain.clamp(0, 1),
                    onChanged: onGainChanged,
                  ),
                ),
                Text('${(device.gain * 100).round()}%'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
