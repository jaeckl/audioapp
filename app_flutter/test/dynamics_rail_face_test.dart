import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/device_strip/dynamics_fx_panels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {double width = 424}) => MaterialApp(
      home: Scaffold(
        body: SizedBox(width: width, height: 280, child: child),
      ),
    );

void main() {
  testWidgets('compressor rail face: time rails + curve plate', (tester) async {
    await tester.pumpWidget(_host(CompressorDevicePanel(
      device: const CompressorDeviceSnapshot(
        id: 'c1',
        gain: 1,
        pan: .5,
        bypassed: false,
        meterGainReductionDb: 0,
        meterInputLevel: 0,
        inputGain: 1,
        compThreshold: .55,
        compRatio: .5,
        compAttack: .2,
        compRelease: .55,
        compKnee: .25,
        compMakeup: .35,
      ),
      onParameterChanged: (_, __) {},
    )));
    for (final label in [
      'Attack',
      'Release',
      'Threshold',
      'Ratio',
      'Knee',
      'Makeup',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(CompressorDevicePanel.designWidth, 424);
    expect(tester.takeException(), isNull);
  });

  testWidgets('limiter rail face: ceiling/drive on plate', (tester) async {
    await tester.pumpWidget(_host(LimiterDevicePanel(
      device: const LimiterDeviceSnapshot(
        id: 'l1',
        gain: 1,
        pan: .5,
        bypassed: false,
        meterGainReductionDb: 0,
        meterInputLevel: 0,
        inputGain: 1,
        limitCeiling: .85,
        limitAttack: .15,
        limitRelease: .4,
        limitKnee: .2,
        limitDrive: .3,
        limitMakeup: .25,
      ),
      onParameterChanged: (_, __) {},
    )));
    for (final label in [
      'Attack',
      'Release',
      'Ceiling',
      'Drive',
      'Knee',
      'Makeup',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(LimiterDevicePanel.designWidth, 424);
    expect(tester.takeException(), isNull);
  });

  testWidgets('expander rail face: single timing rail, floor on plate',
      (tester) async {
    await tester.pumpWidget(_host(
      ExpanderDevicePanel(
        device: const ExpanderDeviceSnapshot(
          id: 'e1',
          gain: 1,
          pan: .5,
          bypassed: false,
          meterGainReductionDb: 0,
          meterInputLevel: 0,
          inputGain: 1,
          expandThreshold: .45,
          expandRatio: .4,
          expandAttack: .2,
          expandRelease: .5,
          expandRange: .3,
        ),
        onParameterChanged: (_, __) {},
      ),
      width: 340,
    ));
    for (final label in [
      'Attack',
      'Release',
      'Threshold',
      'Ratio',
      'Floor',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(ExpanderDevicePanel.designWidth, 340);
    expect(tester.takeException(), isNull);
  });

  testWidgets('gate rail face: single timing rail + threshold/floor plate',
      (tester) async {
    await tester.pumpWidget(_host(
      GateDevicePanel(
        device: const GateDeviceSnapshot(
          id: 'g1',
          gain: 1,
          pan: .5,
          bypassed: false,
          meterGainReductionDb: 0,
          meterInputLevel: 0,
          inputGain: 1,
          gateThreshold: .45,
          gateAttack: .25,
          gateRelease: .5,
          gateHold: .2,
          gateRange: .1,
        ),
        onParameterChanged: (_, __) {},
      ),
      width: 340,
    ));
    for (final label in [
      'Attack',
      'Hold',
      'Release',
      'Threshold',
      'Floor',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(GateDevicePanel.designWidth, 340);
    expect(tester.takeException(), isNull);
  });
}
