part of 'device_section_card.dart';

class DevicePreviewFrame extends StatelessWidget {
  const DevicePreviewFrame({
    super.key,
    required this.child,
    this.height = DevicePanelTheme.previewHeroHeight,
    this.borderColor,
  });

  final Widget child;
  final double height;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration:
            DevicePanelTheme.previewDecoration(borderColor: borderColor),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DevicePanelTheme.sectionRadius),
          child: child,
        ),
      ),
    );
  }
}
