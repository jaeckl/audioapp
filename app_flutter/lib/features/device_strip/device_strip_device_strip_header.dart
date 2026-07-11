part of 'device_strip.dart';

class _DeviceStripHeader extends StatelessWidget {
  const _DeviceStripHeader({
    required this.track,
    required this.deviceCount,
    required this.onOpenFullscreen,
    this.collapsed = false,
    this.showCollapse = false,
    this.onExpand,
    this.onCollapse,
  });

  final TrackSnapshot track;
  final int deviceCount;
  final VoidCallback onOpenFullscreen;
  final bool collapsed;
  final bool showCollapse;
  final VoidCallback? onExpand;
  final VoidCallback? onCollapse;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 6, 4, collapsed ? 0 : 2),
      child: Row(
        children: [
          Text(
            'DEVICES',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFFE8A54B),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
          ),
          const SizedBox(width: 8),
          if (track.freeze.enabled) ...[
            _FreezeStripBadge(stale: track.freeze.stale),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              '${track.name} · $deviceCount',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: Colors.white70),
            ),
          ),
          if (collapsed && onExpand != null)
            IconButton(
              tooltip: 'Expand device strip',
              visualDensity: VisualDensity.compact,
              onPressed: onExpand,
              icon: const Icon(Icons.unfold_more,
                  size: 20, color: Colors.white54),
            ),
          if (!collapsed && showCollapse && onCollapse != null)
            IconButton(
              tooltip: 'Collapse device strip',
              visualDensity: VisualDensity.compact,
              onPressed: onCollapse,
              icon: const Icon(Icons.unfold_less,
                  size: 20, color: Colors.white54),
            ),
          IconButton(
            tooltip: 'Open device chain',
            visualDensity: VisualDensity.compact,
            onPressed: onOpenFullscreen,
            icon:
                const Icon(Icons.open_in_full, size: 20, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
