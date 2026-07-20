part of '../dynamics_fx_panels.dart';

/// Phaser-inspired dynamics face: optional side wells + full-bleed curve + plate.
/// Pass empty [left]/[right] to omit that rail (Gate / Expander).
class _DynamicsRailFace extends StatelessWidget {
  const _DynamicsRailFace({
    required this.preview,
    required this.plate,
    this.left = const [],
    this.right = const [],
    this.sideWidth = 84,
  });

  static const sideWell = Color(0xFF1C1C28);

  final Widget preview;
  final List<Widget> left;
  final List<Widget> plate;
  final List<Widget> right;
  final double sideWidth;

  @override
  Widget build(BuildContext context) {
    Widget side(List<Widget> children) => Container(
          width: sideWidth,
          decoration: BoxDecoration(
            color: sideWell,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: children,
          ),
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (left.isNotEmpty) ...[
          side(left),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: FilterSectionLayout(
            modeSelector: const SizedBox.shrink(),
            preview: preview,
            controls: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: plate,
            ),
          ),
        ),
        if (right.isNotEmpty) ...[
          const SizedBox(width: 4),
          side(right),
        ],
      ],
    );
  }
}
