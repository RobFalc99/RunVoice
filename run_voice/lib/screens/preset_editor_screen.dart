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
import '../widgets/neumorphic_segmented_control.dart';
import '../widgets/neumorphic_switch.dart';
import '../widgets/alert_setup_sheet.dart';
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

            // Mode Selection (ISO 9241 Ergonomic Segmented Control)
            const Text(
              'STRUTTURA ALLENAMENTO',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            NeumorphicSegmentedControl<bool>(
              value: preset.isIntervalTraining,
              minHeight: 52,
              onChanged: (isIntervals) {
                preset.isIntervalTraining = isIntervals;
                presetProvider.updatePreset(preset);
              },
              segments: const [
                NeumorphicSegment<bool>(
                  value: false,
                  label: 'Corsa Continua',
                  icon: Icons.directions_run,
                ),
                NeumorphicSegment<bool>(
                  value: true,
                  label: 'Ripetute & Fasi',
                  icon: Icons.repeat,
                ),
              ],
            ),

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

            if (preset.isIntervalTraining) ...[
              _buildIntervalsSection(context, presetProvider, preset),
            ] else ...[
              // Standard Alerts section
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'AVVISI PERIODICI',
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
                    onPressed: () => _showAddAlertSheet(
                      context,
                      presetProvider,
                      preset.id,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (preset.alerts.isEmpty)
                _buildEmptyState(
                  'Nessun avviso periodico',
                  () => _showAddAlertSheet(
                    context,
                    presetProvider,
                    preset.id,
                  ),
                )
              else
                ...preset.alerts.map(
                  (alert) => AlertCard(
                    alert: alert,
                    onEdit: () => _showEditAlertSheet(
                      context,
                      presetProvider,
                      preset.id,
                      alert,
                    ),
                    onToggle: (enabled) {
                      presetProvider.updateAlertInPreset(
                        preset.id,
                        alert.copyWith(enabled: enabled),
                      );
                    },
                    onDelete: () {
                      presetProvider.removeAlertFromPreset(preset.id, alert.id);
                    },
                  ),
                ),

              const SizedBox(height: 28),

              // Coaching Alerts section
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
                    onPressed: () => _showAddCoachingSheet(
                      context,
                      presetProvider,
                      preset.id,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (preset.coachingAlerts.isEmpty)
                _buildEmptyState(
                  'Nessun avviso di coaching',
                  () => _showAddCoachingSheet(
                    context,
                    presetProvider,
                    preset.id,
                  ),
                )
              else
                ...preset.coachingAlerts.map(
                  (alert) => CoachingAlertCard(
                    alert: alert,
                    onEdit: () => _showEditCoachingSheet(
                      context,
                      presetProvider,
                      preset.id,
                      alert,
                    ),
                    onToggle: (enabled) {
                      presetProvider.updateCoachingAlertInPreset(
                        preset.id,
                        alert.copyWith(enabled: enabled),
                      );
                    },
                    onDelete: () {
                      presetProvider.removeCoachingAlertFromPreset(
                        preset.id,
                        alert.id,
                      );
                    },
                  ),
                ),
            ],

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

  Widget _buildIntervalsSection(
    BuildContext context,
    PresetProvider provider,
    Preset preset,
  ) {
    return const SizedBox.shrink();
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
                  preset.isIntervalTraining = convertedPreset.isIntervalTraining;
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







