part of 'device_tool_rail.dart';

/// Drag ghost = raster snapshot of the live device (rail + panels + body).
class _DeviceDragFeedback extends StatefulWidget {
  const _DeviceDragFeedback({
    super.key,
    required this.repaintKey,
    required this.width,
    required this.height,
    required this.pixelRatio,
    required this.accentColor,
  });

  final GlobalKey repaintKey;
  final double width;
  final double height;
  final double pixelRatio;
  final Color accentColor;

  @override
  State<_DeviceDragFeedback> createState() => _DeviceDragFeedbackState();
}

class _DeviceDragFeedbackState extends State<_DeviceDragFeedback> {
  ui.Image? _image;
  Size? _capturedSize;

  @override
  void initState() {
    super.initState();
    _capture();
    if (_image == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _capture();
        if (_image != null) setState(() {});
      });
    }
  }

  void _capture() {
    final ctx = widget.repaintKey.currentContext;
    if (ctx == null) return;
    final ro = ctx.findRenderObject();
    if (ro is! RenderRepaintBoundary) return;
    if (ro.debugNeedsPaint) return;
    try {
      _image?.dispose();
      _capturedSize = ro.size;
      _image = ro.toImageSync(pixelRatio: widget.pixelRatio);
    } catch (_) {
      // Keep fallback until a later frame can capture.
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = _capturedSize?.width ?? widget.width;
    final height = _capturedSize?.height ?? widget.height;
    return Material(
      color: Colors.transparent,
      elevation: 14,
      shadowColor: Colors.black87,
      borderRadius: BorderRadius.circular(DeviceStripTheme.cardRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: _image != null
            ? RawImage(
                image: _image,
                width: width,
                height: height,
                fit: BoxFit.fill,
              )
            : DecoratedBox(
                decoration: BoxDecoration(
                  color: DeviceStripTheme.cardBackground,
                  borderRadius:
                      BorderRadius.circular(DeviceStripTheme.cardRadius),
                  border: Border.all(color: widget.accentColor, width: 2),
                ),
              ),
      ),
    );
  }
}
