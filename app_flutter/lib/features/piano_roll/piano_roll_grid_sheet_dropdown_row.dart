part of 'piano_roll_grid_sheet.dart';

class _DropdownRow<T> extends StatelessWidget {
  const _DropdownRow({
    required this.label,
    required this.value,
    required this.values,
    required this.text,
    this.onChanged,
  });
  final String label;
  final T value;
  final List<T> values;
  final String Function(T) text;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(label),
          const SizedBox(height: 5),
          DropdownButtonFormField<T>(
            initialValue: value,
            isDense: true,
            isExpanded: true,
            dropdownColor: const Color(0xFF22222C),
            decoration: const InputDecoration(
              filled: true,
              fillColor: Color(0xFF22222C),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(borderSide: BorderSide.none),
            ),
            style: const TextStyle(color: Colors.white, fontSize: 12),
            items: [
              for (final item in values)
                DropdownMenuItem(value: item, child: Text(text(item))),
            ],
            onChanged: onChanged == null
                ? null
                : (item) {
                    if (item != null) onChanged!(item);
                  },
          ),
        ],
      );
}
