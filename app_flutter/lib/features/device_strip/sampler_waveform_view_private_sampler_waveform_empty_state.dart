part of 'sampler_waveform_view.dart';

class _SamplerWaveformEmptyState extends StatelessWidget {
  const _SamplerWaveformEmptyState({
    required this.hint,
    required this.accentColor,
    this.onLoadSample,
  });

  final String? hint;
  final Color accentColor;
  final VoidCallback? onLoadSample;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.graphic_eq_rounded,
                size: 28,
                color: accentColor.withValues(alpha: 0.45),
              ),
              const SizedBox(height: 8),
              Text(
                hint ?? 'Load a sample to edit trim and playback',
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: Colors.white38),
                textAlign: TextAlign.center,
              ),
              if (onLoadSample != null) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: onLoadSample,
                  icon: const Icon(Icons.folder_open_rounded, size: 18),
                  label: const Text('Load sample'),
                  style: FilledButton.styleFrom(
                    backgroundColor: accentColor.withValues(alpha: 0.22),
                    foregroundColor: accentColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
