import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_voice/utils/constants.dart';
import 'package:run_voice/widgets/neumorphic_segmented_control.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NeumorphicSegmentedControl', () {
    late int hapticCount;
    final binaryMessenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    setUp(() {
      hapticCount = 0;
      binaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (MethodCall call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          hapticCount++;
        }
        return null;
      });
    });

    tearDown(() {
      binaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });

    Widget buildSubject({
      required String selected,
      required ValueChanged<String> onChanged,
    }) {
      return MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: SizedBox(
              width: 360,
              child: NeumorphicSegmentedControl<String>(
                padding: const EdgeInsets.all(0),
                value: selected,
                onChanged: onChanged,
                segments: const [
                  NeumorphicSegment(value: 'one', label: 'One'),
                  NeumorphicSegment(value: 'two', label: 'Two'),
                  NeumorphicSegment(value: 'three', label: 'Three'),
                ],
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders equal-width segments and respects the minimum touch height', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          selected: 'two',
          onChanged: (_) {},
        ),
      );

      final first = tester.getSize(find.byKey(const ValueKey<String>('one')).first);
      final second = tester.getSize(find.byKey(const ValueKey<String>('two')).first);
      final third = tester.getSize(find.byKey(const ValueKey<String>('three')).first);

      expect(first.width, moreOrLessEquals(120, epsilon: 0.01));
      expect(second.width, moreOrLessEquals(120, epsilon: 0.01));
      expect(third.width, moreOrLessEquals(120, epsilon: 0.01));
      expect(first.height, greaterThanOrEqualTo(48));
      expect(second.height, greaterThanOrEqualTo(48));
      expect(third.height, greaterThanOrEqualTo(48));
    });

    testWidgets('shows selected styling with accent border and inset decoration', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          selected: 'two',
          onChanged: (_) {},
        ),
      );

      final selectedDecoration = tester.widgetList<AnimatedContainer>(find.byKey(const ValueKey<String>('two'))).last.decoration as BoxDecoration;
      final unselectedDecoration = tester.widgetList<AnimatedContainer>(find.byKey(const ValueKey<String>('one'))).last.decoration as BoxDecoration;

      expect(selectedDecoration.border, isNotNull);
      expect((selectedDecoration.border as Border).top.color, AppColors.accent.withValues(alpha: 0.95));
      expect(selectedDecoration.boxShadow, isNotNull);
      expect(unselectedDecoration.boxShadow, isNull);
    });

    testWidgets('taps emit haptic feedback and notify value changes', (tester) async {
      String current = 'one';

      await tester.pumpWidget(
        buildSubject(
          selected: current,
          onChanged: (value) {
            current = value;
          },
        ),
      );

      await tester.tap(find.byKey(const ValueKey<String>('three')));
      await tester.pumpAndSettle();

      expect(hapticCount, greaterThanOrEqualTo(1));
      expect(current, 'three');
    });
  });
}
