import 'package:flutter/material.dart';

class ArrangementView extends StatelessWidget {
  const ArrangementView({
    super.key,
    required this.selectedTrackIndex,
    required this.onTrackSelected,
  });

  final int? selectedTrackIndex;
  final ValueChanged<int> onTrackSelected;

  static const _placeholderTracks = ['Track 1', 'Track 2'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Text('Arrangement', style: theme.textTheme.titleMedium),
              const Spacer(),
              Text(
                'Timeline — pinch zoom (future)',
                style: theme.textTheme.labelSmall?.copyWith(color: Colors.white38),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A22),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: ListView.builder(
              itemCount: _placeholderTracks.length,
              itemBuilder: (context, index) {
                final selected = selectedTrackIndex == index;
                return Material(
                  color: selected ? const Color(0xFF2D2D3A) : Colors.transparent,
                  child: InkWell(
                    onTap: () => onTrackSelected(index),
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 32,
                            decoration: BoxDecoration(
                              color: selected ? theme.colorScheme.primary : Colors.white24,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(_placeholderTracks[index]),
                          const Spacer(),
                          Container(
                            width: 120,
                            height: 28,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Text(
                              'MIDI clip',
                              style: theme.textTheme.labelSmall?.copyWith(color: Colors.white38),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
