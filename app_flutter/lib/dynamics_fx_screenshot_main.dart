import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'bridge/project_snapshot.dart';
import 'features/device_strip/device_container_tabs.dart';
import 'features/device_strip/device_strip_card.dart';
import 'features/device_strip/device_strip_metrics.dart';
import 'features/device_strip/device_strip_theme.dart';
import 'features/device_strip/device_strip_viewport.dart';
import 'features/device_strip/dynamics_fx_panels.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SemanticsBinding.instance.ensureSemantics();
  runApp(const DynamicsFxScreenshotApp());
}

DynamicsDeviceSnapshot _mockDevice(String type) {
  switch (type) {
    case 'gate':
      return const GateDeviceSnapshot(
        id: 'dev-gate',
        gain: 0.8,
        pan: 0.5,
        bypassed: false,
        meterGainReductionDb: 0.0,
        meterInputLevel: 0.0,
        inputGain: 1.0,
        gateThreshold: 0.45,
        gateAttack: 0.25,
        gateRelease: 0.50,
        gateHold: 0.20,
        gateRange: 0.0,
      );
    case 'compressor':
      return const CompressorDeviceSnapshot(
        id: 'dev-compressor',
        gain: 0.8,
        pan: 0.5,
        bypassed: false,
        meterGainReductionDb: 0.0,
        meterInputLevel: 0.0,
        inputGain: 1.0,
        compThreshold: 0.55,
        compRatio: 0.50,
        compAttack: 0.20,
        compRelease: 0.55,
        compKnee: 0.25,
        compMakeup: 0.35,
      );
    case 'expander':
      return const ExpanderDeviceSnapshot(
        id: 'dev-expander',
        gain: 0.8,
        pan: 0.5,
        bypassed: false,
        meterGainReductionDb: 0.0,
        meterInputLevel: 0.0,
        inputGain: 1.0,
        expandThreshold: 0.40,
        expandRatio: 0.45,
        expandAttack: 0.25,
        expandRelease: 0.55,
        expandRange: 0.15,
      );
    case 'limiter':
      return const LimiterDeviceSnapshot(
        id: 'dev-limiter',
        gain: 0.8,
        pan: 0.5,
        bypassed: false,
        meterGainReductionDb: 0.0,
        meterInputLevel: 0.0,
        inputGain: 1.0,
        limitCeiling: 0.85,
        limitAttack: 0.10,
        limitRelease: 0.40,
        limitKnee: 0.0,
        limitDrive: 0.0,
        limitMakeup: 0.0,
      );
    default:
      throw ArgumentError('Unknown mock dynamics type: $type');
  }
}

Widget _dynamicsCard({
  required String type,
  required Widget panel,
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
      selectedTabIndex: 0,
      child: DeviceStripViewport(
        shrinkWrap: true,
        designWidth: width,
        designHeight: bodyHeight,
        child: panel,
      ),
    ),
  );
}

class DynamicsFxScreenshotApp extends StatelessWidget {
  const DynamicsFxScreenshotApp({super.key});

  @override
  Widget build(BuildContext context) {
    void noop(String _, double __) {}

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0E0E14),
        useMaterial3: true,
      ),
      home: Scaffold(
        backgroundColor: const Color(0xFF0E0E14),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _section(
                id: 'picker',
                title: 'Device picker — Effects',
                width: 400,
                height: 400,
                child: Container(
                  width: 400,
                  color: const Color(0xFF1A1A22),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Text(
                          'Insert device',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
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
                ),
              ),
              _section(
                id: 'gate',
                title: 'Gate — Detect',
                width: 360,
                height: 320,
                child: _dynamicsCard(
                  type: 'gate',
                  panel: GateDeviceStrip(
                    device: _mockDevice('gate') as GateDeviceSnapshot,
                    onParameterChanged: noop,
                    selectedTab: GateDeviceTab.detect,
                  ),
                ),
              ),
              _section(
                id: 'compressor',
                title: 'Compressor — Comp',
                width: 360,
                height: 320,
                child: _dynamicsCard(
                  type: 'compressor',
                  panel: CompressorDeviceStrip(
                    device: _mockDevice('compressor') as CompressorDeviceSnapshot,
                    onParameterChanged: noop,
                    selectedTab: CompressorDeviceTab.comp,
                  ),
                ),
              ),
              _section(
                id: 'expander',
                title: 'Expander — Expand',
                width: 360,
                height: 320,
                child: _dynamicsCard(
                  type: 'expander',
                  panel: ExpanderDeviceStrip(
                    device: _mockDevice('expander') as ExpanderDeviceSnapshot,
                    onParameterChanged: noop,
                    selectedTab: ExpanderDeviceTab.expand,
                  ),
                ),
              ),
              _section(
                id: 'limiter',
                title: 'Limiter — Ceiling',
                width: 360,
                height: 320,
                child: _dynamicsCard(
                  type: 'limiter',
                  panel: LimiterDeviceStrip(
                    device: _mockDevice('limiter') as LimiterDeviceSnapshot,
                    onParameterChanged: noop,
                    selectedTab: LimiterDeviceTab.ceiling,
                  ),
                ),
              ),
              _section(
                id: 'chain',
                title: 'Dynamics chain row',
                width: 1504,
                height: 320,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _dynamicsCard(
                      type: 'gate',
                      panel: GateDeviceStrip(
                        device: _mockDevice('gate') as GateDeviceSnapshot,
                        onParameterChanged: noop,
                        selectedTab: GateDeviceTab.detect,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _dynamicsCard(
                      type: 'compressor',
                      panel: CompressorDeviceStrip(
                        device: _mockDevice('compressor') as CompressorDeviceSnapshot,
                        onParameterChanged: noop,
                        selectedTab: CompressorDeviceTab.comp,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _dynamicsCard(
                      type: 'expander',
                      panel: ExpanderDeviceStrip(
                        device: _mockDevice('expander') as ExpanderDeviceSnapshot,
                        onParameterChanged: noop,
                        selectedTab: ExpanderDeviceTab.expand,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _dynamicsCard(
                      type: 'limiter',
                      panel: LimiterDeviceStrip(
                        device: _mockDevice('limiter') as LimiterDeviceSnapshot,
                        onParameterChanged: noop,
                        selectedTab: LimiterDeviceTab.ceiling,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section({
    required String id,
    required String title,
    required Widget child,
    required double width,
    required double height,
  }) {
    return Semantics(
      identifier: id,
      label: id,
      container: true,
      child: SizedBox(
        width: width,
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF9A9AA8),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
