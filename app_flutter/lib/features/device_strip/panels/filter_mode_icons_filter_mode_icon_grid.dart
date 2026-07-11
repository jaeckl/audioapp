part of 'filter_mode_icons.dart';

class FilterModeIconGrid extends StatelessWidget {
  const FilterModeIconGrid({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    this.accentColor = const Color(0xFF5BC0EB),
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 3.0;
        final cellW = (constraints.maxWidth - gap) / 2;
        final cellH = (constraints.maxHeight - gap) / 2;
        final size = math.min(cellW, cellH);

        Widget cell(int index) {
          return Center(
            child: FilterModeIconButton(
              mode: FilterCurveMode.values[index],
              selected: index == selectedIndex,
              accentColor: accentColor,
              size: size,
              onTap: () => onSelected(index),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 2),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: cell(0)),
                    const SizedBox(width: gap),
                    Expanded(child: cell(1)),
                  ],
                ),
              ),
              const SizedBox(height: gap),
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: cell(2)),
                    const SizedBox(width: gap),
                    Expanded(child: cell(3)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
