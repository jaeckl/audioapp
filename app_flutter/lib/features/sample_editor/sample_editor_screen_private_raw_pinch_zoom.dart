part of 'sample_editor_screen.dart';

class _RawPinchZoom extends StatefulWidget {
  const _RawPinchZoom(
      {required this.child,
      required this.onStart,
      required this.onScale,
      required this.onPinchChanged});
  final Widget child;
  final VoidCallback onStart;
  final ValueChanged<double> onScale;
  final ValueChanged<bool> onPinchChanged;
  @override
  State<_RawPinchZoom> createState() => _RawPinchZoomState();
}
