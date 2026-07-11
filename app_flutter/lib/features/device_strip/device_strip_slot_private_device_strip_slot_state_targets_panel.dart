part of 'device_strip_slot.dart';

extension DeviceStripSlotStateTargetspanelOperation on _DeviceStripSlotState {
  Widget _targetsPanel(LfoSnapshot lfo) {
    const accent = Color(0xFFE8A54B);
    final edges = _localModEdges
        .where((e) => e.lfoId == lfo.id && e.deviceId == widget.device.id)
        .toList();
    return Container(
      key: ValueKey('targets_${lfo.id}'),
      width: _targetsPanelWidth,
      decoration: BoxDecoration(
        color: const Color(0xFF14141E),
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 10, 8, 4),
            child: Text(
              'TARGETS',
              style: TextStyle(
                color: accent,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ),
          Expanded(
            child: edges.isEmpty
                ? const Center(
                    child: Text(
                      'No targets',
                      style: TextStyle(color: Colors.white24, fontSize: 9),
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    itemCount: edges.length,
                    itemBuilder: (context, index) {
                      final edge = edges[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                edge.paramId,
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 9,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${(edge.amount * 100).round()}%',
                              style:
                                  const TextStyle(color: accent, fontSize: 9),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _onBridgeCall('removeModulation', {
                                'lfoId': edge.lfoId,
                                'deviceId': edge.deviceId,
                                'paramId': edge.paramId,
                              }),
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: Center(
                                  child: Icon(Icons.close,
                                      size: 14,
                                      color:
                                          Colors.white.withValues(alpha: 0.45)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
