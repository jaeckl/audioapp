import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/device_strip/rotary_knob.dart';
import 'package:audioapp/features/device_strip/sampler_device_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Sampler Tone Cutoff knob long-press requests automation', (tester) async {
    String? automatedParam;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 320,
            child: SamplerDevicePanel(
              device: const DeviceSnapshot(
                id: 'sampler-1',
                type: 'simple_sampler',
                frequencyHz: 440,
                gain: 1,
                pan: 0.5,
                sampleId: 'sample_kick',
                attack: 0,
                decay: 0,
                sustain: 1,
                release: 0,
                filterCutoff: 0.8,
                filterQ: 0.5,
                filterMode: 0,
                trimStartSec: 0,
                trimEndSec: 0,
              ),
              sample: null,
              selectedTab: SamplerDeviceTab.tone,
              onParameterChanged: (_, __) {},
              onAutomateParameter: (paramId) {
                automatedParam = paramId;
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final cutoffKnob = find.descendant(
      of: find.byType(RotaryKnob),
      matching: find.text('Cutoff'),
    );
    expect(cutoffKnob, findsOneWidget);

    await tester.longPress(find.byWidgetPredicate(
      (widget) => widget is RotaryKnob && widget.label == 'Cutoff',
    ));
    await tester.pumpAndSettle();

    expect(automatedParam, 'filterCutoff');
  });
}
