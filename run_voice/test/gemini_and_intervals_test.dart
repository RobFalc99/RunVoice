import 'package:flutter_test/flutter_test.dart';
import 'package:run_voice/models/user_profile.dart';
import 'package:run_voice/models/preset.dart';
import 'package:run_voice/models/alert_config.dart';
import 'package:run_voice/services/gemini_service.dart';

void main() {
  group('UserProfile Gemini API Key', () {
    test('default geminiApiKey is empty', () {
      final profile = UserProfile();
      expect(profile.geminiApiKey, isEmpty);
    });

    test('serializes and deserializes geminiApiKey correctly', () {
      final profile = UserProfile();
      profile.geminiApiKey = 'AIzaSyTestKey123';
      final jsonString = profile.toJsonString();
      final restored = UserProfile.fromJsonString(jsonString);
      expect(restored.geminiApiKey, equals('AIzaSyTestKey123'));
    });
  });

  group('UserProfile Gemini Model', () {
    test('default geminiModel is gemini-3.5-flash-lite', () {
      final profile = UserProfile();
      expect(profile.geminiModel, equals('gemini-3.5-flash-lite'));
    });

    test('geminiModelLabel returns correct label for gemini-3.5-flash-lite', () {
      final profile = UserProfile();
      profile.geminiModel = 'gemini-3.5-flash-lite';
      expect(profile.geminiModelLabel, equals('Gemini 3.5 Flash-Lite'));
    });

    test('geminiModelLabel returns correct label for gemini-3.8-flash', () {
      final profile = UserProfile();
      profile.geminiModel = 'gemini-3.8-flash';
      expect(profile.geminiModelLabel, equals('Gemini 3.8 Flash'));
    });

    test('serializes and deserializes geminiModel correctly', () {
      final profile = UserProfile();
      profile.geminiModel = 'gemini-3.8-flash';
      final jsonString = profile.toJsonString();
      final restored = UserProfile.fromJsonString(jsonString);
      expect(restored.geminiModel, equals('gemini-3.8-flash'));
      expect(restored.geminiModelLabel, equals('Gemini 3.8 Flash'));
    });
  });

  group('GeminiService Validation', () {
    test('empty key returns success: false', () async {
      final res = await GeminiService.testApiKey('');
      expect(res.success, isFalse);
      expect(res.message, contains('vuota'));
    });

    test('whitespace key returns success: false', () async {
      final res = await GeminiService.testApiKey('   ');
      expect(res.success, isFalse);
      expect(res.message, contains('vuota'));
    });
  });

  group('GeminiService Curated Models', () {
    test('curatedModels contains gemini-3.5-flash-lite', () {
      expect(
        GeminiService.curatedModels.any((m) => m.id == 'gemini-3.5-flash-lite'),
        isTrue,
      );
    });

    test('curatedModels contains gemini-3.8-flash', () {
      expect(
        GeminiService.curatedModels.any((m) => m.id == 'gemini-3.8-flash'),
        isTrue,
      );
    });

    test('gemini-3.5-flash-lite model has correct metadata', () {
      final model = GeminiService.curatedModels
          .firstWhere((m) => m.id == 'gemini-3.5-flash-lite');
      expect(model.label, equals('Gemini 3.5 Flash-Lite'));
      expect(model.badge, contains('Consigliato'));
    });

    test('gemini-3.8-flash model has correct metadata', () {
      final model =
          GeminiService.curatedModels.firstWhere((m) => m.id == 'gemini-3.8-flash');
      expect(model.label, equals('Gemini 3.8 Flash'));
      expect(model.badge, contains('Novità'));
    });
  });

  group('IntervalStep Formatting & Serialization', () {
    test('formats distance duration correctly', () {
      final step1 = IntervalStep(
        id: '1',
        name: 'Ripetuta 1km',
        type: AlertTrigger.distance,
        distanceMeters: 1000,
      );
      expect(step1.displayDuration, equals('1.0 km'));

      final step2 = IntervalStep(
        id: '2',
        name: 'Scatto 400m',
        type: AlertTrigger.distance,
        distanceMeters: 400,
      );
      expect(step2.displayDuration, equals('400 metri'));
    });

    test('formats time duration correctly', () {
      final step1 = IntervalStep(
        id: '1',
        name: 'Recupero 90s',
        type: AlertTrigger.time,
        durationSeconds: 90,
      );
      expect(step1.displayDuration, equals('1 min e 30 sec'));

      final step2 = IntervalStep(
        id: '2',
        name: 'Recupero 2m',
        type: AlertTrigger.time,
        durationSeconds: 120,
      );
      expect(step2.displayDuration, equals('2 minuti'));
    });

    test('serializes and deserializes step correctly', () {
      final step = IntervalStep(
        id: 'step_test',
        name: 'Test Step',
        type: AlertTrigger.distance,
        distanceMeters: 800,
      );
      final json = step.toJson();
      final restored = IntervalStep.fromJson(json);
      expect(restored.id, equals('step_test'));
      expect(restored.name, equals('Test Step'));
      expect(restored.type, equals(AlertTrigger.distance));
      expect(restored.distanceMeters, equals(800));
    });
  });
}
