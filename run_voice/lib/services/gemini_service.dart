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
  "global_alerts": [
    {
      "name": "Distanza ogni chilometro",
      "metric": "distance" | "time" | "bpm" | "pace",
      "trigger": "time" | "distance",
      "interval_seconds": null,
      "interval_meters": 1000,
      "mode": "total" | "current" | "split"
    }
  ],
  "steps": [
    {
      "id": "step_1",
      "label": "Riscaldamento",
      "phase": "warmup" | "work" | "recovery" | "cooldown",
      "duration": {
        "type": "distance_meters" | "time_seconds",
        "value": 600
      },
      "target": {
        "metric": "heart_rate_bpm" | "pace" | "none",
        "target_hr_bpm_min": 120,
        "target_hr_bpm_max": 135,
        "target_hr_bpm": 127,
        "bpm_tolerance": 8,
        "target_pace_sec_per_km": 300,
        "pace_tolerance_sec": 10
      },
      "periodic_alerts": [
        {
          "name": "Distanza ogni 5 minuti",
          "metric": "distance" | "time" | "bpm" | "pace",
          "trigger": "time" | "distance",
          "interval_seconds": 300,
          "interval_meters": null,
          "mode": "total" | "current" | "split"
        }
      ],
      "coaching_alerts": [
        {
          "name": "Battiti 120-135",
          "metric": "bpm" | "pace",
          "min_value": 120.0,
          "max_value": 135.0
        }
      ]
    }
  ]
}

REGOLE FONDAMENTALI GLOBALI:
1. SEMPRE produci almeno 1 step, anche per allenamenti continui (es. "Corsa continua").
2. GLOBAL_ALERTS vs PERIODIC_ALERTS vs COACHING_ALERTS:
   - Usa global_alerts per annunci che si applicano durante TUTTO l'allenamento e non sono collegati alle ripetute (es. 'ogni chilometro dimmi la distanza complessiva', 'durante tutto l'allenamento ogni X minuti dimmi il tempo').
   - Usa periodic_alerts (dentro ogni step) per annunci periodici legati SOLO a quella fase/step (es. 'ogni 5 minuti di questa ripetuta dimmi la distanza', 'ogni chilometro durante il lavoro').
   - Usa coaching_alerts (dentro ogni step) per monitorare range di metriche durante quella fase (es. 'mantieni i battiti tra 120 e 135', 'battiti sopra 140', 'ritmo tra 4:30 e 5:00').
3. Se l'utente chiede "ogni X minuti dimmi la distanza complessiva" → global_alerts: trigger: "time", interval_seconds: X*60, metric: "distance", mode: "total".
4. Se l'utente chiede "ogni X minuti dimmi la distanza di questa ripetuta" → periodic_alerts dello step: trigger: "time", interval_seconds: X*60, metric: "distance", mode: "total" o "current".
5. IMPORTANTE: Non saltare NESSUN alert menzonato dall'utente, né in global_alerts né in periodic_alerts né in coaching_alerts.

REGOLE SUI GLOBAL_ALERTS:
1. Usa global_alerts per annunci che durano "durante tutto l'allenamento" o "non collegati alle ripetute".
2. Esempi:
   - "Ogni chilometro dimmi la distanza complessiva" → global_alerts: [{ name: "Distanza complessiva", metric: "distance", trigger: "distance", interval_meters: 1000, mode: "total" }]
   - "Ogni 5 minuti dimmi il tempo totale" → global_alerts: [{ name: "Tempo totale", metric: "time", trigger: "time", interval_seconds: 300, mode: "total" }]
   - "Non collegato alle ripetute, dimmi ogni 2 km la distanza" → global_alerts: [{ name: "Distanza", metric: "distance", trigger: "distance", interval_meters: 2000, mode: "total" }]
3. Se non ci sono annunci globali, global_alerts può essere [] o omesso.

REGOLE SUI TARGET CARDIO E PASSO (steps):
1. Se il testo contiene indicazioni di battito cardiaco o BPM (es. '120-135 bpm', '145-155 bpm', 'sotto 140 bpm', 'battiti tra 120 e 135'):
   - Imposta SEMPRE `metric: "heart_rate_bpm"` per ciascuna fase interessata nel target.
   - Imposta `target_hr_bpm_min` e `target_hr_bpm_max` con gli estremi del range (es. 120 e 135).
   - Calcola anche il centro `target_hr_bpm` e la semi-tolleranza `bpm_tolerance`.
   - SEMPRE includi anche un coaching_alert in quello step con { name, metric: "bpm", min_value, max_value }.
2. Se il testo contiene indicazioni di passo/ritmo (es. '4:30/km', '5 min/km'):
   - Imposta `metric: "pace"` con `target_pace_sec_per_km` in secondi (es. 270 per 4:30) e `pace_tolerance_sec: 10`.
   - Se pertinente, aggiungi un coaching_alert per il passo.
3. Riconosci le ripetizioni ('8x(2'+2')') espandendole in sequenze alternate di step di lavoro ('work') e recupero ('recovery') con i rispettivi target cardio/passo.

REGOLE COACHING_ALERTS (dentro steps):
1. Usa coaching_alerts per monitorare range di metriche durante uno step (es. 'battiti tra 120 e 135', 'battiti sopra 140', 'battiti fino a 155', 'ritmo tra 4:30 e 5:00').
2. Formato: { name: string, metric: "bpm" | "pace", min_value: double?, max_value: double? }
   - Se "battiti sopra 140" → metric: "bpm", min_value: 140, max_value: 180 (valore ragionevole).
   - Se "battiti tra 120 e 135" → metric: "bpm", min_value: 120, max_value: 135.
   - Se "battiti fino a 120" → metric: "bpm", min_value: 50, max_value: 120 (valore ragionevole minimo).
   - Se "ritmo tra 4:30 e 5:00" → metric: "pace", min_value: 270 (secondi per km), max_value: 300.
   - Se "ritmo sopra 6 minuti per km" → metric: "pace", min_value: 360, max_value: 1200 (valore ragionevole massimo).
3. IMPORTANTE: Tutti i coaching_alerts menzonati devono SEMPRE essere inclusi nello step corrispondente. Non saltare mai un coaching alert richiesto dall'utente.
4. Se uno step ha target con range HR/Pace, DEVE avere anche il corrispondente coaching_alert.

REGOLE PERIODIC_ALERTS (dentro steps):
1. Usa periodic_alerts per annunci periodici che avvengono DURANTE uno step specifico.
2. Se l'utente dice "ogni 5 minuti dimmi la distanza" durante uno step → trigger: "time", interval_seconds: 300, metric: "distance", mode: "total" (o "current" se è distanza dello step attuale).
3. Se l'utente dice "ogni chilometro dimmi il ritmo di questa ripetuta" → trigger: "distance", interval_meters: 1000, metric: "pace", mode: "current".
4. Se l'utente dice "ogni 500 metri dimmi il tempo trascorso dello step" → trigger: "distance", interval_meters: 500, metric: "time", mode: "current".
5. Formato: { name: string, metric: "distance" | "time" | "bpm" | "pace", trigger: "time" | "distance", interval_seconds?: int, interval_meters?: double, mode: "total" | "current" | "split" }
6. IMPORTANTE: Non saltare nessun periodic alert menzonato per quella fase. Se l'utente chiede annunci periodici per uno step, DEVONO essere inclusi.

REGOLE FINALI:
1. Restituisci ESCLUSIVAMENTE l'oggetto JSON, senza markdown né testo aggiuntivo.
2. Se global_alerts è vuoto, può essere omesso o un array vuoto [].
3. Se uno step non ha periodic_alerts, può essere omesso o array vuoto []. Stessa cosa per coaching_alerts.
4. Per allenamenti continui senza ripetizioni, crea 1 step con phase: "work" e duration in base al contesto (default 5 km se non specificato).
5. Ogni step DEVE avere almeno: id, label, phase, duration. Il target, periodic_alerts e coaching_alerts sono opzionali se non specificati.
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
