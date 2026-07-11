part of 'sample_editor_screen.dart';

class _ProcessTabBar extends StatelessWidget {
  const _ProcessTabBar({required this.selected, required this.onSelected});
  final _ProcessTab selected;
  final ValueChanged<_ProcessTab> onSelected;

  static const _specs = <(_ProcessTab, String, IconData)>[
    (_ProcessTab.level, 'Level', Icons.tune),
    (_ProcessTab.playback, 'Playback', Icons.repeat),
    (_ProcessTab.warp, 'Warp', Icons.speed),
    (_ProcessTab.apply, 'Apply', Icons.auto_fix_high),
  ];

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 30,
        child: Row(
          children: [
            for (var i = 0; i < _specs.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: _ProcessTabChip(
                  label: _specs[i].$2,
                  icon: _specs[i].$3,
                  active: selected == _specs[i].$1,
                  onTap: () => onSelected(_specs[i].$1),
                ),
              ),
            ],
          ],
        ),
      );
}
