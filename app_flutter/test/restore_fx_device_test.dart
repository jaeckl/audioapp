import 'package:audioapp/bridge/device_snapshot.dart';
import 'package:audioapp/devices/device_repository.dart';
import 'package:audioapp/features/device_strip/device_strip_metrics.dart';
import 'package:audioapp/features/device_strip/restore_fx_panels.dart';
import 'package:audioapp/features/device_strip/rotary_knob.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('snapshot defaults', () {
    test('dc_offset', () {
      final d = DeviceSnapshot.fromMap({
        'id': 'dc-1',
        'type': 'dc_offset',
        'parameters': {},
      }) as DcOffsetDeviceSnapshot;
      expect(d.dcMode, 1.0);
      expect(d.dcAmount, 1.0);
      expect(d.dcCutoff, 0.3);
    });

    test('de_crackler', () {
      final d = DeviceSnapshot.fromMap({
        'id': 'cr-1',
        'type': 'de_crackler',
        'parameters': {},
      }) as DeCracklerDeviceSnapshot;
      expect(d.crackSense, 0.5);
      expect(d.crackStrength, 0.6);
      expect(d.crackWidth, 0.4);
    });

    test('de_esser', () {
      final d = DeviceSnapshot.fromMap({
        'id': 'de-1',
        'type': 'de_esser',
        'parameters': {},
      }) as DeEsserDeviceSnapshot;
      expect(d.deFreq, 0.55);
      expect(d.deThresh, 0.45);
      expect(d.deAmount, 0.5);
      expect(d.deListen, 0.0);
    });

    test('de_hum', () {
      final d = DeviceSnapshot.fromMap({
        'id': 'hum-1',
        'type': 'de_hum',
        'parameters': {},
      }) as DeHumDeviceSnapshot;
      expect(d.humMains, 0.0);
      expect(d.humDepth, 0.7);
      expect(d.humHarmonics, 0.4);
    });

    test('de_noise', () {
      final d = DeviceSnapshot.fromMap({
        'id': 'dn-1',
        'type': 'de_noise',
        'parameters': {},
      }) as DeNoiseDeviceSnapshot;
      expect(d.dnThresh, 0.35);
      expect(d.dnReduce, 0.5);
      expect(d.dnSmooth, 0.4);
    });
  });

  group('withParameter engine ids + JSON aliases', () {
    test('dc_offset', () {
      final base = DeviceSnapshot.fromMap({
        'id': 'dc',
        'type': 'dc_offset',
      }) as DcOffsetDeviceSnapshot;
      expect(base.withParameter('dcMode', 0.0).dcMode, 0.0);
      expect(base.withParameter('mode', 0.0).dcMode, 0.0);
      expect(base.withParameter('dcAmount', 0.4).dcAmount, 0.4);
      expect(base.withParameter('amount', 0.4).dcAmount, 0.4);
      expect(base.withParameter('dcCutoff', 0.9).dcCutoff, 0.9);
      expect(base.withParameter('cutoff', 0.9).dcCutoff, 0.9);
      expect(identical(base.withParameter('unknown', 1.0), base), isTrue);
    });

    test('de_crackler', () {
      final base = DeviceSnapshot.fromMap({
        'id': 'cr',
        'type': 'de_crackler',
      }) as DeCracklerDeviceSnapshot;
      expect(base.withParameter('crackSense', 0.1).crackSense, 0.1);
      expect(base.withParameter('sensitivity', 0.2).crackSense, 0.2);
      expect(base.withParameter('crackStrength', 0.3).crackStrength, 0.3);
      expect(base.withParameter('strength', 0.4).crackStrength, 0.4);
      expect(base.withParameter('crackWidth', 0.5).crackWidth, 0.5);
      expect(base.withParameter('width', 0.6).crackWidth, 0.6);
    });

    test('de_esser', () {
      final base = DeviceSnapshot.fromMap({
        'id': 'de',
        'type': 'de_esser',
      }) as DeEsserDeviceSnapshot;
      expect(base.withParameter('deFreq', 0.1).deFreq, 0.1);
      expect(base.withParameter('freq', 0.2).deFreq, 0.2);
      expect(base.withParameter('deThresh', 0.3).deThresh, 0.3);
      expect(base.withParameter('threshold', 0.4).deThresh, 0.4);
      expect(base.withParameter('deAmount', 0.5).deAmount, 0.5);
      expect(base.withParameter('amount', 0.6).deAmount, 0.6);
      expect(base.withParameter('deListen', 1.0).deListen, 1.0);
      expect(base.withParameter('listen', 1.0).deListen, 1.0);
    });

    test('de_hum', () {
      final base = DeviceSnapshot.fromMap({
        'id': 'hum',
        'type': 'de_hum',
      }) as DeHumDeviceSnapshot;
      expect(base.withParameter('humMains', 1.0).humMains, 1.0);
      expect(base.withParameter('mainsFreq', 1.0).humMains, 1.0);
      expect(base.withParameter('humDepth', 0.2).humDepth, 0.2);
      expect(base.withParameter('depth', 0.3).humDepth, 0.3);
      expect(base.withParameter('humHarmonics', 0.9).humHarmonics, 0.9);
      expect(base.withParameter('harmonics', 0.8).humHarmonics, 0.8);
    });

    test('de_noise', () {
      final base = DeviceSnapshot.fromMap({
        'id': 'dn',
        'type': 'de_noise',
      }) as DeNoiseDeviceSnapshot;
      expect(base.withParameter('dnThresh', 0.1).dnThresh, 0.1);
      expect(base.withParameter('threshold', 0.2).dnThresh, 0.2);
      expect(base.withParameter('dnReduce', 0.3).dnReduce, 0.3);
      expect(base.withParameter('reduction', 0.4).dnReduce, 0.4);
      expect(base.withParameter('dnSmooth', 0.5).dnSmooth, 0.5);
      expect(base.withParameter('smoothing', 0.6).dnSmooth, 0.6);
    });
  });

  group('layout chrome widths', () {
    test('design widths and output rails', () {
      expect(DeviceStripMetrics.designWidthFor('dc_offset'), 96);
      expect(DeviceStripMetrics.designWidthFor('de_crackler'), 96);
      expect(DeviceStripMetrics.designWidthFor('de_esser'), 96);
      expect(DeviceStripMetrics.designWidthFor('de_hum'), 96);
      expect(DeviceStripMetrics.designWidthFor('de_noise'), 96);

      expect(DeviceStripMetrics.outputPanelWidthFor('dc_offset'), 30);
      expect(DeviceStripMetrics.outputPanelWidthFor('de_crackler'), 30);
      expect(DeviceStripMetrics.outputPanelWidthFor('de_esser'), 64);
      expect(DeviceStripMetrics.outputPanelWidthFor('de_hum'), 64);
      expect(DeviceStripMetrics.outputPanelWidthFor('de_noise'), 64);
    });

    test('definitions registered in picker repo', () {
      expect(deviceDefinitionRepository.find('dc_offset'), isNotNull);
      expect(deviceDefinitionRepository.find('de_crackler'), isNotNull);
      expect(deviceDefinitionRepository.find('de_esser'), isNotNull);
      expect(deviceDefinitionRepository.find('de_hum'), isNotNull);
      expect(deviceDefinitionRepository.find('de_noise'), isNotNull);
      expect(
        deviceDefinitionRepository.find('dc_offset')!.picker.category,
        'Restore Effects',
      );
    });
  });

  testWidgets('dc offset body combo fires mode change', (tester) async {
    final device = DcOffsetDeviceSnapshot(
      id: 'dc-1',
      gain: 1,
      pan: 0.5,
      bypassed: false,
      meterGainReductionDb: 0,
      meterInputLevel: 0,
      dcMode: 1,
      dcAmount: 1,
      dcCutoff: 0.3,
    );
    final changes = <(String, double)>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 100,
          height: 280,
          child: DcOffsetFxPanel(
            device: device,
            onParameterChanged: (id, v) => changes.add((id, v)),
            onModulationAssign: null,
          ),
        ),
      ),
    ));
    await tester.tap(find.byKey(const ValueKey('dc-mode-combo')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mean').last);
    await tester.pumpAndSettle();
    expect(changes.any((c) => c.$1 == 'dcMode' && c.$2 == 0.0), isTrue);
  });

  testWidgets('de-hum combo fires mains change', (tester) async {
    final changes = <(String, double)>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 100,
          height: 280,
          child: DeHumFxPanel(
            device: const DeHumDeviceSnapshot(
              id: 'hum',
              gain: 1,
              pan: 0.5,
              bypassed: false,
              meterGainReductionDb: 0,
              meterInputLevel: 0,
              humMains: 0,
              humDepth: 0.7,
              humHarmonics: 0.4,
            ),
            onParameterChanged: (id, v) => changes.add((id, v)),
            onModulationAssign: null,
          ),
        ),
      ),
    ));
    await tester.tap(find.byKey(const ValueKey('hum-mains-combo')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('60 Hz').last);
    await tester.pumpAndSettle();
    expect(changes.any((c) => c.$1 == 'humMains' && c.$2 == 1.0), isTrue);
  });

  testWidgets('restore panels fit tight body without overflow', (tester) async {
    FlutterError.onError = (details) {
      final msg = details.toString();
      if (msg.contains('overflowed') || msg.contains('OVERFLOWING')) {
        fail(msg);
      }
      FlutterError.presentError(details);
    };

    Future<void> pumpPanel(Widget panel) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 88, height: 220, child: panel),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    await pumpPanel(DcOffsetFxPanel(
      device: const DcOffsetDeviceSnapshot(
        id: 'dc',
        gain: 1,
        pan: 0.5,
        bypassed: false,
        meterGainReductionDb: 0,
        meterInputLevel: 0,
        dcMode: 1,
        dcAmount: 1,
        dcCutoff: 0.3,
      ),
      onParameterChanged: (_, __) {},
      onModulationAssign: null,
    ));
    await pumpPanel(DeCracklerFxPanel(
      device: const DeCracklerDeviceSnapshot(
        id: 'cr',
        gain: 1,
        pan: 0.5,
        bypassed: false,
        meterGainReductionDb: 0,
        meterInputLevel: 0,
        crackSense: 0.5,
        crackStrength: 0.5,
        crackWidth: 0.5,
      ),
      onParameterChanged: (_, __) {},
      onModulationAssign: null,
    ));
    await pumpPanel(DeEsserFxPanel(
      device: const DeEsserDeviceSnapshot(
        id: 'de',
        gain: 1,
        pan: 0.5,
        bypassed: false,
        meterGainReductionDb: 0,
        meterInputLevel: 0,
        deFreq: 0.5,
        deThresh: 0.5,
        deAmount: 0.5,
        deListen: 0,
      ),
      onParameterChanged: (_, __) {},
      onModulationAssign: null,
    ));
    await pumpPanel(DeHumFxPanel(
      device: const DeHumDeviceSnapshot(
        id: 'hum',
        gain: 1,
        pan: 0.5,
        bypassed: false,
        meterGainReductionDb: 0,
        meterInputLevel: 0,
        humMains: 0,
        humDepth: 0.7,
        humHarmonics: 0.4,
      ),
      onParameterChanged: (_, __) {},
      onModulationAssign: null,
    ));
    await pumpPanel(DeNoiseFxPanel(
      device: const DeNoiseDeviceSnapshot(
        id: 'dn',
        gain: 1,
        pan: 0.5,
        bypassed: false,
        meterGainReductionDb: 0,
        meterInputLevel: 0,
        dnThresh: 0.5,
        dnReduce: 0.5,
        dnSmooth: 0.5,
      ),
      onParameterChanged: (_, __) {},
      onModulationAssign: null,
    ));
  });

  testWidgets('de-hum combo long-press requests automate', (tester) async {
    String? automated;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 96,
          height: 280,
          child: DeHumFxPanel(
            device: const DeHumDeviceSnapshot(
              id: 'hum',
              gain: 1,
              pan: 0.5,
              bypassed: false,
              meterGainReductionDb: 0,
              meterInputLevel: 0,
              humMains: 0,
              humDepth: 0.7,
              humHarmonics: 0.4,
            ),
            onParameterChanged: (_, __) {},
            onModulationAssign: null,
            onAutomateParameter: (id) => automated = id,
          ),
        ),
      ),
    ));
    await tester.longPress(find.byKey(const ValueKey('hum-mains-combo')));
    await tester.pumpAndSettle();
    expect(automated, 'humMains');
  });

  testWidgets('dc-mode combo long-press requests automate', (tester) async {
    String? automated;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 96,
          height: 280,
          child: DcOffsetFxPanel(
            device: const DcOffsetDeviceSnapshot(
              id: 'dc',
              gain: 1,
              pan: 0.5,
              bypassed: false,
              meterGainReductionDb: 0,
              meterInputLevel: 0,
              dcMode: 1,
              dcAmount: 1,
              dcCutoff: 0.3,
            ),
            onParameterChanged: (_, __) {},
            onModulationAssign: null,
            onAutomateParameter: (id) => automated = id,
          ),
        ),
      ),
    ));
    await tester.longPress(find.byKey(const ValueKey('dc-mode-combo')));
    await tester.pumpAndSettle();
    expect(automated, 'dcMode');
  });

  testWidgets('dc amount knob drag fires dcAmount', (tester) async {
    final changes = <(String, double)>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 100,
          height: 280,
          child: DcOffsetFxPanel(
            device: const DcOffsetDeviceSnapshot(
              id: 'dc',
              gain: 1,
              pan: 0.5,
              bypassed: false,
              meterGainReductionDb: 0,
              meterInputLevel: 0,
              dcMode: 1,
              dcAmount: 0.5,
              dcCutoff: 0.3,
            ),
            onParameterChanged: (id, v) => changes.add((id, v)),
            onModulationAssign: null,
          ),
        ),
      ),
    ));
    final amountKnob = find.byWidgetPredicate(
      (w) => w is RotaryKnob && w.label == 'Amount' && w.parameterId == 'dcAmount',
    );
    expect(amountKnob, findsOneWidget);
    await tester.drag(amountKnob, const Offset(0, -50));
    await tester.pumpAndSettle();
    expect(changes.any((c) => c.$1 == 'dcAmount' && c.$2 != 0.5), isTrue);
  });
}
