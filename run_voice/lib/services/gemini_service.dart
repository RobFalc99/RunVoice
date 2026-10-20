import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/workout_plan.dart';

class GeminiService {
  static const String defaultModel = 'gemini-2.5-flash';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';

  /// Tests if the provided API key is valid by sending a minimal ping request.
  static Future<({bool success, String message})> testApiKey(
    String apiKey, {
    String model = defaultModel,
  }) async {
    if (apiKey.trim().isEmpty) {
      return (success: false, message: 'La chiave API non può essere vuota.');
    }
    try {
      final url = Uri.parse('$_baseUrl/$model:generateContent?key=${apiKey.trim()}');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': 'Ping test. Rispondi con: OK'}
              ]
            }
          ]
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return (success: true, message: 'Connessione a Gemini riuscita!');
      } else {
        try {
          final errJson = jsonDecode(response.body);
          final msg = errJson['error']?['message'] ?? 'Errore HTTP ${response.statusCode}';
          return (success: false, message: 'Errore: $msg');
        } catch (_) {
          return (success: false, message: 'Errore server HTTP ${response.statusCode}');
        }
      }
    } catch (e) {
      return (success: false, message: 'Errore di connessione: ${e.toString()}');
    }
  }

  /// Generates a WorkoutPlan from natural language prompt using structured JSON generation.
  static Future<WorkoutPlan> generateWorkoutPlan(
    String apiKey,
    String promptText, {
    String model = defaultModel,
  }) async {
    final url = Uri.parse('$_baseUrl/$model:generateContent?key=${apiKey.trim()}');
    final systemInstruction = '''
Sei un coach di corsa esperto. Genera un piano di allenamento valido in formato JSON conforme al seguente schema per WorkoutPlan:
{
  "id": "workout_custom",
  "name": "Titolo allenamento",
  "description": "Descrizione breve",
  "structure": "continuous" | "intervals" | "pyramid" | "fartlek",
  "announce_start": true,
  "announce_splits": true,
  "announce_end": true,
  "steps": [
    {
      "id": "step_1",
      "label": "Riscaldamento",
      "phase": "warmup" | "work" | "recovery" | "cooldown",
      "duration": {
        "type": "distance_meters" | "time_seconds",
        "value": 1000
      },
      "target": {
        "metric": "none" | "pace" | "heart_rate_bpm",
        "target_pace_sec_per_km": 300,
        "pace_tolerance_sec": 10,
        "target_hr_bpm": 150,
        "bpm_tolerance": 5
      }
    }
  ]
}
Restituisci ESCLUSIVAMENTE l'oggetto JSON, senza markdown né testo aggiuntivo.
''';

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'system_instruction': {
          'parts': [{'text': systemInstruction}]
        },
        'contents': [
          {
            'parts': [{'text': promptText}]
          }
        ],
        'generationConfig': {
          'response_mime_type': 'application/json'
        }
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Errore da Gemini (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body);
    final candidate = data['candidates']?[0];
    final text = candidate?['content']?['parts']?[0]?['text'];
    if (text == null) {
      throw Exception('Risposta vuota da Gemini');
    }

    final planMap = jsonDecode(text) as Map<String, dynamic>;
    return WorkoutPlan.fromJson(planMap);
  }
}
