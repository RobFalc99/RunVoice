import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/bluetooth_provider.dart';
import '../providers/location_provider.dart';
import '../providers/tts_provider.dart';
import '../widgets/zone_editor.dart';
import '../widgets/sensor_status_card.dart';
import '../widgets/bluetooth_device_dialog.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _ageController;
  late TextEditingController _maxHRController;
  bool _initialized = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _maxHRController.dispose();
    super.dispose();
  }

  void _initControllers(UserProvider userProvider) {
    if (!_initialized) {
      _firstNameController = TextEditingController(
        text: userProvider.profile.firstName,
      );
      _lastNameController = TextEditingController(
        text: userProvider.profile.lastName,
      );
      _ageController = TextEditingController(
        text: userProvider.profile.age.toString(),
      );
      _maxHRController = TextEditingController(
        text: userProvider.profile.maxHeartRate.toString(),
      );
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final btProvider = context.watch<BluetoothProvider>();
    final locationProvider = context.watch<LocationProvider>();
    final ttsProvider = context.watch<TtsProvider>();

    _initControllers(userProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  'Impostazioni',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- PROFILE SECTION ---
                    const SizedBox(height: 16),
                    _sectionTitle('PROFILO'),
                    const SizedBox(height: 12),
                    _buildProfileSection(userProvider),

                    // --- SENSORS SECTION ---
                    const SizedBox(height: 28),
                    _sectionTitle('SENSORI'),
                    const SizedBox(height: 12),
                    _buildSensorsSection(btProvider, locationProvider),

                    // --- HR ZONES SECTION ---
                    const SizedBox(height: 28),
                    _sectionTitle('ZONE BATTITO CARDIACO'),
                    const SizedBox(height: 12),
                    _buildHRZonesSection(userProvider),

                    // --- VOICE SECTION ---
                    const SizedBox(height: 28),
                    _sectionTitle('VOCE'),
                    const SizedBox(height: 12),
                    _buildVoiceSection(ttsProvider, userProvider),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildProfileSection(UserProvider userProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Column(
        children: [
          // Avatar
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.directions_run,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Name fields
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _firstNameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    prefixIcon: Icon(Icons.person, size: 20),
                  ),
                  onChanged: (v) =>
                      userProvider.updateName(v, _lastNameController.text),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _lastNameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Cognome'),
                  onChanged: (v) =>
                      userProvider.updateName(_firstNameController.text, v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Pronuncia Nome Switch
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Usa il tuo nome negli avvisi',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: const Text(
              'Es: "Ciao Marco, allenamento iniziato"',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
            activeThumbColor: AppColors.primary,
            value: userProvider.profile.speakName,
            onChanged: (val) {
              userProvider.updateSpeakName(val);
            },
          ),
          const SizedBox(height: 12),

          // Age
          TextField(
            controller: _ageController,
            style: const TextStyle(color: AppColors.textPrimary),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Età',
              prefixIcon: Icon(Icons.cake, size: 20),
              suffixText: 'anni',
            ),
            onChanged: (v) {
              final age = int.tryParse(v);
              if (age != null && age > 0 && age < 120) {
                userProvider.updateAge(age);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSensorsSection(
    BluetoothProvider btProvider,
    LocationProvider locationProvider,
  ) {
    return Column(
      children: [
        SensorStatusCard(
          title: 'GPS',
          subtitle: locationProvider.isAvailable
              ? 'Attivo e pronto'
              : 'Non disponibile - controlla i permessi',
          icon: Icons.gps_fixed,
          isConnected: locationProvider.isAvailable,
          onTap: () async {
            await locationProvider.requestPermissions();
          },
        ),
        const SizedBox(height: 10),
        SensorStatusCard(
          title: 'Sensore Battito',
          subtitle: btProvider.isConnected
              ? '${btProvider.connectedDeviceName} (${btProvider.heartRate} BPM)'
              : 'Non connesso',
          icon: Icons.bluetooth,
          isConnected: btProvider.isConnected,
          isLoading: btProvider.isScanning,
          onTap: () => _showBluetoothDialog(btProvider),
        ),
      ],
    );
  }

  Widget _buildHRZonesSection(UserProvider userProvider) {
    return Column(
      children: [
        // Max HR with calculator
        Container(
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
                  Expanded(
                    child: TextField(
                      controller: _maxHRController,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Battito Massimo',
                        prefixIcon: Icon(
                          Icons.favorite,
                          color: AppColors.error,
                        ),
                        suffixText: 'BPM',
                      ),
                      onChanged: (v) {
                        final hr = int.tryParse(v);
                        if (hr != null && hr > 100 && hr < 250) {
                          userProvider.updateMaxHeartRate(hr);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calculate, size: 18),
                      label: const Text('Tanaka (208−0.7×età)'),
                      onPressed: () {
                        userProvider.calculateFromAge(useTanaka: true);
                        _maxHRController.text = userProvider
                            .profile
                            .maxHeartRate
                            .toString();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        side: BorderSide(
                          color: AppColors.accent.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calculate, size: 18),
                      label: const Text('Classica (220−età)'),
                      onPressed: () {
                        userProvider.calculateFromAge(useTanaka: false);
                        _maxHRController.text = userProvider
                            .profile
                            .maxHeartRate
                            .toString();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.info,
                        side: BorderSide(
                          color: AppColors.info.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Ricalcola zone dal battito massimo'),
                  onPressed: () {
                    userProvider.recalculateZones();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Zone editors
        ...userProvider.profile.hrZones.map(
          (zone) => ZoneEditor(
            zone: zone,
            onMinChanged: (value) =>
                userProvider.updateZone(zone.zoneNumber, minBpm: value),
            onMaxChanged: (value) =>
                userProvider.updateZone(zone.zoneNumber, maxBpm: value),
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceSection(
    TtsProvider ttsProvider,
    UserProvider userProvider,
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
          // Voice Selection
          if (ttsProvider.availableVoices.isNotEmpty) ...[
            const Text(
              'Seleziona voce',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: ttsProvider.availableVoices.length,
                itemBuilder: (context, index) {
                  final voice = ttsProvider.availableVoices[index];
                  final isSelected = voice['name'] == ttsProvider.selectedVoice;
                  return ListTile(
                    dense: true,
                    title: Text(
                      voice['name'] ?? 'Sconosciuta',
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      voice['locale'] ?? '',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                            size: 20,
                          )
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    onTap: () {
                      if (voice['name'] != null) {
                        ttsProvider.setVoice(voice['name']!);
                      }
                    },
                  );
                },
              ),
            ),
          ] else
            const Text(
              'Caricamento voci...',
              style: TextStyle(color: AppColors.textMuted),
            ),

          const SizedBox(height: 16),
          const Divider(color: AppColors.surfaceHighlight),
          const SizedBox(height: 16),

          // Speech Speed
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Velocità di riproduzione',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${userProvider.profile.speechRate}x',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Slider(
            value: userProvider.profile.speechRate,
            min: 1.0,
            max: 2.0,
            divisions: 4,
            label: '${userProvider.profile.speechRate}x',
            onChanged: (val) {
              userProvider.updateSpeechRate(val);
              ttsProvider.setSpeechRate(val);
            },
          ),

          const SizedBox(height: 8),

          // Speak units
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Pronuncia unità di misura (km, bpm...)',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            activeThumbColor: AppColors.primary,
            value: userProvider.profile.speakUnits,
            onChanged: (val) {
              userProvider.updateSpeakUnits(val);
            },
          ),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.volume_up, size: 18),
              label: const Text('Testa voce'),
              onPressed: () {
                ttsProvider.setSpeechRate(userProvider.profile.speechRate);
                ttsProvider.testVoice(
                  'Ciao! Sono la tua assistente vocale per la corsa.',
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showBluetoothDialog(BluetoothProvider btProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const BluetoothDeviceDialog(),
    );
  }
}
