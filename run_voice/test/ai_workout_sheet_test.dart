import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:run_voice/providers/user_provider.dart';
import 'package:run_voice/providers/preset_provider.dart';
import 'package:run_voice/widgets/ai_workout_sheet.dart';

void main() {
  testWidgets('AiWorkoutSheet renders correctly in onTheFly mode', (tester) async {
    final userProvider = UserProvider();
    final presetProvider = PresetProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: userProvider),
          ChangeNotifierProvider.value(value: presetProvider),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AiWorkoutSheet(onTheFly: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Workout Rapido con AI'), findsOneWidget);
    expect(find.text('Powered by Gemini 2.5 Flash'), findsOneWidget);
  });

  testWidgets('AiWorkoutSheet renders correctly in presets mode', (tester) async {
    final userProvider = UserProvider();
    final presetProvider = PresetProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: userProvider),
          ChangeNotifierProvider.value(value: presetProvider),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AiWorkoutSheet(onTheFly: false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Crea Allenamento con AI'), findsOneWidget);
  });
}
