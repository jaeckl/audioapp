part of 'sample_editor_take_panel.dart';

class _BoundaryModeTile extends StatelessWidget {
  const _BoundaryModeTile({
    required this.hold,
    required this.enabled,
    required this.onChanged,
  });

  final bool hold;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 150,
        height: 66,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: enabled ? .04 : .02),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: Colors.white.withValues(alpha: enabled ? .07 : .03)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('BOUNDARY',
                  style: TextStyle(
                      color: Colors.white38,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .5)),
              const SizedBox(height: 6),
              Expanded(
                child: Row(children: [
                  _seg('CUT', !hold, enabled, () => onChanged(false)),
                  const SizedBox(width: 6),
                  _seg('RING', hold, enabled, () => onChanged(true)),
                ]),
              ),
            ],
          ),
        ),
      );

  Widget _seg(String label, bool active, bool enabled, VoidCallback onTap) =>
      Expanded(
        child: Material(
          color: active
              ? ArrangementLoopRegionTheme.color.withValues(alpha: .30)
              : Colors.white.withValues(alpha: .05),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: enabled ? onTap : null,
            child: Center(
              child: Text(label,
                  style: TextStyle(
                      color: !enabled
                          ? Colors.white24
                          : active
                              ? Colors.white
                              : Colors.white60,
                      fontSize: 11,
                      fontWeight: FontWeight.w900)),
            ),
          ),
        ),
      );
}
