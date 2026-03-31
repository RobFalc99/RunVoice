import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/preset_provider.dart';
import '../models/alert_config.dart';
import '../widgets/alert_card.dart';
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

            // Alerts section
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'AVVISI',
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
              Container(
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
                    const Text(
                      'Nessun avviso configurato',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showAddAlertDialog(
                        context,
                        presetProvider,
                        preset.id,
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Aggiungi Avviso'),
                    ),
                  ],
                ),
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

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  void _showAddAlertDialog(
    BuildContext context,
    PresetProvider provider,
    String presetId,
  ) {
    AlertType selectedType = AlertType.heartRateZone;
    final nameController = TextEditingController();
    int intervalSeconds = 60;

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
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHighlight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Nuovo Avviso',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),

              // Alert type selector
              const Text(
                'TIPO DI AVVISO',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: AlertType.values.map((type) {
                  final isSelected = selectedType == type;
                  return ChoiceChip(
                    label: Text(type.displayName),
                    selected: isSelected,
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    backgroundColor: AppColors.surfaceLight,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.5)
                          : AppColors.surfaceHighlight,
                    ),
                    onSelected: (_) {
                      setModalState(() {
                        selectedType = type;
                        if (nameController.text.isEmpty) {
                          nameController.text = type.displayName;
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Nome avviso',
                  hintText: 'Es: Battito ogni 2 min',
                ),
              ),

              const SizedBox(height: 16),
              const Text(
                'INTERVALLO',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: intervalSeconds.toDouble(),
                      min: 10,
                      max: 600,
                      divisions: 59,
                      label: _formatInterval(intervalSeconds),
                      onChanged: (v) {
                        setModalState(() => intervalSeconds = v.round());
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatInterval(intervalSeconds),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    final alert = AlertConfig(
                      id: _uuid.v4(),
                      name: nameController.text.isEmpty
                          ? selectedType.displayName
                          : nameController.text,
                      type: selectedType,
                      intervalSeconds: intervalSeconds,
                    );
                    provider.addAlertToPreset(presetId, alert);
                    Navigator.pop(ctx);
                  },
                  child: const Text(
                    'Aggiungi Avviso',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditAlertDialog(
    BuildContext context,
    PresetProvider provider,
    String presetId,
    AlertConfig alert,
  ) {
    final nameController = TextEditingController(text: alert.name);
    AlertType selectedType = alert.type;
    int intervalSeconds = alert.intervalSeconds;

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
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHighlight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Modifica Avviso',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'TIPO DI AVVISO',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: AlertType.values.map((type) {
                  final isSelected = selectedType == type;
                  return ChoiceChip(
                    label: Text(type.displayName),
                    selected: isSelected,
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    backgroundColor: AppColors.surfaceLight,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.5)
                          : AppColors.surfaceHighlight,
                    ),
                    onSelected: (_) {
                      setModalState(() => selectedType = type);
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Nome avviso'),
              ),

              const SizedBox(height: 16),
              const Text(
                'INTERVALLO',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: intervalSeconds.toDouble(),
                      min: 10,
                      max: 600,
                      divisions: 59,
                      label: _formatInterval(intervalSeconds),
                      onChanged: (v) {
                        setModalState(() => intervalSeconds = v.round());
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatInterval(intervalSeconds),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    provider.updateAlertInPreset(
                      presetId,
                      alert.copyWith(
                        name: nameController.text,
                        type: selectedType,
                        intervalSeconds: intervalSeconds,
                      ),
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text(
                    'Salva Modifiche',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
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
