import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/device_strip/device_container_tabs.dart';
import 'package:audioapp/features/device_strip/device_strip_card.dart';
import 'package:audioapp/features/device_strip/device_strip_metrics.dart';
import 'package:audioapp/features/device_strip/device_strip_theme.dart';
import 'package:audioapp/features/device_strip/device_strip_viewport.dart';
import 'package:audioapp/features/device_strip/dynamics_fx_panels.dart';

const _outputDir = '../docs/design/dynamics_fx/screenshots';

DeviceSnapshot _mockDevice(String type) {
  return DeviceSnapshot(
    id: 'dev-$type',
    type: type,
    frequencyHz: 440,
    gain: 0.8,
    pan: 0.5,
    sampleId: '',
    attack: 0.01,
    decay: 0.2,
    sustain: 0.8,
    release: 0.3,
    filterCutoff: 0.7,
    filterQ: 0.3,
    filterMode: 0,
    trimStartSec: 0,
    trimEndSec: 0,
  );
}

Future<void> _capturePng(WidgetTester tester, Key boundaryKey, String filename) async {
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(boundaryKey),
  );
  final image = await boundary.toImage(pixelRatio: 2.0);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  expect(byteData, isNotNull);

  final dir = Directory(_outputDir);
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  final file = File('$_outputDir/$filename');
  await file.writeAsBytes(byteData!.buffer.asUint8List());
}

Widget _screenshotShell({required Size size, required Key boundaryKey, required Widget child}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0E0E14),
      useMaterial3: true,
    ),
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: Scaffold(
        backgroundColor: const Color(0xFF0E0E14),
        body: Center(
          child: RepaintBoundary(key: boundaryKey, child: child),
        ),
      ),
    ),
  );
}

Widget _dynamicsCard({
  required String type,
  required Widget panel,
  int tabIndex = 0,
}) {
  const cardHeight = DeviceStripMetrics.height;
  const bodyHeight = cardHeight - DeviceStripTheme.cardChromeHeight;
  final width = DeviceStripMetrics.designWidthFor(type);

  return SizedBox(
    width: width,
    height: cardHeight,
    child: DeviceStripCard(
      deviceType: type,
      subtitle: 'Stereo · FX',
      bodyHeight: bodyHeight,
      tabs: DeviceContainerTabs.forDeviceType(type),
      selectedTabIndex: tabIndex,
      child: DeviceStripViewport(
        shrinkWrap: true,
        designWidth: width,
        designHeight: bodyHeight,
        child: panel,
      ),
    ),
  );
}

Widget _effectsPickerPreview() {
  return Container(
    width: 400,
    color: const Color(0xFF1A1A22),
    padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
    child: const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Text('Insert device', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Text(
            'Effects',
            style: TextStyle(
              color: Color(0xFF9A9AA8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
        ),
        ListTile(
          leading: Icon(Icons.door_sliding, color: Color(0xFF6EC9A8)),
          title: Text('Gate'),
          subtitle: Text('Noise gate · threshold & hold'),
        ),
        ListTile(
          leading: Icon(Icons.compress, color: Color(0xFFE8A54B)),
          title: Text('Compressor'),
          subtitle: Text('Downward · ratio & makeup'),
        ),
        ListTile(
          leading: Icon(Icons.unfold_more, color: Color(0xFF9AD4E8)),
          title: Text('Expander'),
          subtitle: Text('Downward · below threshold'),
        ),
        ListTile(
          leading: Icon(Icons.horizontal_rule, color: Color(0xFFE85D4B)),
          title: Text('Limiter'),
          subtitle: Text('Brick-wall ceiling · track bus'),
        ),
      ],
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'capture dynamics FX screenshots',
    (tester) async {
    const boundaryKey = Key('screenshot_boundary');
    void noop(String _, double __) {}

    // Device picker — Effects section
    await tester.binding.setSurfaceSize(const Size(420, 520));
    await tester.pumpWidget(
      _screenshotShell(
        boundaryKey: boundaryKey,
        size: const Size(420, 520),
        child: _effectsPickerPreview(),
      ),
    );
    await _capturePng(tester, boundaryKey, '01_device_picker_effects.png');

    final device = _mockDevice('gate');

    // Gate — Detect tab
    await tester.binding.setSurfaceSize(const Size(400, 340));
    await tester.pumpWidget(
      _screenshotShell(
        boundaryKey: boundaryKey,
        size: const Size(400, 340),
        child: _dynamicsCard(
          type: 'gate',
          panel: GateDeviceStrip(
            device: device,
            onParameterChanged: noop,
            selectedTab: GateDeviceTab.detect,
          ),
        ),
      ),
    );
    await _capturePng(tester, boundaryKey, '02_gate_detect.png');

    // Compressor — Comp tab
    await tester.pumpWidget(
      _screenshotShell(
        boundaryKey: boundaryKey,
        size: const Size(400, 340),
        child: _dynamicsCard(
          type: 'compressor',
          panel: CompressorDeviceStrip(
            device: _mockDevice('compressor'),
            onParameterChanged: noop,
            selectedTab: CompressorDeviceTab.comp,
          ),
        ),
      ),
    );
    await _capturePng(tester, boundaryKey, '03_compressor_comp.png');

    // Expander — Expand tab
    await tester.pumpWidget(
      _screenshotShell(
        boundaryKey: boundaryKey,
        size: const Size(400, 340),
        child: _dynamicsCard(
          type: 'expander',
          panel: ExpanderDeviceStrip(
            device: _mockDevice('expander'),
            onParameterChanged: noop,
            selectedTab: ExpanderDeviceTab.expand,
          ),
        ),
      ),
    );
    await _capturePng(tester, boundaryKey, '04_expander_expand.png');

    // Limiter — Ceiling tab
    await tester.pumpWidget(
      _screenshotShell(
        boundaryKey: boundaryKey,
        size: const Size(400, 340),
        child: _dynamicsCard(
          type: 'limiter',
          panel: LimiterDeviceStrip(
            device: _mockDevice('limiter'),
            onParameterChanged: noop,
            selectedTab: LimiterDeviceTab.ceiling,
          ),
        ),
      ),
    );
    await _capturePng(tester, boundaryKey, '05_limiter_ceiling.png');

    // Full dynamics chain row
    const rowHeight = DeviceStripMetrics.height;
    const slotWidth = DeviceStripMetrics.oscillatorDesignWidth;
    const rowWidth = slotWidth * 4 + 24;

    await tester.binding.setSurfaceSize(Size(rowWidth + 32, rowHeight + 32));
    await tester.pumpWidget(
      _screenshotShell(
        boundaryKey: boundaryKey,
        size: Size(rowWidth + 32, rowHeight + 32),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dynamicsCard(
              type: 'gate',
              panel: GateDeviceStrip(
                device: _mockDevice('gate'),
                onParameterChanged: noop,
                selectedTab: GateDeviceTab.detect,
              ),
            ),
            const SizedBox(width: 8),
            _dynamicsCard(
              type: 'compressor',
              panel: CompressorDeviceStrip(
                device: _mockDevice('compressor'),
                onParameterChanged: noop,
                selectedTab: CompressorDeviceTab.comp,
              ),
            ),
            const SizedBox(width: 8),
            _dynamicsCard(
              type: 'expander',
              panel: ExpanderDeviceStrip(
                device: _mockDevice('expander'),
                onParameterChanged: noop,
                selectedTab: ExpanderDeviceTab.expand,
              ),
            ),
            const SizedBox(width: 8),
            _dynamicsCard(
              type: 'limiter',
              panel: LimiterDeviceStrip(
                device: _mockDevice('limiter'),
                onParameterChanged: noop,
                selectedTab: LimiterDeviceTab.ceiling,
              ),
            ),
          ],
        ),
      ),
    );
    await _capturePng(tester, boundaryKey, '06_dynamics_chain_row.png');
  }, skip: true); // RepaintBoundary.toImage() hangs headless; use tools/capture_dynamics_screenshots.py
}
