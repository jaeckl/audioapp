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
              device: const SamplerDeviceSnapshot(
                id: 'sampler-1',
                gain: 1.0,
                pan: 0.5,
                bypassed: false,
                meterGainReductionDb: 0.0,
                meterInputLevel: 0.0,
                sampleId: 'sample_kick',
                attack: 0.0,
                decay: 0.0,
                sustain: 1.0,
                release: 0.0,
                filterCutoff: 0.8,
                filterQ: 0.5,
                filterMode: 0,
                trimStartSec: 0.0,
                trimEndSec: 0.0,
                filterEnvAmount: 0.0,
                filterAttack: 0.0,
                filterDecay: 0.0,
                filterSustain: 1.0,
                filterRelease: 0.0,
                playbackMode: 0,
                regionStartSec: 0.0,
                regionEndSec: 0.0,
                rootPitch: 60,
                rootFineTune: 0,
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
