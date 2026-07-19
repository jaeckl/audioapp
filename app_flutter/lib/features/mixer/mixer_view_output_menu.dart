part of 'mixer_view.dart';

class _MixerOutputMenu extends StatelessWidget {
  const _MixerOutputMenu({
    required this.choices,
    required this.valueId,
    required this.onChanged,
    this.locked = false,
  });

  final List<_OutputDestination> choices;
  final String valueId;
  final ValueChanged<String>? onChanged;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final selected = _choiceById(choices, valueId) ??
        (choices.isEmpty
            ? const _OutputDestination(
                id: 'master',
                label: 'Master',
                icon: Icons.speaker_outlined,
              )
            : choices.first);

    if (locked || onChanged == null) {
      return _OutputChip(destination: selected, locked: true);
    }

    return PopupMenuButton<String>(
      initialValue: selected.id,
      color: MixerTheme.menuBackground,
      padding: EdgeInsets.zero,
      offset: const Offset(0, -4),
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final choice in choices)
          PopupMenuItem<String>(
            value: choice.id,
            child: _OutputMenuRow(
              destination: choice,
              selected: choice.id == selected.id,
            ),
          ),
      ],
      child: _OutputChip(destination: selected, locked: false),
    );
  }
}

class _OutputChip extends StatelessWidget {
  const _OutputChip({required this.destination, required this.locked});

  final _OutputDestination destination;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MixerTheme.outputRowHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: MixerTheme.chromeSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(
            destination.icon,
            size: 16,
            color: MixerTheme.textMuted,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              destination.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: MixerTheme.menuFontSize,
                fontWeight: FontWeight.w600,
                color: MixerTheme.textPrimary,
              ),
            ),
          ),
          Icon(
            locked ? Icons.lock_outline : Icons.expand_more,
            size: 16,
            color: MixerTheme.textMuted,
          ),
        ],
      ),
    );
  }
}

class _OutputMenuRow extends StatelessWidget {
  const _OutputMenuRow({
    required this.destination,
    required this.selected,
  });

  final _OutputDestination destination;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          destination.icon,
          size: 18,
          color: selected ? MixerTheme.accent : MixerTheme.textMuted,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            destination.label,
            style: TextStyle(
              fontSize: MixerTheme.menuFontSize,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? MixerTheme.accent : MixerTheme.textPrimary,
            ),
          ),
        ),
        if (selected)
          const Icon(Icons.check, size: 16, color: MixerTheme.accent),
      ],
    );
  }
}
