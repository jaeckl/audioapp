part of 'device_landscape_shell.dart';

class _DeviceLandscapeShellState extends State<DeviceLandscapeShell> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A22),
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
        ),
        actions: widget.actions,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = math.min(
              constraints.maxWidth / widget.designWidth,
              constraints.maxHeight / widget.designHeight,
            );

            return Center(
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.center,
                child: SizedBox(
                  width: widget.designWidth,
                  height: widget.designHeight,
                  child: widget.child,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
