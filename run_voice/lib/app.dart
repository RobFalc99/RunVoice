import 'package:flutter/material.dart';
import 'screens/training_screen.dart';
import 'screens/presets_screen.dart';
import 'screens/settings_screen.dart';
import 'utils/constants.dart';

class RunVoiceApp extends StatefulWidget {
  const RunVoiceApp({super.key});

  @override
  State<RunVoiceApp> createState() => _RunVoiceAppState();
}

class _RunVoiceAppState extends State<RunVoiceApp> {
  int _currentIndex = 0;

  final _screens = const [TrainingScreen(), PresetsScreen(), SettingsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.surfaceHighlight, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) =>
              setState(() => _currentIndex = index),
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primary.withValues(alpha: 0.15),
          height: 70,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.directions_run_outlined),
              selectedIcon: Icon(
                Icons.directions_run,
                color: AppColors.primary,
              ),
              label: 'Allenamento',
            ),
            NavigationDestination(
              icon: Icon(Icons.playlist_play_outlined),
              selectedIcon: Icon(Icons.playlist_play, color: AppColors.primary),
              label: 'Preset',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings, color: AppColors.primary),
              label: 'Impostazioni',
            ),
          ],
        ),
      ),
    );
  }
}
