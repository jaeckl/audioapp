import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';

/// Side panel showing properties of the currently selected LFO.
/// Appears to the right of the modulation grid when an LFO is selected.
class LfoPropertiesPanel extends StatelessWidget {
  const LfoPropertiesPanel({
    super.key,
    required this.lfo,
    required this.edges,
    required this.onUpdate,
    required this.onRemoveEdge,
  });

  final LfoSnapshot lfo;
  final List<ModulationEdgeSnapshot> edges;
  final Future<void> Function(String param, double value) onUpdate;
  final Future<void> Function(int lfoId, String paramId) onRemoveEdge;

  static const _syncOptions = ['Free', '1/1', '1/2', '1/4', '1/8', '1/16'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: const Color(0xFF14141C),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'LFO ${lfo.id}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: const Color(0xFFE8A54B),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _propRow('Waveform', SizedBox(
              width: 80,
              height: 24,
              child: DropdownButtonFormField<int>(
                value: lfo.waveform.clamp(0, 4),
                isDense: true,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                  isCollapsed: true,
                ),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white70,
                  fontSize: 10,
                ),
                items: List.generate(5, (i) => DropdownMenuItem(
                  value: i,
                  child: Text(LfoSnapshot.waveformNames[i], style: const TextStyle(fontSize: 10)),
                )),
                onChanged: (v) { if (v != null) onUpdate('waveform', v.toDouble()); },
              ),
            )),
            const SizedBox(height: 6),
            _propRow('Rate', _miniSlider(lfo.rate, 'Rate', (v) => onUpdate('rate', v))),
            const SizedBox(height: 6),
            _propRow('Sync', SizedBox(
              width: 60,
              height: 24,
              child: DropdownButtonFormField<int>(
                value: lfo.syncDivision.clamp(0, 5),
                isDense: true,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                  isCollapsed: true,
                ),
                style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70, fontSize: 10),
                items: List.generate(_syncOptions.length, (i) => DropdownMenuItem(
                  value: i,
                  child: Text(_syncOptions[i], style: const TextStyle(fontSize: 10)),
                )),
                onChanged: (v) { if (v != null) onUpdate('syncDivision', v.toDouble()); },
              ),
            )),
            const SizedBox(height: 6),
            _propRow('Phase', _miniSlider(lfo.phase, 'Phase', (v) => onUpdate('phase', v))),
            if (edges.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Targets',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white38,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              ...edges.map((edge) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        edge.paramId,
                        style: const TextStyle(color: Colors.white60, fontSize: 9),
                      ),
                    ),
                    Text(
                      '${(edge.amount * 100).round()}%',
                      style: const TextStyle(color: Color(0xFFE8A54B), fontSize: 9),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => onRemoveEdge(lfo.id, edge.paramId),
                      child: const Icon(Icons.close, size: 12, color: Colors.white30),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _propRow(String label, Widget control) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 9),
          ),
        ),
        const SizedBox(width: 6),
        control,
      ],
    );
  }

  Widget _miniSlider(double value, String label, ValueChanged<double> onChanged) {
    return SizedBox(
      width: 60,
      height: 24,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onHorizontalDragUpdate: (details) {
              final delta = details.delta.dx / constraints.maxWidth;
              onChanged((value + delta).clamp(0.0, 1.0));
            },
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D14),
                borderRadius: BorderRadius.circular(3),
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                width: constraints.maxWidth * value,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8A54B),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}