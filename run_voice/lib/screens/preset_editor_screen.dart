import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

            // Mode Selection
            const Text(
              'MODALITÀ ALLENAMENTO',
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
              child: SwitchListTile(
                title: const Text(
                  'Modalità Ripetute',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                subtitle: const Text(
                  'Esegui una sequenza di passi uno dopo l\'altro',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                activeTrackColor: AppColors.primary,
                value: preset.isIntervalTraining,
                onChanged: (v) {
                  preset.isIntervalTraining = v;
                  presetProvider.updatePreset(preset);
                },
              ),
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
                    activeTrackColor: AppColors.primary,
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
                    activeTrackColor: AppColors.primary,
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
                  () => _showAddCoachingDialog(
                    context,
                    presetProvider,
                    preset.id,
                  ),
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

  // DIALOGS

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
    AlertConfig? existing, {
    IntervalStep? step,
  }) {
    final isEditing = existing != null;
    AlertMetric selectedMetric = existing?.metric ?? AlertMetric.bpm;
    AlertMode selectedMode = existing?.mode ?? AlertMode.current;
    AlertTrigger selectedTrigger = existing?.trigger ?? AlertTrigger.time;
    final nameController = TextEditingController(text: existing?.name ?? '');
    int intervalSeconds = existing?.intervalSeconds ?? 60;
    double intervalMeters = existing?.intervalMeters ?? 1000;
    double lapDistanceKm = existing?.lapDistanceKm ?? 1.0;

    String timeUnit = 'secondi';
    String distanceUnit = 'metri';

    if (isEditing) {
      if (existing.trigger == AlertTrigger.time) {
        if (existing.intervalSeconds % 60 == 0) {
          timeUnit = 'minuti';
        }
      } else {
        if (existing.intervalMeters % 1000 == 0) {
          distanceUnit = 'chilometri';
        }
      }
    }

    final intervalSecondsController = TextEditingController(
      text: timeUnit == 'minuti'
          ? (intervalSeconds / 60.0).toStringAsFixed(1)
          : '$intervalSeconds',
    );
    final intervalMetersController = TextEditingController(
      text: distanceUnit == 'chilometri'
          ? (intervalMeters / 1000.0).toStringAsFixed(1)
          : '${intervalMeters.round()}',
    );
    final lapController = TextEditingController(
      text: lapDistanceKm.toStringAsFixed(1),
    );

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
          child: SingleChildScrollView(
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
                          if (nameController.text.isEmpty || !isEditing) {
                            nameController.text = m.displayName;
                          }
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
                  _buildSliderWithInput(
                    value: lapDistanceKm,
                    min: 0.1,
                    max: 10.0,
                    divisions: 99,
                    controller: lapController,
                    formatDisplay: (v) => v.toStringAsFixed(1),
                    onSliderChanged: (v) {
                      setModalState(() {
                        lapDistanceKm = v;
                        lapController.text = v.toStringAsFixed(1);
                      });
                    },
                    onTextChanged: (v) {
                      final parsed = double.tryParse(v);
                      if (parsed != null && parsed >= 0.1 && parsed <= 10.0) {
                        setModalState(() => lapDistanceKm = parsed);
                      }
                    },
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
                // Trigger selector
                _buildLabel('ATTIVAZIONE'),
                Wrap(
                  spacing: 8,
                  children: AlertTrigger.values.map((t) {
                    return ChoiceChip(
                      label: Text(t.displayName),
                      selected: selectedTrigger == t,
                      onSelected: (_) {
                        setModalState(() => selectedTrigger = t);
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12),
                if (selectedTrigger == AlertTrigger.time) ...[
                  _buildLabel('INTERVALLO TEMPO'),
                  StatefulBuilder(
                    builder: (context, setState) {
                      final double minVal = timeUnit == 'minuti' ? 0.5 : 10.0;
                      final double maxVal = timeUnit == 'minuti' ? 30.0 : 1800.0;
                      final int divVal = timeUnit == 'minuti' ? 59 : 179;
                      final double currentVal = timeUnit == 'minuti'
                          ? (intervalSeconds / 60.0)
                          : intervalSeconds.toDouble();

                      return Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: currentVal.clamp(minVal, maxVal),
                              min: minVal,
                              max: maxVal,
                              divisions: divVal,
                              label: timeUnit == 'minuti'
                                  ? '${currentVal.toStringAsFixed(1)} min'
                                  : '${currentVal.round()}s',
                              onChanged: (v) {
                                setModalState(() {
                                  if (timeUnit == 'minuti') {
                                    intervalSeconds = (v * 60).round();
                                    intervalSecondsController.text = v.toStringAsFixed(1);
                                  } else {
                                    intervalSeconds = v.round();
                                    intervalSecondsController.text = '${v.round()}';
                                  }
                                });
                                setState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 65,
                            child: TextField(
                              controller: intervalSecondsController,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                              ],
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                filled: true,
                                fillColor: AppColors.surfaceLight,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onChanged: (v) {
                                final parsed = double.tryParse(v);
                                if (parsed != null) {
                                  setModalState(() {
                                    if (timeUnit == 'minuti') {
                                      intervalSeconds = (parsed * 60).round().clamp(10, 1800);
                                    } else {
                                      intervalSeconds = parsed.round().clamp(10, 1800);
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: timeUnit,
                            dropdownColor: AppColors.surfaceLight,
                            underline: const SizedBox(),
                            icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary, size: 18),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'secondi', child: Text('sec')),
                              DropdownMenuItem(value: 'minuti', child: Text('min')),
                            ],
                            onChanged: (newUnit) {
                              if (newUnit != null) {
                                setModalState(() {
                                  timeUnit = newUnit;
                                  if (newUnit == 'minuti') {
                                    intervalSecondsController.text = (intervalSeconds / 60.0).toStringAsFixed(1);
                                  } else {
                                    intervalSecondsController.text = '$intervalSeconds';
                                  }
                                });
                                setState(() {});
                              }
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ] else ...[
                  _buildLabel('INTERVALLO DISTANZA'),
                  StatefulBuilder(
                    builder: (context, setState) {
                      final double minVal = distanceUnit == 'chilometri' ? 0.1 : 100.0;
                      final double maxVal = distanceUnit == 'chilometri' ? 10.0 : 10000.0;
                      final int divVal = distanceUnit == 'chilometri' ? 99 : 99;
                      final double currentVal = distanceUnit == 'chilometri'
                          ? (intervalMeters / 1000.0)
                          : intervalMeters;

                      return Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: currentVal.clamp(minVal, maxVal),
                              min: minVal,
                              max: maxVal,
                              divisions: divVal,
                              label: distanceUnit == 'chilometri'
                                  ? '${currentVal.toStringAsFixed(1)} km'
                                  : '${currentVal.round()} m',
                              onChanged: (v) {
                                setModalState(() {
                                  if (distanceUnit == 'chilometri') {
                                    intervalMeters = v * 1000.0;
                                    intervalMetersController.text = v.toStringAsFixed(1);
                                  } else {
                                    intervalMeters = v;
                                    intervalMetersController.text = '${v.round()}';
                                  }
                                });
                                setState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 65,
                            child: TextField(
                              controller: intervalMetersController,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                              ],
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                filled: true,
                                fillColor: AppColors.surfaceLight,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onChanged: (v) {
                                final parsed = double.tryParse(v);
                                if (parsed != null) {
                                  setModalState(() {
                                    if (distanceUnit == 'chilometri') {
                                      intervalMeters = (parsed * 1000.0).clamp(100.0, 10000.0);
                                    } else {
                                      intervalMeters = parsed.clamp(100.0, 10000.0);
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: distanceUnit,
                            dropdownColor: AppColors.surfaceLight,
                            underline: const SizedBox(),
                            icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary, size: 18),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'metri', child: Text('m')),
                              DropdownMenuItem(value: 'chilometri', child: Text('km')),
                            ],
                            onChanged: (newUnit) {
                              if (newUnit != null) {
                                setModalState(() {
                                  distanceUnit = newUnit;
                                  if (newUnit == 'chilometri') {
                                    intervalMetersController.text = (intervalMeters / 1000.0).toStringAsFixed(1);
                                  } else {
                                    intervalMetersController.text = '${intervalMeters.round()}';
                                  }
                                });
                                setState(() {});
                              }
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],

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
                        trigger: selectedTrigger,
                        intervalSeconds: intervalSeconds,
                        intervalMeters: intervalMeters,
                        lapDistanceKm: lapDistanceKm,
                        enabled: isEditing ? existing.enabled : true,
                      );
                      if (step != null) {
                        if (isEditing) {
                          final idx = step.alerts.indexWhere((a) => a.id == existing.id);
                          if (idx != -1) {
                            step.alerts[idx] = newAlert;
                          }
                        } else {
                          step.alerts.add(newAlert);
                        }
                        provider.updateIntervalInPreset(presetId, step);
                      } else {
                        if (isEditing) {
                          provider.updateAlertInPreset(presetId, newAlert);
                        } else {
                          provider.addAlertToPreset(presetId, newAlert);
                        }
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
    CoachingAlert? existing, {
    IntervalStep? step,
  }) {
    final isEditing = existing != null;
    AlertMetric selectedMetric = existing?.metric ?? AlertMetric.speed;
    final nameController = TextEditingController(text: existing?.name ?? '');
    double minValue = existing?.minValue ?? 5.0;
    double maxValue = existing?.maxValue ?? 15.0;
    int okIntervalSeconds = existing?.okIntervalSeconds ?? 120;
    int outOfRangeDelaySeconds = existing?.outOfRangeDelaySeconds ?? 10;
    bool speakCurrentValue = existing?.speakCurrentValue ?? false;
    bool notifyOnReturn = existing?.notifyOnReturn ?? true;
    int calculationWindowSeconds = existing?.calculationWindowSeconds ?? 0;
    bool speakValueEvenWhenOk = existing?.speakValueEvenWhenOk ?? false;
    bool useWindow = calculationWindowSeconds > 0;

    final okController = TextEditingController(text: '$okIntervalSeconds');
    final outController = TextEditingController(
      text: '$outOfRangeDelaySeconds',
    );
    final minController = TextEditingController(
      text:
          (selectedMetric == AlertMetric.bpm ||
              selectedMetric == AlertMetric.hrZone)
          ? minValue.round().toString()
          : minValue.toStringAsFixed(1),
    );
    final maxController = TextEditingController(
      text:
          (selectedMetric == AlertMetric.bpm ||
              selectedMetric == AlertMetric.hrZone)
          ? maxValue.round().toString()
          : maxValue.toStringAsFixed(1),
    );

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
          child: SingleChildScrollView(
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
                              if (nameController.text.isEmpty || !isEditing) {
                                nameController.text =
                                    'Coaching ${m.displayName}';
                              }
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
                              minController.text =
                                  (m == AlertMetric.bpm ||
                                      m == AlertMetric.hrZone)
                                  ? minValue.round().toString()
                                  : minValue.toStringAsFixed(1);
                              maxController.text =
                                  (m == AlertMetric.bpm ||
                                      m == AlertMetric.hrZone)
                                  ? maxValue.round().toString()
                                  : maxValue.toStringAsFixed(1);
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
                if (selectedMetric == AlertMetric.hrZone) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(6, (index) {
                      final isSelected =
                          minValue.round() == index &&
                          maxValue.round() == index;
                      return ChoiceChip(
                        label: Text('Zona $index'),
                        selected: isSelected,
                        onSelected: (_) {
                          setModalState(() {
                            minValue = index.toDouble();
                            maxValue = index.toDouble();
                          });
                        },
                      );
                    }),
                  ),
                ] else if (selectedMetric == AlertMetric.bpm) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'BPM Minimo',
                            suffixText: 'bpm',
                          ),
                          onChanged: (v) {
                            final val = double.tryParse(v);
                            if (val != null) minValue = val;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: maxController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'BPM Massimo',
                            suffixText: 'bpm',
                          ),
                          onChanged: (v) {
                            final val = double.tryParse(v);
                            if (val != null) maxValue = val;
                          },
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: RangeSlider(
                          values: RangeValues(minValue, maxValue),
                          min: 0,
                          max: 30,
                          divisions: 300,
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
                ],

                const SizedBox(height: 12),

                // Option: speak current value
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text(
                          'Dici anche il valore attuale',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: const Text(
                          'Es: "velocità troppo alta, a 18.5" invece di "velocità troppo alta"',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        activeTrackColor: AppColors.primary,
                        value: speakCurrentValue,
                        onChanged: (v) =>
                            setModalState(() {
                              speakCurrentValue = v;
                              if (!v) {
                                speakValueEvenWhenOk = false;
                              }
                            }),
                      ),
                      if (speakCurrentValue) ...[
                        const Divider(height: 1, color: AppColors.surfaceHighlight),
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: SwitchListTile(
                            dense: true,
                            title: const Text(
                              'Anche quando tutto bene',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: const Text(
                              'Dice il valore attuale anche quando sei nel range corretto',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                              ),
                            ),
                            activeTrackColor: AppColors.primary,
                            value: speakValueEvenWhenOk,
                            onChanged: (v) =>
                                setModalState(() => speakValueEvenWhenOk = v),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SwitchListTile(
                    title: const Text(
                      'Avviso rapido rientro in range',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      'Quando torni in range riceverai il primo avviso "tutto bene" dopo il ritardo del fuori range (invece di aspettare l\'intervallo normale).',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    activeTrackColor: AppColors.primary,
                    value: notifyOnReturn,
                    onChanged: (v) => setModalState(() => notifyOnReturn = v),
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text(
                          'Usa finestra temporale (media)',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: const Text(
                          'Calcola il valore medio negli ultimi minuti/secondi anziché quello istantaneo',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        activeTrackColor: AppColors.primary,
                        value: useWindow,
                        onChanged: (v) {
                          setModalState(() {
                            useWindow = v;
                            if (v && calculationWindowSeconds == 0) {
                              calculationWindowSeconds = 90; // Default: 1:30
                            } else if (!v) {
                              calculationWindowSeconds = 0;
                            }
                          });
                        },
                      ),
                      if (useWindow) ...[
                        const Divider(height: 1, color: AppColors.surfaceHighlight),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Durata finestra:',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              Row(
                                children: [
                                  // Minutes dropdown
                                  SizedBox(
                                    width: 75,
                                    child: DropdownButtonFormField<int>(
                                      value: (calculationWindowSeconds ~/ 60).clamp(0, 10),
                                      dropdownColor: AppColors.surfaceLight,
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: AppColors.surfaceHighlight),
                                        ),
                                        suffixText: 'm',
                                      ),
                                      items: List.generate(11, (i) => DropdownMenuItem(value: i, child: Text('$i'))),
                                      onChanged: (m) {
                                        if (m != null) {
                                          setModalState(() {
                                            final currentSec = calculationWindowSeconds % 60;
                                            calculationWindowSeconds = m * 60 + currentSec;
                                            if (calculationWindowSeconds == 0) {
                                              calculationWindowSeconds = 5;
                                            }
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Seconds dropdown
                                  SizedBox(
                                    width: 75,
                                    child: DropdownButtonFormField<int>(
                                      value: ((calculationWindowSeconds % 60) ~/ 5 * 5).clamp(0, 55),
                                      dropdownColor: AppColors.surfaceLight,
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: AppColors.surfaceHighlight),
                                        ),
                                        suffixText: 's',
                                      ),
                                      items: List.generate(12, (i) {
                                        final sec = i * 5;
                                        return DropdownMenuItem(value: sec, child: Text('$sec'));
                                      }),
                                      onChanged: (s) {
                                        if (s != null) {
                                          setModalState(() {
                                            final currentMin = calculationWindowSeconds ~/ 60;
                                            calculationWindowSeconds = currentMin * 60 + s;
                                            if (calculationWindowSeconds == 0) {
                                              calculationWindowSeconds = 5;
                                            }
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),


                const SizedBox(height: 12),
                _buildLabel('AVVISO "TUTTO BENE" (SE NEL RANGE)'),
                _buildSliderWithInput(
                  value: okIntervalSeconds.toDouble(),
                  min: 30,
                  max: 1800,
                  divisions: 177,
                  controller: okController,
                  formatDisplay: (v) => _formatInterval(v.round()),
                  onSliderChanged: (v) {
                    setModalState(() {
                      okIntervalSeconds = v.round();
                      okController.text = '${v.round()}';
                    });
                  },
                  onTextChanged: (v) {
                    final parsed = int.tryParse(v);
                    if (parsed != null && parsed >= 30 && parsed <= 1800) {
                      setModalState(() => okIntervalSeconds = parsed);
                    }
                  },
                ),

                const SizedBox(height: 12),
                _buildLabel('RITARDO AVVISO "FUORI RANGE"'),
                _buildSliderWithInput(
                  value: outOfRangeDelaySeconds.toDouble(),
                  min: 5,
                  max: 120,
                  divisions: 115,
                  controller: outController,
                  formatDisplay: (v) => _formatInterval(v.round()),
                  onSliderChanged: (v) {
                    setModalState(() {
                      outOfRangeDelaySeconds = v.round();
                      outController.text = '${v.round()}';
                    });
                  },
                  onTextChanged: (v) {
                    final parsed = int.tryParse(v);
                    if (parsed != null && parsed >= 5 && parsed <= 120) {
                      setModalState(() => outOfRangeDelaySeconds = parsed);
                    }
                  },
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
                        speakCurrentValue: speakCurrentValue,
                        notifyOnReturn: notifyOnReturn,
                        calculationWindowSeconds: calculationWindowSeconds,
                        speakValueEvenWhenOk: speakValueEvenWhenOk,
                      );
                      if (step != null) {
                        if (isEditing) {
                          final idx = step.coachingAlerts.indexWhere((c) => c.id == existing.id);
                          if (idx != -1) {
                            step.coachingAlerts[idx] = newAlert;
                          }
                        } else {
                          step.coachingAlerts.add(newAlert);
                        }
                        provider.updateIntervalInPreset(presetId, step);
                      } else {
                        if (isEditing) {
                          provider.updateCoachingAlertInPreset(
                            presetId,
                            newAlert,
                          );
                        } else {
                          provider.addCoachingAlertToPreset(presetId, newAlert);
                        }
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
      ),
    );
  }

  /// A slider with an editable text field next to it
  Widget _buildSliderWithInput({
    required double value,
    required double min,
    required double max,
    required int divisions,
    required TextEditingController controller,
    required String Function(double) formatDisplay,
    required ValueChanged<double> onSliderChanged,
    required ValueChanged<String> onTextChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            label: formatDisplay(value),
            onChanged: onSliderChanged,
          ),
        ),
        SizedBox(
          width: 70,
          child: TextField(
            controller: controller,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              filled: true,
              fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: onTextChanged,
          ),
        ),
      ],
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
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Aggiungi Passo'),
              onPressed: () => _showIntervalDialogInternal(
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
            'Nessun passo configurato',
            () =>
                _showIntervalDialogInternal(context, provider, preset.id, null),
          )
        else
          ...preset.intervals.map(
            (step) => _buildIntervalCard(context, provider, preset.id, step),
          ),
      ],
    );
  }

  Widget _buildIntervalCard(
    BuildContext context,
    PresetProvider provider,
    String presetId,
    IntervalStep step,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  step.type == AlertTrigger.time
                      ? Icons.timer
                      : Icons.straighten,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    step.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Durata: ${step.displayDuration}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.surfaceHighlight, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.notifications_outlined, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 6),
                const Text(
                  'AVVISI DI QUESTA FASE',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 12, color: AppColors.primary),
                  label: const Text('Periodico', style: TextStyle(fontSize: 11, color: AppColors.primary)),
                  onPressed: () => _showAddAlertForStepDialog(context, provider, presetId, step),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                ),
                const SizedBox(width: 10),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 12, color: AppColors.accent),
                  label: const Text('Coaching', style: TextStyle(fontSize: 11, color: AppColors.accent)),
                  onPressed: () => _showAddCoachingForStepDialog(context, provider, presetId, step),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (step.alerts.isEmpty && step.coachingAlerts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Nessun avviso specifico impostato per questa fase.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else ...[
              ...step.alerts.map(
                (alert) => _buildStepAlertRow(context, provider, presetId, step, alert),
              ),
              ...step.coachingAlerts.map(
                (coaching) => _buildStepCoachingRow(context, provider, presetId, step, coaching),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(color: AppColors.surfaceHighlight, height: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.copy,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                  onPressed: () =>
                      provider.duplicateIntervalInPreset(presetId, step),
                  tooltip: 'Duplica',
                ),
                IconButton(
                  icon: const Icon(
                    Icons.edit,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                  onPressed: () => _showIntervalDialogInternal(
                    context,
                    provider,
                    presetId,
                    step,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                    size: 18,
                  ),
                  onPressed: () =>
                      provider.removeIntervalFromPreset(presetId, step.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showIntervalDialogInternal(
    BuildContext context,
    PresetProvider provider,
    String presetId,
    IntervalStep? existing,
  ) {
    final isEditing = existing != null;
    AlertTrigger selectedTrigger = existing?.type ?? AlertTrigger.time;
    final nameController = TextEditingController(text: existing?.name ?? '');
    int durationSeconds = existing?.durationSeconds ?? 60;
    double distanceMeters = existing?.distanceMeters ?? 1000;

    String timeUnit = 'secondi';
    String distanceUnit = 'metri';

    if (isEditing) {
      if (existing.type == AlertTrigger.time) {
        if (existing.durationSeconds % 60 == 0) {
          timeUnit = 'minuti';
        }
      } else {
        if (existing.distanceMeters % 1000 == 0) {
          distanceUnit = 'chilometri';
        }
      }
    }

    final durationController = TextEditingController(
      text: timeUnit == 'minuti'
          ? (durationSeconds / 60.0).toStringAsFixed(1)
          : '$durationSeconds',
    );
    final distanceController = TextEditingController(
      text: distanceUnit == 'chilometri'
          ? (distanceMeters / 1000.0).toStringAsFixed(1)
          : '${distanceMeters.round()}',
    );

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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDragHandle(),
                const SizedBox(height: 20),
                Text(
                  isEditing ? 'Modifica Passo' : 'Nuovo Passo',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Nome Fase (Es: Corsa Veloce, Recupero)',
                  ),
                ),
                const SizedBox(height: 16),
                _buildLabel('TIPO DI DURATA'),
                Wrap(
                  spacing: 8,
                  children: AlertTrigger.values.map((t) {
                    return ChoiceChip(
                      label: Text(t.displayName),
                      selected: selectedTrigger == t,
                      onSelected: (_) {
                        setModalState(() => selectedTrigger = t);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                if (selectedTrigger == AlertTrigger.time) ...[
                  _buildLabel('DURATA TEMPO'),
                  StatefulBuilder(
                    builder: (context, setState) {
                      final double minVal = timeUnit == 'minuti' ? 0.5 : 10.0;
                      final double maxVal = timeUnit == 'minuti' ? 60.0 : 3600.0;
                      final int divVal = timeUnit == 'minuti' ? 119 : 359;
                      final double currentVal = timeUnit == 'minuti'
                          ? (durationSeconds / 60.0)
                          : durationSeconds.toDouble();

                      return Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: currentVal.clamp(minVal, maxVal),
                              min: minVal,
                              max: maxVal,
                              divisions: divVal,
                              label: timeUnit == 'minuti'
                                  ? '${currentVal.toStringAsFixed(1)} min'
                                  : '${currentVal.round()}s',
                              onChanged: (v) {
                                setModalState(() {
                                  if (timeUnit == 'minuti') {
                                    durationSeconds = (v * 60).round();
                                    durationController.text = v.toStringAsFixed(1);
                                  } else {
                                    durationSeconds = v.round();
                                    durationController.text = '${v.round()}';
                                  }
                                });
                                setState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 65,
                            child: TextField(
                              controller: durationController,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                              ],
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                filled: true,
                                fillColor: AppColors.surfaceLight,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onChanged: (v) {
                                final parsed = double.tryParse(v);
                                if (parsed != null) {
                                  setModalState(() {
                                    if (timeUnit == 'minuti') {
                                      durationSeconds = (parsed * 60).round().clamp(10, 3600);
                                    } else {
                                      durationSeconds = parsed.round().clamp(10, 3600);
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: timeUnit,
                            dropdownColor: AppColors.surfaceLight,
                            underline: const SizedBox(),
                            icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary, size: 18),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'secondi', child: Text('sec')),
                              DropdownMenuItem(value: 'minuti', child: Text('min')),
                            ],
                            onChanged: (newUnit) {
                              if (newUnit != null) {
                                setModalState(() {
                                  timeUnit = newUnit;
                                  if (newUnit == 'minuti') {
                                    durationController.text = (durationSeconds / 60.0).toStringAsFixed(1);
                                  } else {
                                    durationController.text = '$durationSeconds';
                                  }
                                });
                                setState(() {});
                              }
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ] else ...[
                  _buildLabel('DURATA DISTANZA'),
                  StatefulBuilder(
                    builder: (context, setState) {
                      final double minVal = distanceUnit == 'chilometri' ? 0.1 : 50.0;
                      final double maxVal = distanceUnit == 'chilometri' ? 10.0 : 10000.0;
                      final int divVal = distanceUnit == 'chilometri' ? 99 : 199;
                      final double currentVal = distanceUnit == 'chilometri'
                          ? (distanceMeters / 1000.0)
                          : distanceMeters;

                      return Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: currentVal.clamp(minVal, maxVal),
                              min: minVal,
                              max: maxVal,
                              divisions: divVal,
                              label: distanceUnit == 'chilometri'
                                  ? '${currentVal.toStringAsFixed(1)} km'
                                  : '${currentVal.round()} m',
                              onChanged: (v) {
                                setModalState(() {
                                  if (distanceUnit == 'chilometri') {
                                    distanceMeters = v * 1000.0;
                                    distanceController.text = v.toStringAsFixed(1);
                                  } else {
                                    distanceMeters = v;
                                    distanceController.text = '${v.round()}';
                                  }
                                });
                                setState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 65,
                            child: TextField(
                              controller: distanceController,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                              ],
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                filled: true,
                                fillColor: AppColors.surfaceLight,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onChanged: (v) {
                                final parsed = double.tryParse(v);
                                if (parsed != null) {
                                  setModalState(() {
                                    if (distanceUnit == 'chilometri') {
                                      distanceMeters = (parsed * 1000.0).clamp(50.0, 10000.0);
                                    } else {
                                      distanceMeters = parsed.clamp(50.0, 10000.0);
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: distanceUnit,
                            dropdownColor: AppColors.surfaceLight,
                            underline: const SizedBox(),
                            icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary, size: 18),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'metri', child: Text('m')),
                              DropdownMenuItem(value: 'chilometri', child: Text('km')),
                            ],
                            onChanged: (newUnit) {
                              if (newUnit != null) {
                                setModalState(() {
                                  distanceUnit = newUnit;
                                  if (newUnit == 'chilometri') {
                                    distanceController.text = (distanceMeters / 1000.0).toStringAsFixed(1);
                                  } else {
                                    distanceController.text = '${distanceMeters.round()}';
                                  }
                                });
                                setState(() {});
                              }
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      final step = IntervalStep(
                        id: isEditing ? existing.id : _uuid.v4(),
                        name: nameController.text.isEmpty
                            ? 'Fase'
                            : nameController.text,
                        type: selectedTrigger,
                        durationSeconds: durationSeconds,
                        distanceMeters: distanceMeters,
                        alerts: isEditing ? existing.alerts : null,
                        coachingAlerts: isEditing ? existing.coachingAlerts : null,
                      );
                      if (isEditing) {
                        provider.updateIntervalInPreset(presetId, step);
                      } else {
                        provider.addIntervalToPreset(presetId, step);
                      }
                      Navigator.pop(ctx);
                    },
                    child: Text(
                      isEditing ? 'Salva Modifiche' : 'Aggiungi',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepAlertRow(
    BuildContext context,
    PresetProvider provider,
    String presetId,
    IntervalStep step,
    AlertConfig alert,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            alert.metric == AlertMetric.bpm ? Icons.favorite : 
            alert.metric == AlertMetric.distance ? Icons.straighten :
            alert.metric == AlertMetric.time ? Icons.timer : Icons.speed,
            size: 14,
            color: AppColors.primary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${alert.name} (${alert.trigger == AlertTrigger.time ? _formatInterval(alert.intervalSeconds) : "${alert.intervalMeters.round()}m"})',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 16, color: AppColors.textSecondary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _showEditAlertForStepDialog(context, provider, presetId, step, alert),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              step.alerts.removeWhere((a) => a.id == alert.id);
              provider.updateIntervalInPreset(presetId, step);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStepCoachingRow(
    BuildContext context,
    PresetProvider provider,
    String presetId,
    IntervalStep step,
    CoachingAlert coaching,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.psychology, size: 14, color: AppColors.accent),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${coaching.name} (${coaching.minValue.round()}-${coaching.maxValue.round()})',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 16, color: AppColors.textSecondary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _showEditCoachingForStepDialog(context, provider, presetId, step, coaching),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              step.coachingAlerts.removeWhere((c) => c.id == coaching.id);
              provider.updateIntervalInPreset(presetId, step);
            },
          ),
        ],
      ),
    );
  }

  void _showAddAlertForStepDialog(
    BuildContext context,
    PresetProvider provider,
    String presetId,
    IntervalStep step,
  ) {
    _showAlertDialogInternal(context, provider, presetId, null, step: step);
  }

  void _showEditAlertForStepDialog(
    BuildContext context,
    PresetProvider provider,
    String presetId,
    IntervalStep step,
    AlertConfig alert,
  ) {
    _showAlertDialogInternal(context, provider, presetId, alert, step: step);
  }

  void _showAddCoachingForStepDialog(
    BuildContext context,
    PresetProvider provider,
    String presetId,
    IntervalStep step,
  ) {
    _showCoachingDialogInternal(context, provider, presetId, null, step: step);
  }

  void _showEditCoachingForStepDialog(
    BuildContext context,
    PresetProvider provider,
    String presetId,
    IntervalStep step,
    CoachingAlert coaching,
  ) {
    _showCoachingDialogInternal(context, provider, presetId, coaching, step: step);
  }
}
