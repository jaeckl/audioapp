part of 'modulation_strip.dart';

class _LfoCompactRow extends StatelessWidget {
  const _LfoCompactRow({
    required this.lfo,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onWaveformChanged,
    required this.onRateChanged,
    required this.onDelete,
  });

  final LfoSnapshot lfo;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final ValueChanged<int> onWaveformChanged;
  final ValueChanged<double> onRateChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 14,
          child: IconButton(
            tooltip: expanded ? 'Collapse' : 'Expand',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
            onPressed: onToggleExpanded,
            icon: Icon(
              expanded ? Icons.expand_less : Icons.expand_more,
              size: 14,
              color: Colors.white54,
            ),
          ),
        ),
        Text(
          'LFO ${lfo.id}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: const Color(0xFFE8A54B),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 60,
          height: 22,
          child: DropdownButtonFormField<int>(
            initialValue: lfo.waveform.clamp(0, 4),
            isDense: true,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              isCollapsed: true,
            ),
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white70,
              fontSize: 10,
            ),
            items: List.generate(
                5,
                (i) => DropdownMenuItem(
                      value: i,
                      child: Text(LfoSnapshot.waveformNames[i],
                          style: const TextStyle(fontSize: 10)),
                    )),
            onChanged: (v) {
              if (v != null) onWaveformChanged(v);
            },
          ),
        ),
        const Spacer(),
        SizedBox(
          width: 50,
          height: 22,
          child: _MiniSlider(
            value: lfo.rate,
            label: 'Rate',
            onChanged: onRateChanged,
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: 'Remove LFO',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
          onPressed: onDelete,
          icon: const Icon(Icons.remove_circle_outline,
              size: 14, color: Colors.white38),
        ),
      ],
    );
  }
}
