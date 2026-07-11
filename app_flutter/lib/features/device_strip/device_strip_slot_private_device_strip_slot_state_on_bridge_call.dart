part of 'device_strip_slot.dart';

extension DeviceStripSlotStateOnbridgecallOperation on _DeviceStripSlotState {
  Future<ProjectSnapshot> _onBridgeCall(
      String method, Map<String, dynamic> args) async {
    final bridge = widget.onModulationBridgeCall;
    if (bridge == null) return _emptySnapshot;
    try {
      debugPrint('DEVICE_SLOT: _onBridgeCall $method args=$args');
      final snapshot = await bridge(method, args);
      debugPrint(
          'DEVICE_SLOT: _onBridgeCall $method SUCCESS lfos=${snapshot.lfos.length}');
      if (mounted) {
        setState(() {
          _localLfos = List.of(snapshot.lfos);
          _localModEdges = List.of(snapshot.modEdges);
          // Clear stale selection/connect-mode IDs no longer in the list
          final ids = _localLfos.map((l) => l.id).toSet();
          if (_selectedLfoId != null && !ids.contains(_selectedLfoId))
            _selectedLfoId = null;
          if (_connectModeLfoId != null && !ids.contains(_connectModeLfoId))
            _connectModeLfoId = null;
        });
      }
      return snapshot;
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Modulation error: $e'),
              duration: const Duration(seconds: 3)),
        );
      }
      return _emptySnapshot;
    }
  }
}
