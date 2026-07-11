part of 'modulation_strip.dart';

class _ExpandedLfoContent extends StatelessWidget {
  const _ExpandedLfoContent({
    required this.lfo,
    required this.edges,
    required this.onUpdate,
    required this.onRemoveEdge,
  });

  final LfoSnapshot lfo;
  final List<ModulationEdgeSnapshot> edges;
  final Future<void> Function(String param, double value) onUpdate;
  final Future<void> Function(ModulationEdgeSnapshot edge) onRemoveEdge;

  static const _syncOptions = ['Free', '1/1', '1/2', '1/4', '1/8', '1/16'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Text('Sync:',
                style: TextStyle(color: Colors.white38, fontSize: 9)),
            const SizedBox(width: 4),
            SizedBox(
              width: 48,
              height: 22,
              child: DropdownButtonFormField<int>(
                initialValue: lfo.syncDivision.clamp(0, 5),
                isDense: true,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  isCollapsed: true,
                ),
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: Colors.white70, fontSize: 10),
                items: List.generate(
                    _syncOptions.length,
                    (i) => DropdownMenuItem(
                          value: i,
                          child: Text(_syncOptions[i],
                              style: const TextStyle(fontSize: 10)),
                        )),
                onChanged: (v) {
                  if (v != null) onUpdate('syncDivision', v.toDouble());
                },
              ),
            ),
            const SizedBox(width: 12),
            const Text('Phase:',
                style: TextStyle(color: Colors.white38, fontSize: 9)),
            const SizedBox(width: 4),
            SizedBox(
              width: 50,
              height: 22,
              child: _MiniSlider(
                value: lfo.phase,
                label: 'Phase',
                onChanged: (v) => onUpdate('phase', v),
              ),
            ),
          ],
        ),
        if (edges.isNotEmpty) ...[
          const SizedBox(height: 4),
          const Text('Targets:',
              style: TextStyle(color: Colors.white38, fontSize: 9)),
          const SizedBox(height: 2),
          ...edges.map((edge) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        edge.paramId,
                        style:
                            const TextStyle(color: Colors.white60, fontSize: 9),
                      ),
                    ),
                    Text(
                      '${(edge.amount * 100).round()}%',
                      style: const TextStyle(
                          color: Color(0xFFE8A54B), fontSize: 9),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => onRemoveEdge(edge),
                      child: const Icon(Icons.close,
                          size: 12, color: Colors.white30),
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }
}
