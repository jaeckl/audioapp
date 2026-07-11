part of 'sample_editor_screen.dart';

class _SliceTabBar extends StatelessWidget {
  const _SliceTabBar({required this.selected, required this.onSelected});
  final _SliceTab selected;
  final ValueChanged<_SliceTab> onSelected;

  static const _tabs = <(_SliceTab, String, IconData)>[
    (_SliceTab.auto, 'Auto', Icons.auto_fix_high),
    (_SliceTab.edit, 'Edit', Icons.edit),
    (_SliceTab.map, 'Map', Icons.grid_view_rounded),
  ];

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 38,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .035),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: Colors.white.withValues(alpha: .08)),
          ),
          child: Row(children: [
            for (var i = 0; i < _tabs.length; i++)
              Expanded(
                child: _SliceTabButton(
                  label: _tabs[i].$2,
                  icon: _tabs[i].$3,
                  active: selected == _tabs[i].$1,
                  onTap: () => onSelected(_tabs[i].$1),
                ),
              ),
          ]),
        ),
      );
}
