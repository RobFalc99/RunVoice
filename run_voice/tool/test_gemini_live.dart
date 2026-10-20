import 'dart:io';

import 'package:run_voice/services/gemini_service.dart';

Future<String?> _readApiKeyFromEnvFile(String path) async {
  final file = File(path);
  if (!await file.exists()) {
    return null;
  }
  final lines = await file.readAsLines();
  for (final raw in lines) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final eqIdx = line.indexOf('=');
    if (eqIdx <= 0) continue;
    final key = line.substring(0, eqIdx).trim();
    if (key != 'GEMINI_API_KEY') continue;
    var value = line.substring(eqIdx + 1).trim();
    // Rimuovi eventuali virgolette singole o doppie attorno al valore.
    if (value.length >= 2 &&
        ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'")))) {
      value = value.substring(1, value.length - 1);
    }
    return value;
  }
  return null;
}

Future<String?> _resolveApiKey() async {
  final fromEnv = Platform.environment['GEMINI_API_KEY'];
  if (fromEnv != null && fromEnv.trim().isNotEmpty) {
    return fromEnv.trim();
  }

  final candidates = <String>[
    if (Platform.environment['USERPROFILE'] != null)
      '${Platform.environment['USERPROFILE']}\\.env',
    if (Platform.environment['HOME'] != null) '${Platform.environment['HOME']}\\.env',
  ];

  for (final candidate in candidates) {
    final value = await _readApiKeyFromEnvFile(candidate);
    if (value != null && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}

String _maskKey(String apiKey) {
  if (apiKey.length <= 8) {
    return '<hidden> (length=${apiKey.length})';
  }
  final head = apiKey.substring(0, 4);
  final tail = apiKey.substring(apiKey.length - 4);
  return '$head...$tail (length=${apiKey.length})';
}

Future<void> main() async {
  stdout.writeln('=== RunVoice Gemini Live Test ===');

  final apiKey = await _resolveApiKey();
  if (apiKey == null) {
    stderr.writeln(
      'ERROR: GEMINI_API_KEY non trovata in variabile d\'ambiente né in '
      '\$USERPROFILE/.env o \$HOME/.env.',
    );
    exit(1);
  }

  // Mostra solo lunghezza e prefisso/suffisso offuscati, MAI il valore.
  stdout.writeln('OK: GEMINI_API_KEY rilevata (${_maskKey(apiKey)}).');

  // 1) Test connettività API
  stdout.writeln('\n[1/3] Esecuzione di GeminiService.testApiKey ...');
  final ping = await GeminiService.testApiKey(apiKey);
  if (ping.success) {
    stdout.writeln('SUCCESS: ${ping.message}');
  } else {
    stderr.writeln('ERROR: ${ping.message}');
    exit(2);
  }

  // 2) Generazione WorkoutPlan
  const prompt =
      '5 ripetute da 1000m a ritmo 4:30 con 2 min recupero';
  stdout.writeln('\n[2/3] Generazione workout plan dal prompt: "$prompt" ...');
  final plan = await GeminiService.generateWorkoutPlan(apiKey, prompt);
  stdout.writeln('SUCCESS: piano generato.');
  stdout.writeln(' - Nome:        ${plan.name}');
  stdout.writeln(' - ID:          ${plan.id}');
  stdout.writeln(' - Descrizione: ${plan.description}');
  stdout.writeln(' - Struttura:   ${plan.structure.name}');
  stdout.writeln(' - N. step:     ${plan.steps.length}');
  stdout.writeln(' - Durata tot.: ${plan.totalDuration.displayString}');
  stdout.writeln(
      ' - Voice coach: start=${plan.announceStart}, splits=${plan.announceSplits}, end=${plan.announceEnd}');

  // 3) Conversione in Preset legacy
  stdout.writeln('\n[3/3] Conversione in Preset legacy tramite plan.toPreset() ...');
  final preset = plan.toPreset();
  stdout.writeln('SUCCESS: preset generato.');
  stdout.writeln(' - Nome:           ${preset.name}');
  stdout.writeln(' - isInterval:     ${preset.isIntervalTraining}');
  stdout.writeln(' - N. intervals:   ${preset.intervals.length}');
  stdout.writeln(' - announceStart:  ${preset.announceStart}');
  stdout.writeln(' - announceEnd:    ${preset.announceEnd}');
  stdout.writeln(' - announceSummary:${preset.announceSummary}');

  stdout.writeln('\nALL_TESTS_PASSED');
}
