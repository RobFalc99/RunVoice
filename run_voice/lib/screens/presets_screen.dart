import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/preset_provider.dart';
import '../models/preset.dart';
import '../widgets/preset_tile.dart';
import '../utils/constants.dart';
import 'preset_editor_screen.dart';

class PresetsScreen extends StatelessWidget {
  const PresetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final presetProvider = context.watch<PresetProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Preset',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Configura i tuoi avvisi personalizzati',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Presets list
            if (presetProvider.presets.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.playlist_add,
                        size: 64,
                        color: AppColors.textMuted,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Nessun preset',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Crea il tuo primo preset di avvisi',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final preset = presetProvider.presets[index];
                    return PresetTile(
                      preset: preset,
                      isSelected: preset.id == presetProvider.selectedPresetId,
                      onTap: () => presetProvider.selectPreset(preset.id),
                      onEdit: () => _navigateToEditor(context, preset),
                      onDelete: () =>
                          _confirmDelete(context, presetProvider, preset),
                      onDuplicate: () =>
                          presetProvider.duplicatePreset(preset.id),
                    );
                  }, childCount: presetProvider.presets.length),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePresetDialog(context, presetProvider),
        icon: const Icon(Icons.add),
        label: const Text('Nuovo Preset'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _navigateToEditor(BuildContext context, Preset preset) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PresetEditorScreen(presetId: preset.id),
      ),
    );
  }

  void _showCreatePresetDialog(BuildContext context, PresetProvider provider) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Nuovo Preset',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Nome',
                hintText: 'Es: Corsa Lenta',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Descrizione (opzionale)',
                hintText: 'Es: Avvisi ogni 2 minuti',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final preset = await provider.createPreset(
                  name: nameController.text,
                  description: descController.text,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) _navigateToEditor(context, preset);
              }
            },
            child: const Text('Crea'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    PresetProvider provider,
    Preset preset,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Eliminare preset?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Sei sicuro di voler eliminare "${preset.name}"?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deletePreset(preset.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }
}
