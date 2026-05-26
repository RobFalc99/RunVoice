import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/preset_provider.dart';
import '../providers/bluetooth_provider.dart';
import '../providers/location_provider.dart';
import '../providers/workout_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/sensor_status_card.dart';
import '../widgets/metric_display.dart';
import '../widgets/bluetooth_device_dialog.dart';
import '../models/alert_config.dart';
import '../utils/constants.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatPace(double paceMinPerKm) {
    if (paceMinPerKm <= 0 || paceMinPerKm.isInfinite || paceMinPerKm.isNaN) {
      return '--:--';
    }
    final minutes = paceMinPerKm.floor();
    final seconds = ((paceMinPerKm - minutes) * 60).round();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final presetProvider = context.watch<PresetProvider>();
    final bluetoothProvider = context.watch<BluetoothProvider>();
    final locationProvider = context.watch<LocationProvider>();
    final workoutProvider = context.watch<WorkoutProvider>();
    final userProvider = context.watch<UserProvider>();

    final selectedPreset = presetProvider.selectedPreset;
    final isActive = workoutProvider.isActive;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.directions_run,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ciao, ${userProvider.profile.displayName}!',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          isActive
                              ? 'Allenamento in corso'
                              : 'Pronto a correre?',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Active Workout UI
            if (isActive) ...[
              _buildActiveWorkout(workoutProvider),
            ] else ...[
              // Sensor Status
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'STATO SENSORI',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SensorStatusCard(
                        title: 'GPS',
                        subtitle: locationProvider.isAvailable
                            ? 'Pronto'
                            : 'Non disponibile',
                        icon: Icons.gps_fixed,
                        isConnected: locationProvider.isAvailable,
                        onTap: () => locationProvider.checkAvailability(),
                      ),
                      const SizedBox(height: 10),
                      SensorStatusCard(
                        title: 'Battito Cardiaco',
                        subtitle: bluetoothProvider.isConnected
                            ? '${bluetoothProvider.connectedDeviceName} - ${bluetoothProvider.heartRate} BPM'
                            : 'Non connesso - tocca per connettere',
                        icon: Icons.favorite,
                        isConnected: bluetoothProvider.isConnected,
                        onTap: () => _showBluetoothDialog(bluetoothProvider),
                      ),
                    ],
                  ),
                ),
              ),

              // Preset Selector
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PRESET SELEZIONATO',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildPresetSelector(presetProvider),
                    ],
                  ),
                ),
              ),

              // Start Button
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildStartButton(
                        workoutProvider,
                        selectedPreset,
                        bluetoothProvider.isConnected,
                        locationProvider.isAvailable,
                        userProvider,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPresetSelector(PresetProvider presetProvider) {
    final selectedPreset = presetProvider.selectedPreset;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: presetProvider.selectedPresetId,
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.playlist_play,
                color: AppColors.primary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.surfaceLight,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            dropdownColor: AppColors.surfaceLight,
            items: presetProvider.presets.map((preset) {
              return DropdownMenuItem(
                value: preset.id,
                child: Text(
                  preset.name,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              );
            }).toList(),
            onChanged: (id) {
              if (id != null) presetProvider.selectPreset(id);
            },
          ),
          if (selectedPreset != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  size: 16,
                  color: AppColors.primary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  '${selectedPreset.activeAlertCount + selectedPreset.activeCoachingCount} avvisi attivi su ${selectedPreset.alerts.length + selectedPreset.coachingAlerts.length}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStartButton(
    WorkoutProvider workoutProvider,
    dynamic selectedPreset,
    bool btConnected,
    bool gpsAvailable,
    UserProvider userProvider,
  ) {
    final canStart = selectedPreset != null && gpsAvailable && btConnected;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: canStart ? _pulseAnimation.value : 1.0,
          child: SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton(
              onPressed: canStart
                  ? () {
                      workoutProvider.setHRZones(userProvider.profile.hrZones);
                      workoutProvider.startWorkout(
                        selectedPreset,
                        speakUnits: userProvider.profile.speakUnits,
                        userName: userProvider.profile.firstName,
                        speakName: userProvider.profile.speakName,
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canStart
                    ? AppColors.primary
                    : AppColors.surfaceHighlight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: canStart ? 8 : 0,
                shadowColor: AppColors.primary.withValues(alpha: 0.4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.play_arrow_rounded,
                    size: 32,
                    color: canStart ? Colors.white : AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'INIZIA ALLENAMENTO',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: canStart ? Colors.white : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  SliverToBoxAdapter _buildActiveWorkout(WorkoutProvider wp) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (wp.activePreset?.isIntervalTraining == true) ...[
              _buildIntervalProgressCard(wp),
              const SizedBox(height: 16),
            ],
            // Timer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.primaryDark.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'TEMPO',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDuration(wp.elapsedTime),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 52,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (wp.isPaused)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'IN PAUSA',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Metrics grid
            Row(
              children: [
                Expanded(
                  child: MetricDisplay(
                    label: 'BPM',
                    value: wp.heartRate > 0 ? '${wp.heartRate}' : '--',
                    icon: Icons.favorite,
                    color: wp.currentZone != null
                        ? AppColors.getZoneColor(wp.currentZone!)
                        : AppColors.error,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricDisplay(
                    label: 'ZONA',
                    value: wp.currentZone != null ? 'Z${wp.currentZone}' : '--',
                    icon: Icons.area_chart,
                    color: wp.currentZone != null
                        ? AppColors.getZoneColor(wp.currentZone!)
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: MetricDisplay(
                    label: 'DISTANZA',
                    value: wp.distanceKm.toStringAsFixed(2),
                    unit: 'km',
                    icon: Icons.straighten,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PaceSlidableBox(
                    currentPace: wp.paceMinPerKm,
                    averagePace: wp.distanceKm > 0 
                        ? (wp.elapsedTime.inSeconds / 60) / wp.distanceKm 
                        : 0.0,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Pause / Resume + Stop buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (wp.isPaused) {
                          wp.resumeWorkout();
                        } else {
                          wp.pauseWorkout();
                        }
                      },
                      icon: Icon(
                        wp.isPaused ? Icons.play_arrow : Icons.pause,
                        size: 24,
                      ),
                      label: Text(
                        wp.isPaused ? 'RIPRENDI' : 'PAUSA',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 56,
                  width: 56,
                  child: ElevatedButton(
                    onPressed: () => _confirmStop(wp),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Icon(Icons.stop, size: 28),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmStop(WorkoutProvider wp) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Terminare allenamento?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Sei sicuro di voler terminare l\'allenamento corrente?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              wp.stopWorkout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Termina'),
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

  Widget _buildIntervalProgressCard(WorkoutProvider wp) {
    final preset = wp.activePreset;
    if (preset == null || preset.intervals.isEmpty) return const SizedBox();

    final currentIndex = wp.currentIntervalIndex;
    final totalSteps = preset.intervals.length;
    
    if (currentIndex >= totalSteps) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 24),
            SizedBox(width: 12),
            Text(
              'Ripetute completate!',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    final currentStep = preset.intervals[currentIndex];
    
    String progressText = '';
    double progressPercent = 0.0;
    
    if (currentStep.type == AlertTrigger.time) {
      final elapsedInStep = wp.elapsedTime - wp.currentIntervalStartTime;
      final elapsedSeconds = elapsedInStep.inSeconds;
      final targetSeconds = currentStep.durationSeconds;
      progressPercent = (elapsedSeconds / targetSeconds).clamp(0.0, 1.0);
      progressText = '${_formatDuration(elapsedInStep)} / ${_formatDuration(Duration(seconds: targetSeconds))}';
    } else {
      final elapsedDistanceKm = wp.distanceKm - wp.currentIntervalStartDistanceKm;
      final elapsedMeters = elapsedDistanceKm * 1000;
      final targetMeters = currentStep.distanceMeters;
      progressPercent = (elapsedMeters / targetMeters).clamp(0.0, 1.0);
      progressText = '${elapsedMeters.round()}m / ${targetMeters.round()}m';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'FASE ${currentIndex + 1} DI $totalSteps',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                currentStep.type == AlertTrigger.time ? Icons.timer : Icons.straighten,
                color: AppColors.accent,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            currentStep.name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                progressText,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                '${(progressPercent * 100).round()}%',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressPercent,
              minHeight: 8,
              backgroundColor: AppColors.surfaceHighlight,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.surfaceHighlight, height: 1),
          const SizedBox(height: 12),
          const Text(
            'STORICO E SEQUENZA FASI',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          
          SizedBox(
            height: 75,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: totalSteps,
              itemBuilder: (context, index) {
                final step = preset.intervals[index];
                final isCompleted = index < currentIndex;
                final isActive = index == currentIndex;
                
                Color cardBg = AppColors.surfaceLight;
                Color borderColor = Colors.transparent;
                Color textColor = AppColors.textSecondary;
                Color durationColor = AppColors.textMuted;
                
                if (isActive) {
                  cardBg = AppColors.primary.withValues(alpha: 0.1);
                  borderColor = AppColors.primary;
                  textColor = AppColors.textPrimary;
                  durationColor = AppColors.primaryLight;
                } else if (isCompleted) {
                  textColor = AppColors.textMuted;
                  durationColor = AppColors.textMuted.withValues(alpha: 0.5);
                }
                
                return Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          if (isCompleted)
                            const Icon(Icons.check_circle, color: AppColors.success, size: 14)
                          else if (isActive)
                            const Icon(Icons.play_circle_filled, color: AppColors.primary, size: 14)
                          else
                            const Icon(Icons.circle_outlined, color: AppColors.textMuted, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${index + 1}. ${step.name}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 12,
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        step.displayDuration,
                        style: TextStyle(
                          color: durationColor,
                          fontSize: 11,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PaceSlidableBox extends StatefulWidget {
  final double currentPace;
  final double averagePace;

  const _PaceSlidableBox({required this.currentPace, required this.averagePace});

  @override
  State<_PaceSlidableBox> createState() => _PaceSlidableBoxState();
}

class _PaceSlidableBoxState extends State<_PaceSlidableBox> {
  final PageController _controller = PageController();

  String _formatPace(double paceMinPerKm) {
    if (paceMinPerKm <= 0 || paceMinPerKm.isInfinite || paceMinPerKm.isNaN) {
      return '--:--';
    }
    final minutes = paceMinPerKm.floor();
    final seconds = ((paceMinPerKm - minutes) * 60).round();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Opacity(
          opacity: 0,
          child: const MetricDisplay(
            label: 'PASSO MEDIO',
            value: '00:00',
            unit: '/km',
            icon: Icons.speed,
          ),
        ),
        Positioned.fill(
          child: PageView(
            controller: _controller,
            children: [
              MetricDisplay(
                label: 'PASSO ATT.',
                value: _formatPace(widget.currentPace),
                unit: '/km',
                icon: Icons.speed,
                color: AppColors.accent,
              ),
              MetricDisplay(
                label: 'PASSO MEDIO',
                value: _formatPace(widget.averagePace),
                unit: '/km',
                icon: Icons.speed,
                color: AppColors.accent,
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 8,
          left: 0,
          right: 0,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final page = _controller.hasClients && _controller.position.haveDimensions
                  ? _controller.page ?? 0.0
                  : 0.0;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDot(page, 0),
                  const SizedBox(width: 4),
                  _buildDot(page, 1),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDot(double currentPage, int index) {
    final isActive = (currentPage.round() == index);
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: isActive ? AppColors.accent : AppColors.surfaceHighlight,
        shape: BoxShape.circle,
      ),
    );
  }
}
