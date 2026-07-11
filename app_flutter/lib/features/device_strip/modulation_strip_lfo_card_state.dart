part of 'modulation_strip.dart';

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
      'deviceId': edge.deviceId,
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
