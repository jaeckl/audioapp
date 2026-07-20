part of 'eq_preview.dart';

/// Eager pan so strip scroll loses once finger lands on an EQ handle.
class _EagerPanRecognizer extends PanGestureRecognizer {
  _EagerPanRecognizer({required this.shouldClaim});

  final bool Function(Offset localPosition) shouldClaim;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (!shouldClaim(event.localPosition)) return;
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }

  @override
  void rejectGesture(int pointer) {
    acceptGesture(pointer);
  }
}
