part of 'curve_editor_screen.dart';

class _ShapeInsertSheet extends StatefulWidget {
  const _ShapeInsertSheet({
    required this.accent,
    required this.polarity,
    required this.startVal,
    required this.endVal,
    required this.onApply,
  });

  final Color accent;
  final int polarity;
  final double startVal;
  final double endVal;
  final void Function(
      String shapeName, double floor, double peak, double cycles) onApply;

  @override
  State<_ShapeInsertSheet> createState() => _ShapeInsertSheetState();
}
