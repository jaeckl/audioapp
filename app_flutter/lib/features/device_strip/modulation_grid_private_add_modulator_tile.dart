part of 'modulation_grid.dart';

class _AddModulatorTile extends StatelessWidget {
  const _AddModulatorTile({
    required this.onPressed,
    required this.width,
    required this.height,
  });

  final VoidCallback onPressed;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: const Color(0xFF181821),
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Center(
              child: Icon(Icons.add, size: 18, color: Colors.white54),
            ),
          ),
        ),
      ),
    );
  }
}
