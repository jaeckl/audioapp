import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';

/// Bottom sheet for assigning an LFO to a knob parameter.
/// Shows available LFOs with amount sliders.
class ModulationAssignSheet extends StatefulWidget {
  const ModulationAssignSheet({
    super.key,
    required this.lfos,
    required this.existingEdges,
    required this.deviceId,
    required this.paramId,
    required this.paramLabel,
    required this.onAssign,
    required this.onRemove,
  });

  final List<LfoSnapshot> lfos;
  final List<ModulationEdgeSnapshot> existingEdges;
  final String deviceId;
  final String paramId;
  final String paramLabel;
  final Future<void> Function(int lfoId, double amount) onAssign;
  final Future<void> Function(int lfoId) onRemove;

  @override
  State<ModulationAssignSheet> createState() => _ModulationAssignSheetState();
}

class _ModulationAssignSheetState extends State<ModulationAssignSheet> {
  final Map<int, double> _amounts = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final edge in widget.existingEdges) {
      _amounts[edge.lfoId] = edge.amount;
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      for (final entry in _amounts.entries) {
        await widget.onAssign(entry.key, entry.value);
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: 280,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Text(
                    'Modulate ${widget.paramLabel}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close, size: 18, color: Colors.white54),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            Expanded(
              child: widget.lfos.isEmpty
                  ? Center(
                      child: Text(
                        'No LFOs available. Tap "Mod" in the device header to add one.',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.white38),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      children: widget.lfos.map((lfo) {
                        final existing = widget.existingEdges
                            .where((e) => e.lfoId == lfo.id)
                            .toList();
                        final amount = _amounts[lfo.id] ??
                            (existing.isNotEmpty ? existing.first.amount : 0.0);
                        final isAssigned = existing.isNotEmpty || _amounts.containsKey(lfo.id);

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 50,
                                child: Text(
                                  'LFO ${lfo.id}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: const Color(0xFFE8A54B),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderThemeData(
                                    trackHeight: 3,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                    activeTrackColor: const Color(0xFFE8A54B),
                                    inactiveTrackColor: Colors.white12,
                                    thumbColor: const Color(0xFFE8A54B),
                                    overlayColor: const Color(0xFFE8A54B).withValues(alpha: 0.15),
                                  ),
                                  child: Slider(
                                    value: amount,
                                    min: -1.0,
                                    max: 1.0,
                                    divisions: 40,
                                    onChanged: (v) => setState(() => _amounts[lfo.id] = v),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 36,
                                child: Text(
                                  '${(amount * 100).round()}%',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              if (isAssigned)
                                IconButton(
                                  tooltip: 'Remove modulation',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                  icon: const Icon(Icons.remove_circle_outline,
                                      size: 16, color: Colors.white30),
                                  onPressed: () async {
                                    await widget.onRemove(lfo.id);
                                    if (mounted) {
                                      setState(() => _amounts.remove(lfo.id));
                                    }
                                  },
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8A54B),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving...' : 'Done'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the modulation assignment bottom sheet for a given parameter.
Future<void> showModulationAssignSheet({
  required BuildContext context,
  required List<LfoSnapshot> lfos,
  required List<ModulationEdgeSnapshot> allEdges,
  required String deviceId,
  required String paramId,
  required String paramLabel,
  required Future<void> Function(int lfoId, double amount) onAssign,
  required Future<void> Function(int lfoId) onRemove,
}) {
  final existingEdges = allEdges.where(
    (e) => e.deviceId == deviceId && e.paramId == paramId,
  ).toList();

  return showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1A1A24),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (_) => ModulationAssignSheet(
      lfos: lfos,
      existingEdges: existingEdges,
      deviceId: deviceId,
      paramId: paramId,
      paramLabel: paramLabel,
      onAssign: onAssign,
      onRemove: onRemove,
    ),
  );
}