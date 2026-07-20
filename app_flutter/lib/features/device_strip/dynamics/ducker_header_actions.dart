part of '../dynamics_fx_panels.dart';

/// Flat header sidechain source combo (Reverb-style chrome).
class DuckerHeaderActions extends StatelessWidget {
  const DuckerHeaderActions({
    super.key,
    required this.device,
    required this.sources,
    required this.tracks,
    required this.onSidechainChanged,
  });

  final DuckerDeviceSnapshot device;
  final List<RoutingSourceOption> sources;
  final List<TrackSnapshot> tracks;
  final ValueChanged<String> onSidechainChanged;

  static const _accent = DuckerDevicePanel.accent;

  IconData _iconFor(RoutingSourceOption source) {
    final index = tracks.indexWhere((t) => t.id == source.trackId);
    if (index < 0) return Icons.audiotrack;
    return TrackLaneIcon.iconForTrack(tracks[index], index);
  }

  String get _label {
    final match = sources.where((s) => s.id == device.sidechainSourceId);
    if (match.isEmpty) return 'OFF';
    final source = match.first;
    if (source.id.isEmpty) return 'OFF';
    return source.label.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final selected = sources.any((s) => s.id == device.sidechainSourceId)
        ? device.sidechainSourceId
        : '';
    return SizedBox(
      height: 40,
      child: PopupMenuButton<String>(
        key: const ValueKey('ducker-sidechain-menu'),
        tooltip: 'Sidechain input',
        padding: EdgeInsets.zero,
        color: const Color(0xFF22222E),
        onSelected: (id) {
          final match = sources.where((s) => s.id == id).firstOrNull;
          if (match != null && match.disabled) return;
          onSidechainChanged(id);
        },
        itemBuilder: (context) => [
          for (final source in sources)
            PopupMenuItem<String>(
              value: source.id,
              enabled: !source.disabled,
              height: 34,
              child: Row(
                children: [
                  if (source.id.isNotEmpty) ...[
                    Icon(_iconFor(source), size: 14, color: _accent),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      source.disabled && source.disabledReason != null
                          ? '${source.label} (${source.disabledReason})'
                          : (source.id.isEmpty ? 'Off' : source.label),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: source.id == selected
                            ? _accent
                            : source.disabled
                                ? Colors.white38
                                : Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
        child: SizedBox(
          width: 96,
          height: 40,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    _label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .25,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 14,
                  color: Colors.white54,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
