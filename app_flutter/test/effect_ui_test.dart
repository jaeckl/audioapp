import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:audioapp/effects/effect_device_strip.dart';
import 'package:audioapp/engine_bridge.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> methodCalls;

  setUp(() {
    methodCalls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('engine/effect'),
            (MethodCall methodCall) async {
      methodCalls.add(methodCall);
      switch (methodCall.method) {
        case 'enableEffect':
          return true;
        case 'setEffectParameter':
          return true;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('engine/effect'), null);
  });

  group('EffectDeviceStrip UI tests', () {
    testWidgets('renders delay effect with name and sliders', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EffectDeviceStrip(
              type: 'delay',
              snapshot: {
                'enabled': true,
                'params': {'timeMs': 250.0, 'feedback': 0.4, 'mix': 0.5},
              },
            ),
          ),
        ),
      );

      // Effect name: "Delay Effect"
      expect(find.text('Delay Effect'), findsOneWidget);
      // At least one Slider
      expect(find.byType(Slider), findsWidgets);
      // Switch
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('slider drag triggers setEffectParameter bridge call',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EffectDeviceStrip(
              type: 'delay',
              snapshot: {
                'enabled': true,
                'params': {'timeMs': 250.0, 'feedback': 0.4, 'mix': 0.5},
              },
            ),
          ),
        ),
      );

      final slider = find.byType(Slider).first;
      // Drag right to increase value
      await tester.drag(slider, const Offset(50, 0));
      await tester.pumpAndSettle();

      // Should have called setEffectParameter at least once
      expect(
        methodCalls.any((c) => c.method == 'setEffectParameter'),
        isTrue,
        reason: 'expected setEffectParameter to be called on slider drag',
      );
    });

    testWidgets('switch tap triggers enableEffect bridge call',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EffectDeviceStrip(
              type: 'delay',
              snapshot: {
                'enabled': true,
                'params': {'timeMs': 250.0},
              },
            ),
          ),
        ),
      );

      final switchWidget = find.byType(Switch);
      expect(switchWidget, findsOneWidget);

      await tester.tap(switchWidget);
      await tester.pumpAndSettle();

      // Should have called enableEffect with enabled=false (toggled off)
      expect(
        methodCalls.any(
          (c) =>
              c.method == 'enableEffect' &&
              c.arguments['enabled'] == false,
        ),
        isTrue,
        reason: 'expected enableEffect(false) to be called on switch tap',
      );
    });
  });
}