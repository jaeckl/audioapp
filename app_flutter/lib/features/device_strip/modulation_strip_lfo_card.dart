part of 'modulation_strip.dart';

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
  final Future<ProjectSnapshot> Function(
      String method, Map<String, dynamic> args) onBridgeCall;

  @override
  State<_LfoCard> createState() => _LfoCardState();
}
