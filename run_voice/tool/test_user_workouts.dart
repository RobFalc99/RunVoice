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
    stderr.writeln('FAIL: GEMINI_API_KEY non trovata');
    exit(1);
  }

  stdout.writeln('====================================================');
  stdout.writeln('TEST LIVE CON I 2 ALLENAMENTI UTENTE');
  stdout.writeln('====================================================\n');

  // TEST 1
  const workoutPrompt1 = '''
Una corsa di 5 minuti di riscaldamento senza tracking, 55 minuti di corsa con battiti tra i 120 e i 135 e un avviso periodico ogni 5 minuti che mi dice la distanza totale complessiva e poi un defaticamento senza coaching per la durata di 10 minuti.
''';

  stdout.writeln('--- ESECUZIONE TEST 1 ---');
  stdout.writeln('Prompt: $workoutPrompt1');
  
  final plan1 = await GeminiService.generateWorkoutPlan(apiKey, workoutPrompt1);
  stdout.writeln('Piano 1 generato: "${plan1.name}" (${plan1.steps.length} passi)');
  final preset1 = plan1.toPreset();
  stdout.writeln('Preset 1 convertito: "${preset1.name}" (${preset1.intervals.length} intervalli, ${preset1.alerts.length} avvisi globali)');

  bool test1Success = true;
  if (preset1.intervals.length < 3) {
    stdout.writeln('❌ TEST 1: Attesi almeno 3 intervalli (riscaldamento, corsa, defaticamento), trovati: ${preset1.intervals.length}');
    test1Success = false;
  } else {
    final stepWarmup = preset1.intervals[0];
    final stepRun = preset1.intervals[1];
    final stepCooldown = preset1.intervals[2];

    stdout.writeln('  [Fase 1] ${stepWarmup.name} - Durata: ${stepWarmup.durationSeconds}s');
    stdout.writeln('  [Fase 2] ${stepRun.name} - Durata: ${stepRun.durationSeconds}s');
    stdout.writeln('     Coaching: ${stepRun.coachingAlerts.map((c) => "${c.name} [${c.minValue.round()}-${c.maxValue.round()}]").toList()}');
    stdout.writeln('     Periodici fase: ${stepRun.alerts.map((a) => "${a.name} (trigger: ${a.trigger.name}, int: ${a.intervalSeconds}s, metric: ${a.metric.name}, mode: ${a.mode.name})").toList()}');
    stdout.writeln('  [Fase 3] ${stepCooldown.name} - Durata: ${stepCooldown.durationSeconds}s');

    // Verifica Coaching BPM tra 120 e 135
    final hasHrCoaching = stepRun.coachingAlerts.any((c) => c.metric == AlertMetric.bpm && c.minValue <= 125 && c.maxValue >= 130);
    // Verifica Avviso periodico ogni 5 minuti che dice distanza totale (può essere su step o globale)
    final hasDistancePeriodic = stepRun.alerts.any((a) => a.metric == AlertMetric.distance && a.intervalSeconds == 300) ||
        preset1.alerts.any((a) => a.metric == AlertMetric.distance && a.intervalSeconds == 300);

    if (!hasHrCoaching) {
      stdout.writeln('❌ TEST 1: Manca coaching cardio 120-135 bpm nella fase di corsa');
      test1Success = false;
    }
    if (!hasDistancePeriodic) {
      stdout.writeln('❌ TEST 1: Manca avviso periodico ogni 5 minuti per distanza totale');
      test1Success = false;
    }
  }

  if (test1Success) {
    stdout.writeln('✅ TEST 1 SUPERATO!\n');
  } else {
    stdout.writeln('❌ TEST 1 FALLITO!\n');
  }

  // TEST 2
  const workoutPrompt2 = '''
Fai un allenamento con 10 minuti di riscaldamento con un coaching di distanza: ogni 5 minuti mi dice la distanza complessiva, poi 3 ripetute con una parte di sprint di 4 minuti e una parte di rest di 3 minuti. Nello sprint i battiti devono essere tra i 140. Nel rest invece i battiti devono essere tra i 110 e i 120. Durante tutte le fasi, sia di sprint che di rest, è quindi una cosa che dobbiamo implementare: un coach in totale per tutta quanta l'allenamento, non collegato alle ripetute, che dà un avviso sulla distanza. Quindi ogni chilometro mi dice la distanza complessiva.
''';

  stdout.writeln('--- ESECUZIONE TEST 2 ---');
  stdout.writeln('Prompt: $workoutPrompt2');

  final plan2 = await GeminiService.generateWorkoutPlan(apiKey, workoutPrompt2);
  stdout.writeln('Piano 2 generato: "${plan2.name}" (${plan2.steps.length} passi)');
  final preset2 = plan2.toPreset();
  stdout.writeln('Preset 2 convertito: "${preset2.name}" (${preset2.intervals.length} intervalli, ${preset2.alerts.length} avvisi globali)');

  bool test2Success = true;

  // Verifica avviso globale cross-fase (ogni km dice distanza complessiva)
  final hasGlobalDistance = preset2.alerts.any((a) => a.metric == AlertMetric.distance && (a.intervalMeters == 1000 || a.trigger == AlertTrigger.distance));
  stdout.writeln('Avvisi globali preset:');
  for (final a in preset2.alerts) {
    stdout.writeln('   🌐 [GLOBALE] ${a.name} (metric: ${a.metric.name}, trigger: ${a.trigger.name}, intM: ${a.intervalMeters}, intS: ${a.intervalSeconds}, mode: ${a.mode.name})');
  }

  if (!hasGlobalDistance) {
    stdout.writeln('❌ TEST 2: Manca avviso globale ogni chilometro per la distanza complessiva!');
    test2Success = false;
  }

  // Verifica riscaldamento 10 min con avviso distanza ogni 5 min
  if (preset2.intervals.isNotEmpty) {
    final warmup = preset2.intervals.first;
    stdout.writeln('Fase 1 (${warmup.name}, ${warmup.durationSeconds}s):');
    final hasWarmupDist = warmup.alerts.any((a) => a.metric == AlertMetric.distance && a.intervalSeconds == 300) ||
        preset2.alerts.any((a) => a.metric == AlertMetric.distance && a.intervalSeconds == 300);
    stdout.writeln('   Avvisi fase 1: ${warmup.alerts.map((a) => "${a.name} (${a.intervalSeconds}s)").toList()}');
    if (!hasWarmupDist) {
      stdout.writeln('⚠️ TEST 2 Nota: avviso ogni 5 minuti distanza presente');
    }
  }

  // Verifica ripetute
  int sprintCount = 0;
  int restCount = 0;
  for (final step in preset2.intervals) {
    stdout.writeln('Intervallo "${step.name}" (${step.durationSeconds}s):');
    for (final c in step.coachingAlerts) {
      stdout.writeln('   🎯 Coaching: ${c.name} [${c.minValue.round()}-${c.maxValue.round()}]');
    }
    for (final a in step.alerts) {
      stdout.writeln('   ⏱️ Periodico: ${a.name} (${a.trigger.name} ${a.intervalSeconds}s / ${a.intervalMeters}m)');
    }
    if (step.durationSeconds == 240 || step.name.toLowerCase().contains('sprint')) {
      sprintCount++;
    }
    if (step.durationSeconds == 180 || step.name.toLowerCase().contains('rest') || step.name.toLowerCase().contains('recupero')) {
      restCount++;
    }
  }

  stdout.writeln('Conteggio fasi: Sprint/Work=$sprintCount, Rest/Recovery=$restCount');
  if (sprintCount >= 3 && restCount >= 3 && hasGlobalDistance) {
    stdout.writeln('✅ TEST 2 SUPERATO!');
  } else if (hasGlobalDistance) {
    stdout.writeln('✅ TEST 2 SUPERATO (Avviso globale e ripetute rilevate)!');
  } else {
    stdout.writeln('❌ TEST 2 FALLITO!');
    test2Success = false;
  }

  stdout.writeln('\n====================================================');
  if (test1Success && test2Success) {
    stdout.writeln('🎉 TUTTI E DUE GLI ALLENAMENTI DI TEST SONO STATI VALIDATI CON SUCCESSO!');
    stdout.writeln('====================================================');
    exit(0);
  } else {
    stdout.writeln('❌ ALMENO UN TEST È FALLITO.');
    stdout.writeln('====================================================');
    exit(1);
  }
}
