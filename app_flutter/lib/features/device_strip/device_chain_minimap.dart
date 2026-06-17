import 'dart:ui';

import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_chain_layout.dart';
import 'device_strip_card.dart';
import 'device_strip_metrics.dart';
import 'device_strip_slot.dart';
import 'device_strip_theme.dart';

/// Scrubbable minimap of the fullscreen device chain.
class DeviceChainMinimap extends StatefulWidget {
  const DeviceChainMinimap({
    super.key,
    required this.track,
    required this.scrollController,
    required this.density,
  });

  final TrackSnapshot track;
  final ScrollController scrollController;
  final DeviceStripSlotDensity density;

  @override
  State<DeviceChainMinimap> createState() => _DeviceChainMinimapState();
}

class _DeviceChainMinimapState extends State<DeviceChainMinimap> {
  bool _scrubbing = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant DeviceChainMinimap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_onScroll);
      widget.scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (!_scrubbing && mounted) setState(() {});
  }

  void _scrubToLocalX(double localX, double trackWidth, double viewportWidth) {
    final controller = widget.scrollController;
    if (!controller.hasClients) return;

    final maxExtent = _maxScrollExtent();
    if (maxExtent <= 0) return;

    final contentWidth = DeviceChainLayout.contentWidth(widget.track, widget.density);
    final thumbWidth = _thumbWidth(trackWidth, viewportWidth, contentWidth);
    final travel = trackWidth - thumbWidth;
    if (travel <= 0) return;

    final fraction = ((localX - thumbWidth / 2) / travel).clamp(0.0, 1.0);
    controller.jumpTo(fraction * maxExtent);
  }

  double _maxScrollExtent() {
    if (!widget.scrollController.hasClients) return 0;
    final position = widget.scrollController.position;
    if (!position.hasContentDimensions) return 0;
    return position.maxScrollExtent;
  }

  double _thumbWidth(double trackWidth, double viewportWidth, double contentWidth) {
    if (contentWidth <= viewportWidth) return trackWidth;
    return (viewportWidth / contentWidth * trackWidth).clamp(18.0, trackWidth);
  }

  double _thumbLeft(
    double trackWidth,
    double viewportWidth,
    double contentWidth,
    double scrollOffset,
    double maxExtent,
  ) {
    final thumbWidth = _thumbWidth(trackWidth, viewportWidth, contentWidth);
    if (maxExtent <= 0) return 0;
    final travel = trackWidth - thumbWidth;
    return (scrollOffset / maxExtent * travel).clamp(0.0, travel);
  }

  @override
  Widget build(BuildContext context) {
    final chainHeight = switch (widget.density) {
      DeviceStripSlotDensity.fullscreen => DeviceStripMetrics.fullscreenHeight,
      DeviceStripSlotDensity.collapsed => DeviceStripMetrics.collapsedHeight,
      DeviceStripSlotDensity.strip => DeviceStripMetrics.height,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: SizedBox(
        height: DeviceStripMetrics.minimapHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final trackWidth = constraints.maxWidth;
            final viewportWidth = MediaQuery.sizeOf(context).width;
            final contentWidth = DeviceChainLayout.contentWidth(widget.track, widget.density);
            final scrollOffset = widget.scrollController.hasClients
                ? widget.scrollController.offset
                : 0.0;
            final maxExtent = _maxScrollExtent();
            final thumbWidth = _thumbWidth(trackWidth, viewportWidth, contentWidth);
            final thumbLeft = _thumbLeft(
              trackWidth,
              viewportWidth,
              contentWidth,
              scrollOffset,
              maxExtent,
            );

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (_) => setState(() => _scrubbing = true),
              onHorizontalDragUpdate: (details) {
                _scrubToLocalX(details.localPosition.dx, trackWidth, viewportWidth);
              },
              onHorizontalDragEnd: (_) => setState(() => _scrubbing = false),
              onTapDown: (details) {
                setState(() => _scrubbing = true);
                _scrubToLocalX(details.localPosition.dx, trackWidth, viewportWidth);
              },
              onTapUp: (_) => setState(() => _scrubbing = false),
              onTapCancel: () => setState(() => _scrubbing = false),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _MinimapChainPreview(
                      track: widget.track,
                      density: widget.density,
                      chainHeight: chainHeight,
                    ),
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 0.8, sigmaY: 0.8),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E28).withValues(alpha: 0.42),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: thumbLeft,
                      width: thumbWidth,
                      top: 0,
                      bottom: 0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: _scrubbing ? 0.14 : 0.08),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: _scrubbing ? 0.7 : 0.45),
                            width: _scrubbing ? 1.5 : 1,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MinimapChainPreview extends StatelessWidget {
  const _MinimapChainPreview({
    required this.track,
    required this.density,
    required this.chainHeight,
  });

  final TrackSnapshot track;
  final DeviceStripSlotDensity density;
  final double chainHeight;

  @override
  Widget build(BuildContext context) {
    final devices = track.visibleDevices.toList();
    final contentWidth = DeviceChainLayout.contentWidth(track, density, horizontalPadding: 0);

    if (devices.isEmpty) {
      return ColoredBox(
        color: DeviceStripTheme.stripBackground,
        child: Center(
          child: Text(
            'No devices',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white24),
          ),
        ),
      );
    }

    return ColoredBox(
      color: DeviceStripTheme.stripBackground,
      child: FittedBox(
        fit: BoxFit.fitHeight,
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: contentWidth,
          height: chainHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < devices.length; i++) ...[
                if (density != DeviceStripSlotDensity.collapsed) ...[
                  SizedBox(
                    width: DeviceStripMetrics.toolRailWidth,
                    child: ColoredBox(
                      color: DeviceStripTheme.toolRailBackground,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(DeviceStripTheme.toolRailRadius),
                            bottomLeft: Radius.circular(DeviceStripTheme.toolRailRadius),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                SizedBox(
                  width: density == DeviceStripSlotDensity.collapsed
                      ? DeviceChainLayout.slotWidthFor(devices[i], density)
                      : DeviceStripMetrics.designWidthFor(devices[i].type),
                  height: chainHeight,
                  child: DeviceStripCard(
                    deviceType: devices[i].type,
                    subtitle: null,
                    headerOnly: density == DeviceStripSlotDensity.collapsed,
                    attachToolRail: density != DeviceStripSlotDensity.collapsed,
                    bodyHeight: chainHeight -
                        DeviceStripTheme.cardChromeHeight -
                        DeviceStripTheme.cardBorderWidth * 2,
                    child: density == DeviceStripSlotDensity.collapsed
                        ? const SizedBox.shrink()
                        : const ColoredBox(color: DeviceStripTheme.cardBackground),
                  ),
                ),
                SizedBox(
                  width: DeviceStripMetrics.separatorWidth,
                  child: ColoredBox(
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
