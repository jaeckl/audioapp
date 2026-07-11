part of 'editor_view_range.dart';

class EditorViewRangeDropdown extends StatelessWidget {
  const EditorViewRangeDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<int>(
        value: value,
        isDense: true,
        icon: const Icon(Icons.unfold_more, size: 18, color: Colors.white54),
        dropdownColor: const Color(0xFF2A2A36),
        style: const TextStyle(color: Colors.white70, fontSize: 13),
        items: [
          for (final bars in EditorViewRange.bars)
            DropdownMenuItem(
              value: bars,
              child: Text('$bars bar${bars == 1 ? '' : 's'}'),
            ),
        ],
        onChanged: (next) {
          if (next != null) {
            onChanged(next);
          }
        },
      ),
    );
  }
}
