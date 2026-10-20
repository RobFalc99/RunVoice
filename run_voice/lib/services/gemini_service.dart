import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/workout_plan.dart';

class GeminiService {
  static const String defaultModel = 'gemini-3.5-flash-lite';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';
  static const List<({String id, String label, String badge, String description})> curatedModels = [
    (
      id: 'gemini-3.5-flash-lite',
      label: 'Gemini 3.5 Flash-Lite',
      badge: 'Consigliato ⚡',
      description: 'Ultraleggero, bassissima latenza e consumo ridotto',
    ),
    (
      id: 'gemini-3.8-flash',
      label: 'Gemini 3.8 Flash',
      badge: 'Novità 2026 🚀',
      description: 'Ultimo modello Flash raccomandato da Google AI Studio',
    ),
    (
      id: 'gemini-3.5-flash',
      label: 'Gemini 3.5 Flash',
      badge: 'Bilanciato 🎯',
      description: 'Ottimo bilanciamento tra ragionamento e velocità',
    ),
    (
      id: 'gemini-flash-latest',
      label: 'Gemini Flash Latest',
      badge: 'Auto-Update 🔄',
      description: 'Punta sempre all\'ultima versione stabile rilasciata',
    ),
    (
      id: 'gemini-flash-lite-latest',
      label: 'Gemini Flash-Lite Latest',
      badge: 'Auto-Update Lite 🔄',
      description: 'Punta sempre alla versione Flash-Lite più recente',
    ),
    (
      id: 'gemini-2.5-flash',
      label: 'Gemini 2.5 Flash',
      badge: 'Legacy 📦',
      description: 'Versione precedente (potrebbe non essere attiva su tutti gli account)',
    ),
  ];

  /// Queries the /v1beta/models endpoint with the provided API key and returns list of model IDs supporting generateContent.
  static Future<List<String>> fetchAvailableModels(String apiKey) async {
    if (apiKey.trim().isEmpty) return [];
    try {
      final url = Uri.parse('$_baseUrl?key=${apiKey.trim()}');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final models = data['models'] as List<dynamic>? ?? [];
        final result = <String>[];
        for (final m in models) {
          if (m is Map<String, dynamic>) {
            final methods = (m['supportedGenerationMethods'] as List<dynamic>?)?.cast<String>() ?? [];
            if (methods.contains('generateContent')) {
              final name = (m['name'] as String? ?? '').replaceFirst('models/', '');
              if (name.isNotEmpty) {
                result.add(name);
              }
            }
          }
        }
        return result;
      }
    } catch (_) {}
    return [];
  }

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
