import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../sample_library/sample_library_screen.dart';

/// Bitwig-inspired compact sampler panel for the device strip.
class SamplerDeviceStrip extends StatelessWidget {
  const SamplerDeviceStrip({
    super.key,
    required this.trackName,
    required this.device,
    required this.sample,
    required this.onGainChanged,
    required this.onLoadSample,
    required this.onOpenFullscreen,
  });

  final String trackName;
  final DeviceSnapshot device;
  final SampleLibraryEntrySnapshot? sample;
  final ValueChanged<double> onGainChanged;
  final VoidCallback onLoadSample;
  final VoidCallback onOpenFullscreen;

  static const Color _panel = Color(0xFF1C1C24);
  static const Color _accent = Color(0xFFE8A54B);
  static const Color _wave = Color(0xFF6EC9A0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sampleName = sample?.name ?? 'No sample loaded';
    final peaks = sample?.waveformPeaks ?? const <double>[];

    return Material(
      color: _panel,
      child: InkWell(
        onTap: onOpenFullscreen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 6, 10, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: _accent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(
                          'SAMPLER',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: _accent,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sampleName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Open sampler editor',
                          visualDensity: VisualDensity.compact,
                          onPressed: onOpenFullscreen,
                          icon: const Icon(Icons.open_in_full, size: 18, color: Colors.white54),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFF121218),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: sample == null
                                ? Colors.white.withValues(alpha: 0.12)
                                : Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: peaks.isEmpty
                              ? Center(
                                  child: Text(
                                    'Tap Load to choose a sample',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.white38,
                                    ),
                                  ),
                                )
                              : CustomPaint(
                                  painter: WaveformPainter(
                                    peaks: peaks,
                                    color: _wave,
                                  ),
                                  child: const SizedBox.expand(),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        SizedBox(
                          width: 36,
                          child: Text(
                            'Gain',
                            style: theme.textTheme.labelSmall?.copyWith(color: Colors.white54),
                          ),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 2,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                              overlayShape: SliderComponentShape.noOverlay,
                            ),
                            child: Slider(
                              min: 0,
                              max: 1,
                              value: device.gain.clamp(0, 1),
                              onChanged: onGainChanged,
                            ),
                          ),
                        ),
                        Text(
                          '${(device.gain * 100).round()}%',
                          style: theme.textTheme.labelSmall?.copyWith(color: Colors.white54),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonal(
                          onPressed: onLoadSample,
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          child: const Text('Load'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
