import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/device_strip/time_fx_panels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ReverbDeviceSnapshot _reverb({double modeMorph = 2}) => ReverbDeviceSnapshot(
      id: 'reverb-1',
      gain: 1,
      pan: .5,
      bypassed: false,
      meterGainReductionDb: 0,
      meterInputLevel: 0,
      outputMix: .35,
      outputWidth: 1,
      modeMorph: modeMorph,
    );

Widget _host(ReverbDeviceSnapshot device, void Function(String, double) changed,
        {ReverbViewTab selectedTab = ReverbViewTab.tail}) =>
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: ReverbFxPanel.designWidth,
          height: 280,
          child: ReverbFxPanel(
            device: device,
            onParameterChanged: changed,
            selectedTab: selectedTab,
          ),
        ),
      ),
    );

void main() {
  testWidgets('version C uses a large editor and right parameter column',
      (tester) async {
    final changes = <(String, double)>[];
    await tester.pumpWidget(_host(_reverb(), (id, value) {
      changes.add((id, value));
    }));

    for (final label in ['Decay', 'Pre-delay', 'Size', 'Diffusion', 'Mod']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(
        find.byKey(const ValueKey('reverb-response-editor')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('reverb-parameter-column')), findsOneWidget);
    expect(ReverbFxPanel.designWidth, 320);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tone screen edits wet-path ducking without another row',
      (tester) async {
    final changes = <(String, double)>[];
    await tester.pumpWidget(_host(
      _reverb(),
      (id, value) => changes.add((id, value)),
      selectedTab: ReverbViewTab.tone,
    ));
    final editor = find.byKey(const ValueKey('reverb-response-editor'));
    final topLeft = tester.getTopLeft(editor);
    final size = tester.getSize(editor);
    await tester.dragFrom(
      topLeft + Offset(size.width * .4, size.height - 7),
      const Offset(35, 0),
    );
    await tester.pump();
    expect(changes.any((change) => change.$1 == 'ducking'), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('preview handles win horizontal drags over strip scrolling',
      (tester) async {
    final changes = <(String, double)>[];
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: ReverbFxPanel.designWidth,
          height: 280,
          child: SingleChildScrollView(
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: ReverbFxPanel.designWidth + 200,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: ReverbFxPanel.designWidth,
                  child: ReverbFxPanel(
                    device: _reverb(),
                    onParameterChanged: (id, value) => changes.add((id, value)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ));
    final editor = find.byKey(const ValueKey('reverb-response-editor'));
    await tester.dragFrom(
      tester.getCenter(editor),
      const Offset(40, 0),
    );
    await tester.pumpAndSettle();
    expect(changes, isNotEmpty);
    expect(scrollController.offset, 0);
  });

  testWidgets('header actions select algorithm and toggle freeze',
      (tester) async {
    final changes = <(String, double)>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ReverbHeaderActions(
          device: _reverb(),
          onParameterChanged: (id, value) => changes.add((id, value)),
        ),
      ),
    ));
    await tester.tap(find.byKey(const ValueKey('reverb-freeze')));
    expect(changes, contains(('freeze', 1.0)));
    expect(find.byIcon(Icons.ac_unit), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('reverb-mode-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SPACE'));
    expect(changes, contains(('modeMorph', 3.0)));
    expect(tester.takeException(), isNull);
  });

  test('reverb registers functional container tabs', () {
    expect(ReverbFxPanel.containerTabs.map((tab) => tab.label),
        orderedEquals(['TAIL', 'TONE', 'MOD']));
  });

  test('reverb snapshot parses modern parameters and output rail', () {
    final snapshot = DeviceSnapshot.fromMap({
      'id': 'reverb-map',
      'type': 'reverb',
      'parameters': {
        'modeMorph': 1.5,
        'decay': .8,
        'preDelay': .2,
        'size': .7,
        'diffusion': .9,
        'damping': .6,
        'modulation': .3,
        'lowCut': .25,
        'highCut': .85,
        'ducking': .4,
        'freeze': 1.0,
      },
      'outputPanel': {'outputMix': .42, 'outputWidth': .88},
    }) as ReverbDeviceSnapshot;
    expect(snapshot.modeMorph, 1.5);
    expect(snapshot.decay, .8);
    expect(snapshot.ducking, .4);
    expect(snapshot.outputMix, .42);
    expect(snapshot.outputWidth, .88);
    expect(snapshot.freeze, 1.0);
    expect(snapshot.withParameter('highCut', .7).highCut, .7);
  });
}
