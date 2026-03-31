import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/preset_provider.dart';
import '../models/preset.dart';
import '../models/alert_config.dart';
import '../widgets/alert_card.dart';
import '../widgets/coaching_alert_card.dart';
import '../utils/constants.dart';

class PresetEditorScreen extends StatefulWidget {
  final String presetId;

  const PresetEditorScreen({super.key, required this.presetId});

  @override
  State<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends State<PresetEditorScreen> {
  final _uuid = const Uuid();
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
          'Modifica Preset',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
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
                  SwitchListTile(
                    title: const Text(
                      'Inizio/Fine allenamento',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    activeColor: AppColors.primary,
                    value: preset.announceStart,
                    onChanged: (v) {
                      preset.announceStart = v;
                      preset.announceEnd = v;
                      presetProvider.updatePreset(preset);
                    },
                  ),
                  Divider(color: AppColors.surfaceHighlight, height: 1),
                  SwitchListTile(
                    title: const Text(
                      'Sommario finale',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    activeColor: AppColors.primary,
                    value: preset.announceSummary,
                    onChanged: (v) {
                      preset.announceSummary = v;
                      presetProvider.updatePreset(preset);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

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
                  onPressed: () =>
                      _showAddAlertDialog(context, presetProvider, preset.id),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (preset.alerts.isEmpty)
              _buildEmptyState(
                'Nessun avviso periodico',
                () => _showAddAlertDialog(context, presetProvider, preset.id),
              )
            else
              ...preset.alerts.map(
                (alert) => AlertCard(
                  alert: alert,
                  onEdit: () => _showEditAlertDialog(
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
                  onPressed: () => _showAddCoachingDialog(
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
                () =>
                    _showAddCoachingDialog(context, presetProvider, preset.id),
              )
            else
              ...preset.coachingAlerts.map(
                (alert) => CoachingAlertCard(
                  alert: alert,
                  onEdit: () => _showEditCoachingDialog(
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
    // We will implement this after tts and workout service integration
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Test audio in riproduzione...')),
    );
  }

  // DIALOGS AHEAD

  void _showAddAlertDialog(
    BuildContext context,
    PresetProvider provider,
    String presetId,
  ) {
    _showAlertDialogInternal(context, provider, presetId, null);
  }

  void _showEditAlertDialog(
    BuildContext context,
    PresetProvider provider,
    String presetId,
    AlertConfig alert,
  ) {
    _showAlertDialogInternal(context, provider, presetId, alert);
  }

  void _showAlertDialogInternal(
    BuildContext context,
    PresetProvider provider,
    String presetId,
    AlertConfig? existing,
  ) {
    final isEditing = existing != null;
    AlertMetric selectedMetric = existing?.metric ?? AlertMetric.bpm;
    AlertMode selectedMode = existing?.mode ?? AlertMode.current;
    final nameController = TextEditingController(text: existing?.name ?? '');
    int intervalSeconds = existing?.intervalSeconds ?? 60;
    double lapDistanceKm = existing?.lapDistanceKm ?? 1.0;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDragHandle(),
              const SizedBox(height: 20),
              Text(
                isEditing ? 'Modifica Avviso' : 'Nuovo Avviso',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),

              // Metric selector
              _buildLabel('METRICA'),
              Wrap(
                spacing: 8,
                children: AlertMetric.values.map((m) {
                  return ChoiceChip(
                    label: Text(m.displayName),
                    selected: selectedMetric == m,
                    onSelected: (_) {
                      setModalState(() {
                        selectedMetric = m;
                        if (nameController.text.isEmpty || !isEditing)
                          nameController.text = m.displayName;
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),
              // Mode selector
              _buildLabel('MODALITÀ'),
              Wrap(
                spacing: 8,
                children: AlertMode.values.map((m) {
                  return ChoiceChip(
                    label: Text(m.displayName),
                    selected: selectedMode == m,
                    onSelected: (_) {
                      setModalState(() => selectedMode = m);
                    },
                  );
                }).toList(),
              ),

              if (selectedMode == AlertMode.lap) ...[
                const SizedBox(height: 12),
                _buildLabel('DISTANZA GIRO (KM)'),
                Slider(
                  value: lapDistanceKm,
                  min: 0.1,
                  max: 10.0,
                  divisions: 99,
                  label: lapDistanceKm.toStringAsFixed(1),
                  onChanged: (v) => setModalState(() => lapDistanceKm = v),
                ),
              ],

              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Testo da pronunciare',
                  hintText: 'Es: Il tuo battito è',
                ),
              ),

              const SizedBox(height: 16),
              _buildLabel('INTERVALLO'),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: intervalSeconds.toDouble(),
                      min: 10,
                      max: 1800,
                      divisions: 179,
                      label: _formatInterval(intervalSeconds),
                      onChanged: (v) =>
                          setModalState(() => intervalSeconds = v.round()),
                    ),
                  ),
                  _buildValueTag(_formatInterval(intervalSeconds)),
                ],
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    final newAlert = AlertConfig(
                      id: isEditing ? existing.id : _uuid.v4(),
                      name: nameController.text.isEmpty
                          ? selectedMetric.displayName
                          : nameController.text,
                      metric: selectedMetric,
                      mode: selectedMode,
                      lapDistanceKm: lapDistanceKm,
                      intervalSeconds: intervalSeconds,
                      enabled: isEditing ? existing.enabled : true,
                    );
                    if (isEditing) {
                      provider.updateAlertInPreset(presetId, newAlert);
                    } else {
                      provider.addAlertToPreset(presetId, newAlert);
                    }
                    Navigator.pop(ctx);
                  },
                  child: Text(
                    isEditing ? 'Salva Modifiche' : 'Aggiungi Avviso',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCoachingDialog(
    BuildContext context,
    PresetProvider provider,
    String presetId,
  ) {
    _showCoachingDialogInternal(context, provider, presetId, null);
  }

  void _showEditCoachingDialog(
    BuildContext context,
    PresetProvider provider,
    String presetId,
    CoachingAlert alert,
  ) {
    _showCoachingDialogInternal(context, provider, presetId, alert);
  }

  void _showCoachingDialogInternal(
    BuildContext context,
    PresetProvider provider,
    String presetId,
    CoachingAlert? existing,
  ) {
    final isEditing = existing != null;
    AlertMetric selectedMetric = existing?.metric ?? AlertMetric.speed;
    final nameController = TextEditingController(text: existing?.name ?? '');
    double minValue = existing?.minValue ?? 5.0;
    double maxValue = existing?.maxValue ?? 15.0;
    int okIntervalSeconds = existing?.okIntervalSeconds ?? 120;
    int outOfRangeDelaySeconds = existing?.outOfRangeDelaySeconds ?? 10;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDragHandle(),
              const SizedBox(height: 16),
              Text(
                isEditing ? 'Modifica Coaching' : 'Nuovo Coaching',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),

              // Restrict to coaching-compatible metrics
              _buildLabel('METRICA (COACHING)'),
              Wrap(
                spacing: 8,
                children:
                    [
                      AlertMetric.speed,
                      AlertMetric.pace,
                      AlertMetric.bpm,
                      AlertMetric.hrZone,
                    ].map((m) {
                      return ChoiceChip(
                        label: Text(m.displayName),
                        selected: selectedMetric == m,
                        onSelected: (_) {
                          setModalState(() {
                            selectedMetric = m;
                            if (nameController.text.isEmpty || !isEditing)
                              nameController.text = 'Coaching ${m.displayName}';
                            // Reset defaults based on metric
                            if (m == AlertMetric.hrZone) {
                              minValue = 2;
                              maxValue = 3;
                            } else if (m == AlertMetric.bpm) {
                              minValue = 120;
                              maxValue = 160;
                            } else if (m == AlertMetric.pace) {
                              minValue = 4.0;
                              maxValue = 6.0;
                            } else if (m == AlertMetric.speed) {
                              minValue = 10;
                              maxValue = 15;
                            }
                          });
                        },
                      );
                    }).toList(),
              ),

              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Testo di base (es. Velocità)',
                  hintText: 'Sarà seguito da "troppo alta" o "tutto bene"',
                ),
              ),

              const SizedBox(height: 16),
              _buildLabel('RANGE OTTIMALE (${selectedMetric.unit})'),
              Row(
                children: [
                  Expanded(
                    child: RangeSlider(
                      values: RangeValues(minValue, maxValue),
                      min: 0,
                      max: selectedMetric == AlertMetric.bpm ? 250 : 30,
                      divisions: 250,
                      labels: RangeLabels(
                        minValue.toStringAsFixed(1),
                        maxValue.toStringAsFixed(1),
                      ),
                      onChanged: (v) => setModalState(() {
                        minValue = v.start;
                        maxValue = v.end;
                      }),
                    ),
                  ),
                  _buildValueTag(
                    '${minValue.toStringAsFixed(1)} - ${maxValue.toStringAsFixed(1)}',
                  ),
                ],
              ),

              const SizedBox(height: 12),
              _buildLabel('AVVISO STATUS "TUTTO BENE" (SE NEL RANGE)'),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: okIntervalSeconds.toDouble(),
                      min: 30,
                      max: 1800,
                      divisions: 177,
                      label: _formatInterval(okIntervalSeconds),
                      onChanged: (v) =>
                          setModalState(() => okIntervalSeconds = v.round()),
                    ),
                  ),
                  _buildValueTag(_formatInterval(okIntervalSeconds)),
                ],
              ),

              const SizedBox(height: 12),
              _buildLabel('RITARDO AVVISO "FUORI RANGE" (SE FUORI)'),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: outOfRangeDelaySeconds.toDouble(),
                      min: 5,
                      max: 120,
                      divisions: 115,
                      label: _formatInterval(outOfRangeDelaySeconds),
                      onChanged: (v) => setModalState(
                        () => outOfRangeDelaySeconds = v.round(),
                      ),
                    ),
                  ),
                  _buildValueTag(_formatInterval(outOfRangeDelaySeconds)),
                ],
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    final newAlert = CoachingAlert(
                      id: isEditing ? existing.id : _uuid.v4(),
                      name: nameController.text.isEmpty
                          ? 'Coaching ${selectedMetric.displayName}'
                          : nameController.text,
                      metric: selectedMetric,
                      minValue: minValue,
                      maxValue: maxValue,
                      okIntervalSeconds: okIntervalSeconds,
                      outOfRangeDelaySeconds: outOfRangeDelaySeconds,
                      enabled: isEditing ? existing.enabled : true,
                    );
                    if (isEditing) {
                      provider.updateCoachingAlertInPreset(presetId, newAlert);
                    } else {
                      provider.addCoachingAlertToPreset(presetId, newAlert);
                    }
                    Navigator.pop(ctx);
                  },
                  child: Text(
                    isEditing ? 'Salva Modifiche' : 'Aggiungi Coaching',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.surfaceHighlight,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildValueTag(String val) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        val,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatInterval(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (remainingSeconds == 0) return '${minutes}m';
    return '${minutes}m ${remainingSeconds}s';
  }
}
