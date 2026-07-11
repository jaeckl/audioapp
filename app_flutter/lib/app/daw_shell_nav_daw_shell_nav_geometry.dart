part of 'daw_shell_nav.dart';

class DawShellNavGeometry {
  const DawShellNavGeometry({
    required this.edge,
    required this.contentPadding,
    required this.iconQuarterTurns,
  });

  final DawShellNavEdge edge;
  final EdgeInsets contentPadding;
  final int iconQuarterTurns;

  static const double thickness = 64;

  static DawShellNavGeometry of(BuildContext context) {
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final rotation = _effectiveRotation(context);

    switch (rotation) {
      case 1:
        return DawShellNavGeometry(
          edge: DawShellNavEdge.left,
          iconQuarterTurns: 1,
          contentPadding: EdgeInsets.only(left: thickness + viewPadding.left),
        );
      case 3:
        return DawShellNavGeometry(
          edge: DawShellNavEdge.right,
          iconQuarterTurns: 3,
          contentPadding: EdgeInsets.only(right: thickness + viewPadding.right),
        );
      case 2:
        return DawShellNavGeometry(
          edge: DawShellNavEdge.top,
          iconQuarterTurns: 2,
          contentPadding: EdgeInsets.only(top: thickness + viewPadding.top),
        );
      case 0:
      default:
        return DawShellNavGeometry(
          edge: DawShellNavEdge.bottom,
          iconQuarterTurns: 0,
          contentPadding:
              EdgeInsets.only(bottom: thickness + viewPadding.bottom),
        );
    }
  }

  Widget position({required BuildContext context, required Widget child}) {
    final viewPadding = MediaQuery.viewPaddingOf(context);

    switch (edge) {
      case DawShellNavEdge.left:
        return Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          width: thickness + viewPadding.left,
          child: Padding(
            padding: EdgeInsets.only(left: viewPadding.left),
            child: child,
          ),
        );
      case DawShellNavEdge.right:
        return Positioned(
          top: 0,
          bottom: 0,
          right: 0,
          width: thickness + viewPadding.right,
          child: Padding(
            padding: EdgeInsets.only(right: viewPadding.right),
            child: child,
          ),
        );
      case DawShellNavEdge.top:
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: thickness + viewPadding.top,
          child: Padding(
            padding: EdgeInsets.only(top: viewPadding.top),
            child: child,
          ),
        );
      case DawShellNavEdge.bottom:
        return Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: thickness + viewPadding.bottom,
          child: Padding(
            padding: EdgeInsets.only(bottom: viewPadding.bottom),
            child: child,
          ),
        );
    }
  }
}
