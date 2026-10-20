import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_voice/models/alert_config.dart';
import 'package:run_voice/widgets/neumorphic_switch.dart';
import 'package:run_voice/widgets/dial_interaction_layer.dart';
import 'package:run_voice/widgets/alert_setup_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NeumorphicSwitch Tests', () {
    testWidgets('toggles state and calls onChanged with haptic feedback', (WidgetTester tester) async {
      bool value = false;
      bool? newValue;
      
      final List<MethodCall> hapticLog = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
        if (methodCall.method == 'HapticFeedback.vibrate' && 
            methodCall.arguments == 'HapticFeedbackType.selectionClick') {
          hapticLog.add(methodCall);
        }
        return null;
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NeumorphicSwitch(
              value: value,
              onChanged: (v) {
                newValue = v;
              },
            ),
          ),
        ),
      );

      // Verify initial state (semantics or just presence)
      expect(find.byType(NeumorphicSwitch), findsOneWidget);
      
      // Tap the switch
      await tester.tap(find.byType(NeumorphicSwitch));
      await tester.pump();

      // Verify callback
      expect(newValue, isTrue);
      
      // Verify haptic feedback
      expect(hapticLog.length, 1);
      expect(hapticLog.first.arguments, 'HapticFeedbackType.selectionClick');
    });

    testWidgets('does not call onChanged when disabled', (WidgetTester tester) async {
      bool? newValue;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NeumorphicSwitch(
              value: false,
              enabled: false,
              onChanged: (v) => newValue = v,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(NeumorphicSwitch));
      await tester.pump();

      expect(newValue, isNull);
    });
  });

  group('DialInteractionLayer Tests (DialAngles)', () {
    test('calculateDialAngle returns correct angles', () {
      const center = Offset(100, 100);
      
      // 0 degrees (Right)
      expect(DialAngles.calculateDialAngle(const Offset(200, 100), center), 0.0);
      
      // 90 degrees (Down)
      expect(DialAngles.calculateDialAngle(const Offset(100, 200), center), 90.0);
      
      // 180 degrees (Left)
      expect(DialAngles.calculateDialAngle(const Offset(0, 100), center), 180.0);
      
      // -90 degrees (Up)
      expect(DialAngles.calculateDialAngle(const Offset(100, 0), center), -90.0);
    });

    test('normalizeAngleDelta handles boundary crossings correctly', () {
      // Small positive movement across 180/-180 boundary
      // last: 175, current: -175 -> delta should be +10
      expect(DialAngles.normalizeAngleDelta(-175, 175), 10.0);
      
      // Small negative movement across 180/-180 boundary
      // last: -175, current: 175 -> delta should be -10
      expect(DialAngles.normalizeAngleDelta(175, -175), -10.0);
      
      // Normal movement
      expect(DialAngles.normalizeAngleDelta(45, 30), 15.0);
      expect(DialAngles.normalizeAngleDelta(30, 45), -15.0);
    });
  });

  group('AlertSetupSheet Tests', () {
    testWidgets('renders correctly and shows only BPM (no HR Zone)', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AlertSetupSheet.show(
                      context,
                      onConfirm: (_) {},
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Check for Level 1 presence
      expect(find.text('LIVELLO 1'), findsOneWidget);
      expect(find.text('Tipo di avviso'), findsOneWidget);

      // Check for metric chips in Level 2
      expect(find.text('BPM'), findsOneWidget);
      expect(find.text('Ritmo'), findsOneWidget);
      expect(find.text('Velocità'), findsOneWidget);
      expect(find.text('Tempo'), findsWidgets);
      expect(find.text('Distanza'), findsWidgets);
      
      // Verify NO "Zona FC" or similar
      expect(find.text('Zona FC'), findsNothing);
      expect(find.text('Zone FC'), findsNothing);
      expect(find.text('BPM'), findsOneWidget);
    });

    testWidgets('swaps between Periodic and Coaching types', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AlertSetupSheet.show(
                      context,
                      onConfirm: (_) {},
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Initially Periodic is selected (default)
      expect(find.textContaining('Annuncia una metrica'), findsOneWidget);
      
      // Tap Coaching segment
      await tester.tap(find.text('Coaching'));
      await tester.pumpAndSettle();
      
      // Now coaching description should be visible
      expect(find.textContaining('Ricevi un feedback continuo'), findsOneWidget);
      
      // In coaching, Distance and Time metrics should be removed
      expect(find.text('BPM'), findsOneWidget);
      expect(find.text('Ritmo'), findsOneWidget);
      expect(find.text('Velocità'), findsOneWidget);
      expect(find.text('Tempo'), findsNothing);
      expect(find.text('Distanza'), findsNothing);
    });

    testWidgets('metric selection updates state', (WidgetTester tester) async {
       AlertSetupResult? result;

       await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AlertSetupSheet.show(
                      context,
                      onConfirm: (res) => result = res,
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Change metric to BPM
      await tester.tap(find.text('BPM'));
      await tester.pumpAndSettle();

      // Confirm
      await tester.ensureVisible(find.text('Salva'));
      await tester.tap(find.text('Salva'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.isPeriodic, isTrue);
      expect(result!.periodic!.metric, AlertMetric.bpm);
    });
  });
}
