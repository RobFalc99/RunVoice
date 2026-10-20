import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/bluetooth_provider.dart';
import '../providers/location_provider.dart';
import '../providers/tts_provider.dart';
import '../services/gemini_service.dart';
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
  late TextEditingController _geminiApiKeyController;
  bool _initialized = false;
  bool _obscureApiKey = true;
  bool _isTestingApiKey = false;
  String? _apiKeyTestMessage;
  bool? _apiKeyTestSuccess;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _maxHRController.dispose();
    _geminiApiKeyController.dispose();
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
      _geminiApiKeyController = TextEditingController(
        text: userProvider.profile.geminiApiKey,
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

                    // --- AI ASSISTANT SECTION ---
                    const SizedBox(height: 28),
                    _sectionTitle('ASSISTENTE AI (GEMINI)'),
                    const SizedBox(height: 12),
                    _buildAiSection(userProvider),

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

  Widget _buildAiSection(UserProvider userProvider) {
    return Container(
      padding: const EdgeInsets.all(18),
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
              const Icon(
                Icons.auto_awesome,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Google Gemini AI',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Generazione automatica allenamenti da linguaggio naturale',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _geminiApiKeyController,
            obscureText: _obscureApiKey,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Google Gemini API Key',
              hintText: 'Incolla la tua API Key',
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      _obscureApiKey
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () => setState(
                      () => _obscureApiKey = !_obscureApiKey,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.content_paste),
                    onPressed: () async {
                      final data = await Clipboard.getData(Clipboard.kTextPlain);
                      if (data?.text != null) {
                        final key = data!.text!.trim();
                        _geminiApiKeyController.text = key;
                        userProvider.updateGeminiApiKey(key);
                      }
                    },
                  ),
                ],
              ),
            ),
            onChanged: (v) => userProvider.updateGeminiApiKey(v.trim()),
          ),
          if (_apiKeyTestMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (_apiKeyTestSuccess ?? false)
                    ? Colors.green.withValues(alpha: 0.14)
                    : Colors.red.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (_apiKeyTestSuccess ?? false)
                      ? Colors.green.withValues(alpha: 0.35)
                      : Colors.red.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    (_apiKeyTestSuccess ?? false)
                        ? Icons.check_circle
                        : Icons.error_outline,
                    color: (_apiKeyTestSuccess ?? false)
                        ? Colors.green
                        : Colors.red,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _apiKeyTestMessage!,
                      style: TextStyle(
                        color: (_apiKeyTestSuccess ?? false)
                            ? Colors.green
                            : Colors.red,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isTestingApiKey
                  ? null
                  : () async {
                      final key = _geminiApiKeyController.text.trim();
                      userProvider.updateGeminiApiKey(key);
                      setState(() {
                        _isTestingApiKey = true;
                        _apiKeyTestMessage = null;
                      });
                      final res = await GeminiService.testApiKey(key);
                      if (!mounted) return;
                      setState(() {
                        _isTestingApiKey = false;
                        _apiKeyTestSuccess = res.success;
                        _apiKeyTestMessage = res.message;
                      });
                    },
              icon: _isTestingApiKey
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(
                _isTestingApiKey
                    ? 'Verifica connessione...'
                    : 'Salva e Verifica Connessione',
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.info.withValues(alpha: 0.25),
              ),
            ),
            child: const Text(
              'Gemini 2.5 Flash è perfetto per la generazione di allenamenti: è disponibile gratuitamente tramite Google AI Studio (15 RPM / 1.500 RPD), ideale per 3-4 richieste al giorno.\n\nOttieni la tua chiave gratuita su aistudio.google.com/apikey',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
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
