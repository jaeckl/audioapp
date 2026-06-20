import 'package:audioapp/bridge/engine_bridge.dart';
import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/automation/automation_curve_shapes.dart';
import 'package:audioapp/features/automation/automation_editor_screen.dart';
import 'package:audioapp/features/automation/automation_shape_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('insertAutomationShapeBetween replaces interior breakpoints only', () {
    const points = [
      AutomationPointSnapshot(beat: 0, value: 1),
      AutomationPointSnapshot(beat: 2, value: 0.5),
      AutomationPointSnapshot(beat: 4, value: 0.25),
    ];

    final result = insertAutomationShapeBetween(
      points: points,
      startBeat: 0,
      endBeat: 4,
      startValue: 1,
      endValue: 0.25,
      shape: AutomationCurveShape.sawUp,
      params: const AutomationShapeParams(cycles: 2),
    );

    expect(result.length, greaterThan(2));
    expect(result.first.beat, 0);
    expect(result.first.value, 1);
    expect(result.last.beat, 4);
    expect(result.last.value, 0.25);
    expect(
      result.any((p) => (p.beat - 2).abs() < 1e-4 && (p.value - 0.5).abs() < 1e-4),
      isFalse,
    );
  });

  testWidgets('Automation editor hides shape panel until insert mode', (tester) async {
    const channel = MethodChannel('com.audioapp.daw/engine');
    final bridge = EngineBridge(channel: channel);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'setAutomationPoints' || call.method == 'setClipLength') {
        return {
          'ok': true,
          'snapshot': {
            'bpm': 120,
            'playheadBeats': 0.0,
            'playing': false,
            'selectedTrackId': 'track-1',
            'tracks': [
              {
                'id': 'track-1',
                'name': 'Synth',
                'devices': [],
                'midiClips': [],
                'automationClips': [],
              },
            ],
            'automationClips': [
              {
                'id': 'aclip-1',
                'homeTrackId': 'track-1',
                'startBeat': 0.0,
                'lengthBeats': 4.0,
                'deviceId': 'dev-1',
                'paramId': 'filterCutoff',
                'points': [
                  {'beat': 0.0, 'value': 1.0},
                  {'beat': 4.0, 'value': 0.25},
                ],
              },
            ],
          },
        };
      }
      return {'ok': true};
    });

    const clip = AutomationClipSnapshot(
      id: 'aclip-1',
      homeTrackId: 'track-1',
      startBeat: 0,
      lengthBeats: 4,
      deviceId: 'dev-1',
      paramId: 'filterCutoff',
      points: [
        AutomationPointSnapshot(beat: 0, value: 1),
        AutomationPointSnapshot(beat: 4, value: 0.25),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AutomationEditorScreen(
          trackName: 'Synth',
          clip: clip,
          bridge: bridge,
          onSaved: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Insert shape'), findsNothing);
    expect(find.byType(AutomationShapeIcon), findsNothing);
    expect(find.text('Floor'), findsNothing);
    expect(find.text('1/16'), findsOneWidget);
  });
}
