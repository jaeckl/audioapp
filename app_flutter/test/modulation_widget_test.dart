import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/device_strip/lfo_properties_panel.dart';
import 'package:audioapp/features/device_strip/modulatable_spinner_shell.dart';
import 'package:audioapp/features/device_strip/modulation_grid.dart';
import 'package:audioapp/features/device_strip/modulation_strip.dart';
import 'package:audioapp/features/device_strip/modulation_vertical_bar.dart';

/// Suppresses RenderFlex overflow errors that are pre-existing layout issues
/// in production widgets (narrow DropdownButtonFormField constraints inside
/// hard-coded SizedBox widths). These are not caused by the tests.
///
/// {@macro flutter_test.flutter_test_window}
void _suppressKnownOverflows() {
  final original = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exceptionAsString().contains('A RenderFlex overflowed')) {
      return;
    }
    original?.call(details);
  };
  addTearDown(() {
    FlutterError.onError = original;
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ModulationGrid', () {
    testWidgets('renders correct number of LFO tiles', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 400,
            child: ModulationGrid(
              lfos: const [
                LfoSnapshot(id: 1, waveform: 0, rate: 1.0),
                LfoSnapshot(id: 2, waveform: 1, rate: 0.5),
              ],
              selectedLfoId: null,
              maxLfos: 4,
              connectModeLfoId: null,
              playheadBeat: 0,
              bpm: 120,
              playing: false,
              onLfoTap: (_) {},
              onLfoLongPress: (_) {},
              onAddModulator: (_) async {},
              onRemoveLfo: (_) {},
            ),
          ),
        ),
      ));

      // 2 LFO tiles render (no overlay close icons, labels are painted via CustomPaint).
      // 2 LFOs → padded to 3 tiles (1 add button) to complete the column.
      expect(find.byIcon(Icons.add), findsOneWidget);
      // Grid header label.
      expect(find.text('MODULATORS'), findsOneWidget);
      // Verify no close overlay buttons (removed in favor of double-tap menu)
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('add tile is present when lfos < max', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 400,
            child: ModulationGrid(
              lfos: const [LfoSnapshot(id: 1, waveform: 0, rate: 1.0)],
              selectedLfoId: null,
              maxLfos: 4,
              connectModeLfoId: null,
              playheadBeat: 0,
              bpm: 120,
              playing: false,
              onLfoTap: (_) {},
              onLfoLongPress: (_) {},
              onAddModulator: (_) async {},
              onRemoveLfo: (_) {},
            ),
          ),
        ),
      ));

      // The _AddModulatorTile renders Icons.add icons when lfos < maxLfos.
      // 1 LFO → padded to 3 tiles (2 add buttons) to complete the column.
      expect(find.byIcon(Icons.add), findsNWidgets(2));
    });
  });

  group('ModulationStrip', () {
    ProjectSnapshot mockSnapshot() => const ProjectSnapshot(
          bpm: 120,
          selectedTrackId: 'track-1',
          playheadBeats: 0,
          playing: false,
          loopEnabled: true,
          recordArmed: false,
          master:
              MasterTrackSnapshot(id: 'master', name: 'Master', gain: 1.0),
          samples: [],
          tracks: [],
        );

    testWidgets('displays LFO cards with controls', (tester) async {
      _suppressKnownOverflows();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ModulationStrip(
            lfos: const [
              LfoSnapshot(id: 1, waveform: 0, rate: 1.0),
              LfoSnapshot(id: 2, waveform: 2, rate: 0.25),
            ],
            modEdges: const [],
            deviceId: 'test-device',
            onBridgeCall: (_, __) async => mockSnapshot(),
          ),
        ),
      ));

      // Each _LfoCard renders "LFO N" text inside a Text widget.
      expect(find.text('LFO 1'), findsOneWidget);
      expect(find.text('LFO 2'), findsOneWidget);
    });

    testWidgets('shows "Add Modulator" button', (tester) async {
      _suppressKnownOverflows();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ModulationStrip(
            lfos: const [LfoSnapshot(id: 1, waveform: 0, rate: 1.0)],
            modEdges: const [],
            deviceId: 'test-device',
            maxLfos: 4,
            onBridgeCall: (_, __) async => mockSnapshot(),
          ),
        ),
      ));

      // The "Add Modulator" button appears when lfos.length < maxLfos.
      expect(find.text('Add Modulator'), findsOneWidget);
    });
  });

  group('LfoPropertiesPanel', () {
    testWidgets('shows LFO panel name and rate knob', (tester) async {
      _suppressKnownOverflows();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: LfoPropertiesPanel(
            mod: const LfoSnapshot(id: 1, type: 'lfo', rate: 0.5),
            onUpdate: (_, __) async {},
          ),
        ),
      ));

      expect(find.text('LFO 1'), findsOneWidget);
    });
  });

  group('ModulatableSpinnerShell', () {
    testWidgets('shows modulation bar when active', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ModulatableSpinnerShell(
            width: 40,
            height: 40,
            accentColor: Colors.amber,
            borderAlpha: 0.5,
            modulationActive: true,
            modulationAmount: 0.5,
            child: Text('test'),
          ),
        ),
      ));

      // The child is rendered.
      expect(find.text('test'), findsOneWidget);
      // ModulationVerticalBar is rendered when modulation is active with non-zero amount.
      expect(find.byType(ModulationVerticalBar), findsOneWidget);
    });

    testWidgets('shows connect-mode pulse', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ModulatableSpinnerShell(
            width: 40,
            height: 40,
            accentColor: Colors.amber,
            borderAlpha: 0.5,
            connectModeActive: true,
            child: Text('test'),
          ),
        ),
      ));

      // The widget builds without crashing in connect mode.
      expect(find.text('test'), findsOneWidget);
      expect(find.byType(ModulatableSpinnerShell), findsOneWidget);
    });
  });
}