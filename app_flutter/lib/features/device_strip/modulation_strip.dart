import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_strip_theme.dart';

/// Collapsible modulation strip that sits below the device header.
/// Shows LFO cards with waveform/rate/sync controls and a target list.
class ModulationStrip extends StatelessWidget {
  const ModulationStrip({
    super.key,
    required this.lfos,
    required this.modEdges,
    required this.deviceId,
    required this.onBridgeCall,
    this.maxLfos = 2,
  });

  final List<LfoSnapshot> lfos;
  final List<ModulationEdgeSnapshot> modEdges;
  final String deviceId;
  final Future<ProjectSnapshot> Function(String method, Map<String, dynamic> args) onBridgeCall;
  final int maxLfos;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DeviceStripTheme.toolRailBackground,
        border: const Border(
          left: BorderSide(color: DeviceStripTheme.cardBorder, width: DeviceStripTheme.cardBorderWidth),
          right: BorderSide(color: DeviceStripTheme.cardBorder, width: DeviceStripTheme.cardBorderWidth),
          bottom: BorderSide(color: DeviceStripTheme.cardBorder, width: DeviceStripTheme.cardBorderWidth),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ...lfos.map((lfo) => _LfoCard(
              lfo: lfo,
              edges: modEdges.where((e) => e.lfoId == lfo.id).toList(),
              onBridgeCall: onBridgeCall,
              deviceId: deviceId,
            )),
            if (lfos.length < maxLfos)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => onBridgeCall('createLfo', {}),
                    icon: Icon(Icons.add, size: 14, color: theme.colorScheme.primary),
                    label: Text(
                      'Add Modulator',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LfoCard extends StatefulWidget {
  const _LfoCard({
    required this.lfo,
    required this.edges,
    required this.onBridgeCall,
    required this.deviceId,
  });

  final LfoSnapshot lfo;
  final List<ModulationEdgeSnapshot> edges;
  final String deviceId;
  final Future<ProjectSnapshot> Function(String method, Map<String, dynamic> args) onBridgeCall;

  @override
  State<_LfoCard> createState() => _LfoCardState();
}

class _LfoCardState extends State<_LfoCard> {
  bool _expanded = false;

  Future<void> _update(String param, double value) async {
    await widget.onBridgeCall('updateLfoParam', {
      'lfoId': widget.lfo.id,
      'param': param,
      'value': value,
    });
  }

  Future<void> _removeEdge(ModulationEdgeSnapshot edge) async {
    await widget.onBridgeCall('removeModulation', {
      'lfoId': edge.lfoId,
      'paramId': edge.paramId,
    });
  }

  @override
  Widget build(BuildContext context) {
    final lfo = widget.lfo;
    final compact = _LfoCompactRow(
      lfo: lfo,
      expanded: _expanded,
      onToggleExpanded: () => setState(() => _expanded = !_expanded),
      onWaveformChanged: (v) => _update('waveform', v.toDouble()),
      onRateChanged: (v) => _update('rate', v),
      onDelete: () => widget.onBridgeCall('removeLfo', {'lfoId': lfo.id}),
    );

    List<Widget> children = [compact];

    if (_expanded) {
      children.add(const SizedBox(height: 4));
      children.add(_ExpandedLfoContent(
        lfo: lfo,
        edges: widget.edges,
        onUpdate: _update,
        onRemoveEdge: _removeEdge,
      ));
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF181821),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

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
            value: lfo.waveform.clamp(0, 4),
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
            items: List.generate(5, (i) => DropdownMenuItem(
              value: i,
              child: Text(LfoSnapshot.waveformNames[i], style: const TextStyle(fontSize: 10)),
            )),
            onChanged: (v) { if (v != null) onWaveformChanged(v); },
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
          icon: Icon(Icons.remove_circle_outline, size: 14, color: Colors.white38),
        ),
      ],
    );
  }
}

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
            Text('Sync:', style: TextStyle(color: Colors.white38, fontSize: 9)),
            const SizedBox(width: 4),
            SizedBox(
              width: 48,
              height: 22,
              child: DropdownButtonFormField<int>(
                value: lfo.syncDivision.clamp(0, 5),
                isDense: true,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  isCollapsed: true,
                ),
                style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70, fontSize: 10),
                items: List.generate(_syncOptions.length, (i) => DropdownMenuItem(
                  value: i,
                  child: Text(_syncOptions[i], style: const TextStyle(fontSize: 10)),
                )),
                onChanged: (v) { if (v != null) onUpdate('syncDivision', v.toDouble()); },
              ),
            ),
            const SizedBox(width: 12),
            Text('Phase:', style: TextStyle(color: Colors.white38, fontSize: 9)),
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
          Text('Targets:', style: TextStyle(color: Colors.white38, fontSize: 9)),
          const SizedBox(height: 2),
          ...edges.map((edge) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    edge.paramId,
                    style: TextStyle(color: Colors.white60, fontSize: 9),
                  ),
                ),
                Text(
                  '${(edge.amount * 100).round()}%',
                  style: TextStyle(color: const Color(0xFFE8A54B), fontSize: 9),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => onRemoveEdge(edge),
                  child: Icon(Icons.close, size: 12, color: Colors.white30),
                ),
              ],
            ),
          )),
        ],
      ],
    );
  }
}

/// Compact horizontal slider for LFO rate/phase.
class _MiniSlider extends StatelessWidget {
  const _MiniSlider({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final double value;
  final String label;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
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
            child: Row(
              children: [
                Container(
                  width: constraints.maxWidth * value,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8A54B),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}