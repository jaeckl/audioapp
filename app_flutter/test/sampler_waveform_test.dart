import 'package:audioapp/features/device_strip/sampler_waveform_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatSamplerMidiNote maps middle C', () {
    expect(formatSamplerMidiNote(60), 'C4');
    expect(formatSamplerMidiNote(48), 'C3');
  });

  test('formatSamplerFineTune formats cents', () {
    expect(formatSamplerFineTune(0), '0¢');
    expect(formatSamplerFineTune(12), '+12¢');
    expect(formatSamplerFineTune(-5), '-5¢');
  });

  test('formatSamplerPlaybackRange labels modes', () {
    expect(
      formatSamplerPlaybackRange(
        playbackMode: 1,
        durationSec: 2.0,
        trimStartSec: 0,
        trimEndSec: 2.0,
        regionStartSec: 0.4,
        regionEndSec: 0.92,
      ),
      'Loop 0.40s–0.92s',
    );
    expect(
      formatSamplerPlaybackRange(
        playbackMode: 2,
        durationSec: 1.0,
        trimStartSec: 0.1,
        trimEndSec: 0.8,
        regionStartSec: 0,
        regionEndSec: 0,
      ),
      'Rev 0.10s–0.80s',
    );
  });

  testWidgets('SamplerPlaybackIdentityBar toggles playback mode', (tester) async {
    var mode = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SamplerPlaybackIdentityBar(
            rootPitch: 60,
            rootFineTune: 0,
            playbackMode: mode,
            accentColor: Colors.orange,
            onRootPitchChanged: (_) {},
            onRootFineTuneChanged: (_) {},
            onPlaybackModeChanged: (next) => mode = next,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Loop'));
    await tester.pump();
    expect(mode, 1);

    await tester.tap(find.text('Shot'));
    await tester.pump();
    expect(mode, 0);

    await tester.tap(find.text('Rev'));
    await tester.pump();
    expect(mode, 2);
  });

  testWidgets('SamplerWaveformView load sample CTA invokes callback', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 140,
            child: SamplerWaveformView(
              peaks: const [],
              durationSec: 1,
              trimStartSec: 0,
              trimEndSec: 0,
              regionStartSec: 0,
              regionEndSec: 0,
              density: SamplerWaveformDensity.editor,
              waveColor: Colors.green,
              accentColor: Colors.orange,
              onLoadSample: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Load sample'), findsOneWidget);
    await tester.tap(find.text('Load sample'));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('SamplerFineTuneChip adjusts cents', (tester) async {
    var cents = 0.0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return SamplerFineTuneChip(
                rootFineTune: cents,
                accentColor: Colors.orange,
                onChanged: (next) => setState(() => cents = next),
                fixedHeight: 48,
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.keyboard_arrow_up_rounded));
    await tester.pump();
    expect(cents, 1);

    await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
    await tester.pump();
    expect(cents, -1);
  });
}
