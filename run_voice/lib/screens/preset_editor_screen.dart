import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/preset_provider.dart';
import '../models/preset.dart';
import '../models/alert_config.dart';
import '../widgets/alert_card.dart';
import '../widgets/coaching_alert_card.dart';
import '../widgets/neumorphic_card.dart';
import '../widgets/neumorphic_switch.dart';
import '../widgets/alert_setup_sheet.dart';
import '../widgets/ai_workout_sheet.dart';
import '../models/workout_plan.dart';
import '../utils/constants.dart';

class PresetEditorScreen extends StatefulWidget {
  final String presetId;

  const PresetEditorScreen({super.key, required this.presetId});

  @override
  State<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends State<PresetEditorScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final presetProvider = context.watch<PresetProvider>();
    final preset = presetProvider.presets
        .where((p) => p.id == widget.presetId)
        .firstOrNull;

    if (preset == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Errore')),
        body: const Center(
          child: Text(
            'Preset non trovato',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    if (!_initialized) {
      _nameController = TextEditingController(text: preset.name);
      _descController = TextEditingController(text: preset.description);
      _initialized = true;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Modifica Workout',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Genera o Rigenera con AI',
            icon: const Icon(Icons.auto_awesome, color: AppColors.primary),
            onPressed: () => AiWorkoutSheet.show(
              context,
              onTheFly: false,
              onApplyToEditor: (newPreset) async {
                preset.name = newPreset.name;
                preset.description = newPreset.description;
                preset.intervals = newPreset.intervals;
                preset.alerts = newPreset.alerts;
                preset.coachingAlerts = newPreset.coachingAlerts;
                preset.isIntervalTraining = true;
                await presetProvider.updatePreset(preset);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Allenamento rigenerato con successo con AI! ⚡',
                      ),
                    ),
                  );
                }
              },
            ),
          ),
          IconButton(
            tooltip: 'Esporta / Importa JSON AI',
            icon: const Icon(Icons.code, color: AppColors.accent),
            onPressed: () => _showAiJsonDialog(context, presetProvider, preset),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name & Description
            TextField(
              controller: _nameController,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                labelText: 'Nome preset',
                prefixIcon: Icon(Icons.label, color: AppColors.primary),
              ),
              onChanged: (value) {
                preset.name = value;
                presetProvider.updatePreset(preset);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Descrizione',
                prefixIcon: Icon(Icons.description, color: AppColors.textMuted),
              ),
              onChanged: (value) {
                preset.description = value;
                presetProvider.updatePreset(preset);
              },
            ),

            const SizedBox(height: 28),

            const SizedBox(height: 28),

            // Voice settings
            const Text(
              'ANNUNCI VOCALI',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  NeumorphicSwitchListTile(
                    title: 'Inizio/Fine allenamento',
                    value: preset.announceStart,
                    onChanged: (v) {
                      preset.announceStart = v;
                      preset.announceEnd = v;
                      presetProvider.updatePreset(preset);
                    },
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  Divider(color: AppColors.surfaceHighlight, height: 1),
                  NeumorphicSwitchListTile(
                    title: 'Sommario finale',
                    value: preset.announceSummary,
                    onChanged: (v) {
                      preset.announceSummary = v;
                      presetProvider.updatePreset(preset);
                    },
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            _buildIntervalsSection(context, presetProvider, preset),
            const SizedBox(height: 28),
            _buildPresetAlertsSection(context, presetProvider, preset),

            // Test audio button
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () => _testAudioNotifications(context, preset),
                icon: const Icon(Icons.volume_up),
                label: const Text(
                  'Prova Notifiche Audio',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetAlertsSection(
    BuildContext context,
    PresetProvider provider,
    Preset preset,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'AVVISI GLOBALI DELL\'ALLENAMENTO',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Aggiungi'),
              onPressed: () => _showAddAlertSheet(context, provider, preset.id),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (preset.alerts.isEmpty)
          _buildEmptyState(
            'Nessun avviso periodico',
            () => _showAddAlertSheet(context, provider, preset.id),
          )
        else
          ...preset.alerts.map((alert) => AlertCard(
                alert: alert,
                onEdit: () => _showEditAlertSheet(context, provider, preset.id, alert),
                onToggle: (enabled) {
                  provider.updateAlertInPreset(
                    preset.id,
                    alert.copyWith(enabled: enabled),
                  );
                },
                onDelete: () {
                  provider.removeAlertFromPreset(preset.id, alert.id);
                },
              )),
        const SizedBox(height: 28),
        Row(
          children: [
            const Expanded(
              child: Text(
                'AVVISI DI COACHING',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Aggiungi'),
              onPressed: () => _showAddCoachingSheet(context, provider, preset.id),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (preset.coachingAlerts.isEmpty)
          _buildEmptyState(
            'Nessun avviso di coaching',
            () => _showAddCoachingSheet(context, provider, preset.id),
          )
        else
          ...preset.coachingAlerts.map((alert) => CoachingAlertCard(
                alert: alert,
                onEdit: () => _showEditCoachingSheet(context, provider, preset.id, alert),
                onToggle: (enabled) {
                  provider.updateCoachingAlertInPreset(
                    preset.id,
                    alert.copyWith(enabled: enabled),
                  );
                },
                onDelete: () {
                  provider.removeCoachingAlertFromPreset(preset.id, alert.id);
                },
              )),
      ],
    );
  }

  Widget _buildIntervalsSection(
    BuildContext context,
    PresetProvider provider,
    Preset preset,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'SEQUENZA RIPETUTE',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.surfaceHighlight),
              ),
              child: Text(
                '${preset.intervals.length} fasi',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Aggiungi Passo'),
              onPressed: () => _showIntervalStepSheet(
                context,
                provider,
                preset.id,
                null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (preset.intervals.isEmpty)
          _buildEmptyState(
            'Nessuna fase configurata. Aggiungi il riscaldamento o la prima ripetuta.',
            () => _showIntervalStepSheet(
              context,
              provider,
              preset.id,
              null,
            ),
          )
        else
          ...List.generate(
            preset.intervals.length,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildIntervalStepCard(
                context,
                provider,
                preset.id,
                preset.intervals[index],
                index,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildIntervalStepCard(
    BuildContext context,
    PresetProvider provider,
    String presetId,
    IntervalStep step,
    int index,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.primary,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  step.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 18, color: AppColors.textMuted),
                onPressed: () => provider.duplicateIntervalInPreset(presetId, step),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: AppColors.primary),
                onPressed: () => _showIntervalStepSheet(
                  context,
                  provider,
                  presetId,
                  step,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                onPressed: () => provider.removeIntervalFromPreset(presetId, step.id),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                step.type == AlertTrigger.time ? Icons.timer : Icons.straighten,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Durata: ${_formatStepDuration(step)}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.surfaceHighlight, height: 20),
          Row(
            children: [
              const Text(
                'AVVISI DI QUESTA FASE',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 13, color: AppColors.primary),
                label: const Text(
                  'Periodico',
                  style: TextStyle(fontSize: 12, color: AppColors.primary),
                ),
                onPressed: () => AlertSetupSheet.show(
                  context,
                  onConfirm: (result) {
                    if (result.periodic != null) {
                      step.alerts.add(result.periodic!);
                      provider.updateIntervalInPreset(presetId, step);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 13, color: AppColors.accent),
                label: const Text(
                  'Coaching',
                  style: TextStyle(fontSize: 12, color: AppColors.accent),
                ),
                onPressed: () => AlertSetupSheet.show(
                  context,
                  initialCoaching: CoachingAlert(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: 'Coaching Ritmo',
                    metric: AlertMetric.pace,
                    minValue: 5.0,
                    maxValue: 5.5,
                  ),
                  onConfirm: (result) {
                    if (result.coaching != null) {
                      step.coachingAlerts.add(result.coaching!);
                      provider.updateIntervalInPreset(presetId, step);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (step.alerts.isEmpty && step.coachingAlerts.isEmpty)
            const Text(
              'Nessun avviso per questa fase',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...step.alerts.map(
                  (alert) => InputChip(
                    label: Text(alert.name),
                    onDeleted: () {
                      step.alerts.removeWhere((a) => a.id == alert.id);
                      provider.updateIntervalInPreset(presetId, step);
                    },
                  ),
                ),
                ...step.coachingAlerts.map(
                  (alert) => InputChip(
                    label: Text(alert.name),
                    onDeleted: () {
                      step.coachingAlerts.removeWhere((a) => a.id == alert.id);
                      provider.updateIntervalInPreset(presetId, step);
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _showIntervalStepSheet(
    BuildContext context,
    PresetProvider provider,
    String presetId,
    IntervalStep? existing,
  ) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    var trigger = existing?.type ?? AlertTrigger.distance;
    final valueController = TextEditingController(
      text: trigger == AlertTrigger.distance
          ? existing?.distanceMeters.round().toString() ?? '1000'
          : existing?.durationSeconds.toString() ?? '60',
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isDistance = trigger == AlertTrigger.distance;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceHighlight,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        existing == null ? 'Nuovo Passo' : 'Modifica Passo',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Nome passo'),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: ['Riscaldamento', 'Ripetuta', 'Recupero', 'Corsa Veloce', 'Defaticamento']
                            .map((label) => ActionChip(
                                  label: Text(label),
                                  onPressed: () => setSheetState(() => nameController.text = label),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Distanza'),
                              selected: isDistance,
                              onSelected: (_) => setSheetState(() {
                                trigger = AlertTrigger.distance;
                                valueController.text = existing?.distanceMeters.round().toString() ?? '1000';
                              }),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Tempo'),
                              selected: !isDistance,
                              onSelected: (_) => setSheetState(() {
                                trigger = AlertTrigger.time;
                                valueController.text = existing?.durationSeconds.toString() ?? '60';
                              }),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: valueController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: isDistance ? 'Valore distanza' : 'Valore tempo',
                          suffixText: isDistance ? 'm' : 'min:sec (es. 2:30)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (isDistance
                            ? ['200', '400', '800', '1000', '2000', '5000']
                            : ['0:30', '1:00', '2:00', '2:30', '3:00', '4:00', '5:00', '10:00'])
                            .map((value) => ActionChip(
                                  label: Text(
                                    isDistance ? '$value m' : value,
                                  ),
                                  onPressed: () => setSheetState(() => valueController.text = value),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () async {
                            final name = nameController.text.trim();
                            final parsed = _parseDurationInput(valueController.text.trim());
                            if (name.isEmpty || parsed <= 0) return;
                            if (existing == null) {
                              final newStep = IntervalStep(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                name: name,
                                type: trigger,
                                durationSeconds: trigger == AlertTrigger.time ? parsed : 60,
                                distanceMeters: trigger == AlertTrigger.distance ? parsed.toDouble() : 1000,
                              );
                              await provider.addIntervalToPreset(presetId, newStep);
                            } else {
                              existing.name = name;
                              existing.type = trigger;
                              existing.durationSeconds = trigger == AlertTrigger.time ? parsed : existing.durationSeconds;
                              existing.distanceMeters = trigger == AlertTrigger.distance ? parsed.toDouble() : existing.distanceMeters;
                              await provider.updateIntervalInPreset(presetId, existing);
                            }
                            if (context.mounted) Navigator.pop(sheetCtx);
                          },
                          child: const Text('Salva'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  int _parseDurationInput(String input) {
    final trimmed = input.trim();
    if (trimmed.contains(':')) {
      final parts = trimmed.split(':');
      if (parts.length == 2) {
        final minutes = int.tryParse(parts[0].trim()) ?? -1;
        final seconds = int.tryParse(parts[1].trim()) ?? -1;
        if (minutes >= 0 && seconds >= 0 && seconds < 60) {
          return minutes * 60 + seconds;
        }
      }
    }
    return int.tryParse(trimmed) ?? 0;
  }

  String _formatStepDuration(IntervalStep step) {
    if (step.type == AlertTrigger.time) {
      final totalSeconds = step.durationSeconds;
      final minutes = totalSeconds ~/ 60;
      final seconds = totalSeconds % 60;
      if (minutes > 0) return '$minutes min $seconds s';
      return '$seconds s';
    }
    return step.displayDuration;
  }
  Widget _buildEmptyState(String message, VoidCallback onAdd) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.surfaceHighlight,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.notifications_off,
            size: 48,
            color: AppColors.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Aggiungi'),
          ),
        ],
      ),
    );
  }

  void _testAudioNotifications(BuildContext context, Preset preset) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Test audio in riproduzione...')),
    );
  }

  void _showAddAlertSheet(
    BuildContext context,
    PresetProvider provider,
    String presetId,
  ) {
    AlertSetupSheet.show(
      context,
      onConfirm: (result) {
        if (result.periodic != null) {
          provider.addAlertToPreset(presetId, result.periodic!);
        }
      },
    );
  }

  void _showEditAlertSheet(
    BuildContext context,
    PresetProvider provider,
    String presetId,
    AlertConfig alert,
  ) {
    AlertSetupSheet.show(
      context,
      initialPeriodic: alert,
      onConfirm: (result) {
        if (result.periodic != null) {
          provider.updateAlertInPreset(presetId, result.periodic!);
        }
      },
    );
  }

  void _showAddCoachingSheet(
    BuildContext context,
    PresetProvider provider,
    String presetId,
  ) {
    AlertSetupSheet.show(
      context,
      onConfirm: (result) {
        if (result.coaching != null) {
          provider.addCoachingAlertToPreset(presetId, result.coaching!);
        }
      },
    );
  }

  void _showEditCoachingSheet(
    BuildContext context,
    PresetProvider provider,
    String presetId,
    CoachingAlert alert,
  ) {
    AlertSetupSheet.show(
      context,
      initialCoaching: alert,

      onConfirm: (result) {
        if (result.coaching != null) {
          provider.updateCoachingAlertInPreset(presetId, result.coaching!);
        }
      },
    );
  }
  void _showAiJsonDialog(BuildContext context, PresetProvider provider, Preset preset) {
    final workoutPlan = WorkoutPlan.fromPreset(preset);
    final jsonController = TextEditingController(text: workoutPlan.toPrettyJson());

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.accent, size: 22),
              SizedBox(width: 8),
              Text(
                'Workout JSON (AI Standard)',
                style: TextStyle(fontSize: 18, color: AppColors.textPrimary),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Formato standard generato per/da LLM. Puoi modificare il JSON o incollarne uno generato da un\'IA e applicarlo subito.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                NeumorphicCard(
                  padding: const EdgeInsets.all(10),
                  borderRadius: 12,
                  style: NeumorphicStyle.inset,
                  child: TextField(
                    controller: jsonController,
                    maxLines: 14,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: AppColors.accentLight,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: jsonController.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('JSON copiato negli appunti!')),
                );
              },
              child: const Text('Copia'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () {
                try {
                  final decoded = jsonDecode(jsonController.text) as Map<String, dynamic>;
                  final newPlan = WorkoutPlan.fromJson(decoded);
                  final convertedPreset = newPlan.toPreset();
                  preset.name = convertedPreset.name;
                  preset.description = convertedPreset.description;
                  preset.isIntervalTraining = true;
                  preset.intervals = convertedPreset.intervals;
                  preset.announceStart = convertedPreset.announceStart;
                  preset.announceEnd = convertedPreset.announceEnd;
                  preset.announceSummary = convertedPreset.announceSummary;
                  provider.updatePreset(preset);
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Workout aggiornato dal JSON!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Errore JSON non valido: $e')),
                  );
                }
              },
              child: const Text('Applica'),
            ),
          ],
        );
      },
    );
  }
}







