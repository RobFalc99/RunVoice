import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/preset.dart';
import '../models/workout_plan.dart';
import '../providers/preset_provider.dart';
import '../providers/user_provider.dart';
import '../providers/workout_provider.dart';
import '../screens/preset_editor_screen.dart';
import '../screens/settings_screen.dart';
import '../services/gemini_service.dart';
import '../utils/constants.dart';

class AiWorkoutSheet extends StatefulWidget {
  final bool onTheFly;
  final String? initialPrompt;
  final Function(Preset preset)? onStartOnTheFly;
  final Function(Preset preset)? onApplyToEditor;

  const AiWorkoutSheet({
    super.key,
    this.onTheFly = false,
    this.initialPrompt,
    this.onStartOnTheFly,
    this.onApplyToEditor,
  });

  static Future<void> show(
    BuildContext context, {
    bool onTheFly = false,
    String? initialPrompt,
    Function(Preset preset)? onStartOnTheFly,
    Function(Preset preset)? onApplyToEditor,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AiWorkoutSheet(
        onTheFly: onTheFly,
        initialPrompt: initialPrompt,
        onStartOnTheFly: onStartOnTheFly,
        onApplyToEditor: onApplyToEditor,
      ),
    );
  }

  @override
  State<AiWorkoutSheet> createState() => _AiWorkoutSheetState();
}

class _AiWorkoutSheetState extends State<AiWorkoutSheet> {
  late final TextEditingController _promptController;
  bool _isLoading = false;
  String? _errorMessage;
  WorkoutPlan? _generatedPlan;
  bool _showAllSteps = false;

  final List<String> _quickPrompts = const [
    '5x1000m a 4:30 con 2 min recupero',
    '30 min fondo lento con 5 allunghi finali',
    'Piramidale 400-800-1200-800-400 con recupero pari',
    'Riscaldamento 10 min, 8x200m scatti con 1 min camminata, 5 min defaticamento',
  ];

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController(text: widget.initialPrompt ?? '');
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _generate(String apiKey) async {
    final text = _promptController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userProvider = context.read<UserProvider>();
      final model = userProvider.profile.geminiModel;
      final plan = await GeminiService.generateWorkoutPlan(
        apiKey,
        text,
        model: model,
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _generatedPlan = plan;
        _showAllSteps = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<Preset> _saveGeneratedPreset(WorkoutPlan plan) async {
    final presetProvider = context.read<PresetProvider>();
    final preset = plan.toPreset();
    await presetProvider.addPreset(preset);
    return preset;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final apiKey = userProvider.profile.geminiApiKey.trim();
    final hasApiKey = apiKey.isNotEmpty;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Color(0xAA090C10),
              blurRadius: 24,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.onTheFly
                                ? 'Workout Rapido con AI'
                                : 'Crea Allenamento con AI',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Powered by ${userProvider.profile.geminiModelLabel}',
                            style: TextStyle(
                              color: AppColors.primary.withValues(alpha: 0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (!hasApiKey) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chiave API Google non configurata',
                          style: TextStyle(
                            color: AppColors.warning,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Per generare allenamenti con l\'AI gratuita, inserisci prima la tua chiave API nelle Impostazioni.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SettingsScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.settings, size: 16),
                          label: const Text('Apri Impostazioni'),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  TextField(
                    controller: _promptController,
                    maxLines: 3,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Descrivi la tua corsa',
                      hintText:
                          'Es: 10 min riscaldamento, 5x1000m a 4:30 con 2 min recupero, 5 min defaticamento',
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppColors.surfaceHighlight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'ESEMPI RAPIDI:',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _quickPrompts
                        .map(
                          (p) => ActionChip(
                            label: Text(
                              p,
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: AppColors.surface,
                            onPressed: () {
                              setState(() {
                                _promptController.text = p;
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_generatedPlan == null) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : () => _generate(apiKey),
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.auto_awesome),
                        label: Text(
                          _isLoading
                              ? 'Generazione in corso...'
                              : 'Genera Allenamento ✨',
                        ),
                      ),
                    ),
                  ] else ...[
                    _buildPreviewCard(context, _generatedPlan!),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCard(BuildContext context, WorkoutPlan plan) {
    final preset = plan.toPreset();
    final totalAlerts = preset.intervals.fold<int>(
      0,
      (acc, i) => acc + i.alerts.length + i.coachingAlerts.length,
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  plan.totalDuration.displayString,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (plan.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              plan.description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(color: AppColors.surfaceHighlight, height: 1),
          const SizedBox(height: 10),
          if (totalAlerts > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.volume_up,
                    size: 14,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '✓ $totalAlerts avvisi vocali (coaching & periodici) configurati',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "FASI DELL'ALLENAMENTO:",
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              if (plan.steps.length > 6)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showAllSteps = !_showAllSteps;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _showAllSteps ? 'Mostra meno' : 'Mostra tutto (${plan.steps.length})',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _showAllSteps ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          size: 14,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_showAllSteps) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  child: Column(
                    children: plan.steps.map(_buildStepRow).toList(),
                  ),
                ),
              ),
            ),
          ] else ...[
            ...plan.steps.take(6).map(_buildStepRow),
            if (plan.steps.length > 6) ...[
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _showAllSteps = true;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Mostra altro (+${plan.steps.length - 6} fasi)',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
          const SizedBox(height: 16),
          if (widget.onTheFly) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final nav = Navigator.of(context);
                  final workoutProvider = context.read<WorkoutProvider>();
                  final userProvider = context.read<UserProvider>();
                  final saved = await _saveGeneratedPreset(plan);
                  if (!mounted) return;
                  nav.pop();
                  if (widget.onStartOnTheFly != null) {
                    widget.onStartOnTheFly!(saved);
                    return;
                  }
                  await workoutProvider.startWorkout(
                    saved,
                    speakUnits: userProvider.profile.speakUnits,
                    userName: userProvider.profile.displayName,
                    speakName: userProvider.profile.speakName,
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Avvia Ora al Volo 🚀'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final nav = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  final saved = await _saveGeneratedPreset(plan);
                  if (!mounted) return;
                  nav.pop();
                  messenger.showSnackBar(
                    SnackBar(content: Text('Preset "${saved.name}" salvato con successo!')),
                  );
                },
                icon: const Icon(Icons.bookmark_border, size: 18),
                label: const Text('Salva nei Preset'),
              ),
            ),
          ] else if (widget.onApplyToEditor != null) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onApplyToEditor?.call(preset);
                },
                icon: const Icon(Icons.check),
                label: const Text('Applica a Questo Workout'),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final nav = Navigator.of(context);
                  final saved = await _saveGeneratedPreset(plan);
                  if (!mounted) return;
                  nav.pop();
                  nav.push(
                    MaterialPageRoute(
                      builder: (_) => PresetEditorScreen(presetId: saved.id),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('Salva e Apri nell\'Editor 💾'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepRow(WorkoutStep step) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            step.phase.name == 'warmup'
                ? Icons.wb_sunny
                : (step.phase.name == 'cooldown'
                    ? Icons.nightlight_round
                    : Icons.directions_run),
            size: 14,
            color: step.phase.name == 'warmup'
                ? Colors.orange
                : (step.phase.name == 'cooldown'
                    ? Colors.blue
                    : AppColors.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              step.label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                step.duration.displayString,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (step.target.metric != TargetMetric.none) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHighlight.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.surfaceHighlight.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        step.target.metric == TargetMetric.heartRateBpm
                            ? Icons.favorite
                            : Icons.speed,
                        size: 12,
                        color: step.target.metric == TargetMetric.heartRateBpm
                            ? AppColors.error
                            : AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        step.target.metric == TargetMetric.heartRateBpm
                            ? (step.target.displayHeartRate != '--'
                                ? step.target.displayHeartRate
                                : ((step.target.targetHrBpmMin != null &&
                                        step.target.targetHrBpmMax != null)
                                    ? '${step.target.targetHrBpmMin}-${step.target.targetHrBpmMax} bpm'
                                    : '--'))
                            : step.target.displayPace,
                        style: TextStyle(
                          color: step.target.metric == TargetMetric.heartRateBpm
                              ? AppColors.error
                              : AppColors.primary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
