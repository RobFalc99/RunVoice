import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/user_provider.dart';
import 'providers/preset_provider.dart';
import 'providers/bluetooth_provider.dart';
import 'providers/location_provider.dart';
import 'providers/tts_provider.dart';
import 'providers/workout_provider.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // System UI style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize providers
  final userProvider = UserProvider();
  await userProvider.loadProfile();

  final presetProvider = PresetProvider();
  await presetProvider.loadPresets();

  final ttsProvider = TtsProvider();
  await ttsProvider.init();

  final bluetoothProvider = BluetoothProvider();
  final locationProvider = LocationProvider();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: userProvider),
        ChangeNotifierProvider.value(value: presetProvider),
        ChangeNotifierProvider.value(value: ttsProvider),
        ChangeNotifierProvider.value(value: bluetoothProvider),
        ChangeNotifierProvider.value(value: locationProvider),
        ChangeNotifierProvider(
          create: (_) => WorkoutProvider(
            ttsService: ttsProvider.service,
            bluetoothService: bluetoothProvider.service,
            locationService: locationProvider.service,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'RunVoice',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const RunVoiceApp(),
      ),
    ),
  );
}
