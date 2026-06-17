import 'package:audioapp/features/device_strip/device_strip_metrics.dart';
import 'package:audioapp/features/device_strip/device_strip_viewport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DeviceStripViewport keeps design width in wide landscape', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            child: DeviceStripViewport(
              child: ColoredBox(
                key: key,
                color: Colors.red,
              ),
            ),
          ),
        ),
      ),
    );

    final box = tester.renderObject<RenderBox>(find.byKey(key));
    expect(box.size.width, DeviceStripMetrics.designWidth);
    expect(box.size.height, DeviceStripMetrics.height);
  });

  testWidgets('DeviceStripViewport scales down uniformly on narrow width', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final key = GlobalKey();
    const narrowWidth = 360.0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: narrowWidth,
            child: DeviceStripViewport(
              child: ColoredBox(
                key: key,
                color: Colors.red,
              ),
            ),
          ),
        ),
      ),
    );

    final viewportBox = tester.renderObject<RenderBox>(find.byType(DeviceStripViewport));
    final scale = narrowWidth / DeviceStripMetrics.designWidth;
    expect(viewportBox.size.width, narrowWidth);
    expect(viewportBox.size.height, closeTo(DeviceStripMetrics.height * scale, 0.5));
  });
}
