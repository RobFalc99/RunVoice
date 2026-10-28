// ignore_for_file: avoid_print
import 'dart:io';
import 'package:run_voice/models/alert_config.dart';
import 'package:run_voice/services/gemini_service.dart';

Future<String?> _resolveApiKey() async {
  final fromEnv = Platform.environment['GEMINI_API_KEY'];
  if (fromEnv != null && fromEnv.trim().isNotEmpty) {
    return fromEnv.trim();
  }
  final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
  if (home != null) {
    final file = File('$home\\.env');
    if (await file.exists()) {
      for (final line in await file.readAsLines()) {
        final trimmed = line.trim();
        if (trimmed.startsWith('GEMINI_API_KEY=')) {
          var val = trimmed.substring('GEMINI_API_KEY='.length).trim();
          if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
            val = val.substring(1, val.length - 1);
          }
          return val;
        }
      }
    }
  }
  return null;
}

void main() async {
  final apiKey = await _resolveApiKey();
  if (apiKey == null) {
    print('FAIL: API Key non trovata');
    exit(1);
  }

  const prompt = '''
Perfetto, lo traduco tutto in BPM. Uso un range realistico per te in base alle tue corse recenti (easy intorno a 130, qualità un po’ sopra).

### Lavoro di qualità in *BPM*

*Totale stimato:* ~40’

---

#### 1) Riscaldamento – 10’

- *10’ a 120–135 bpm*
  - Parti pure sui 120–125 bpm e lascia che salga verso 130–135 bpm senza forzare.

- Negli ultimi 3’:
  - *3 × 20–30” a 145–150 bpm*
  - Recupero 40–60” a 120–130 bpm tra un allungo e l’altro.

---

#### 2) Blocco qualità – 8 × (2’ + 2’)

Ripeti questo *8 volte*:

- *2’ veloci*
  - Target: *145–155 bpm*
  - Se vedi che sali subito oltre 155–158 bpm, stai spingendo troppo: dal giro dopo parti un filo più piano.

- *2’ di recupero*
  - Scendi a *120–135 bpm*
  - Se resti sopra i 140 bpm per tutti i 2’, il recupero è troppo tirato: rallenta fino quasi a jog o pochi secondi di camminata.

---

#### 3) Defaticamento – 8–10’

- *8–10’ a 120–135 bpm*
  - Stesso feeling del riscaldamento: facile, conversazione possibile, niente chiusure “a fuoco”.
''';

  print('=== Verifico generazione da prompt utente ===');
  final plan = await GeminiService.generateWorkoutPlan(apiKey, prompt);
  print('Piano generato: ${plan.name} (${plan.steps.length} passi)');

  final preset = plan.toPreset();
  print('Preset generato: ${preset.name}');
  print('Numero intervalli totali: ${preset.intervals.length}');

  int totalCoaching = 0;
  int totalPeriodic = 0;

  for (int i = 0; i < preset.intervals.length; i++) {
    final step = preset.intervals[i];
    totalCoaching += step.coachingAlerts.length;
    totalPeriodic += step.alerts.length;

    print('Step ${i + 1} [${step.name} (${step.durationSeconds}s)]:');
    for (final c in step.coachingAlerts) {
      print('   🎯 COACHING: ${c.name} (${c.metric.displayName} ${c.minValue.round()}-${c.maxValue.round()})');
    }
    for (final a in step.alerts) {
      print('   ⏱️ PERIODICO: ${a.name} (ogni ${a.intervalSeconds}s)');
    }
  }

  print('\nRiepilogo:');
  print(' - Totale avvisi di coaching: $totalCoaching');
  print(' - Totale avvisi periodici:   $totalPeriodic');

  if (totalCoaching > 0 && totalPeriodic > 0) {
    print('SUCCESS: TUTTI GLI AVVISI SONO STATI GENERATI CORRETTAMENTE! 🎉');
  } else {
    print('FAIL: Manca qualche avviso.');
    exit(1);
  }
}
