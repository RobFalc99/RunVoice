import 'package:flutter/material.dart';
import '../services/tts_service.dart';

class TtsProvider extends ChangeNotifier {
  final TtsService _service = TtsService();
  bool _isInitialized = false;
  List<Map<String, String>> _availableVoices = [];
  String _selectedVoice = '';

  TtsService get service => _service;
  bool get isInitialized => _isInitialized;
  List<Map<String, String>> get availableVoices => _availableVoices;
  String get selectedVoice => _selectedVoice;

  Future<void> init() async {
    await _service.init();
    _availableVoices = _service.availableVoices;
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setVoice(String voiceName) async {
    _selectedVoice = voiceName;
    await _service.setVoice(voiceName);
    notifyListeners();
  }

  Future<void> setSpeechRate(double rate) async {
    // Normal flutter tts uses 0.0 to 1.0. App uses 1.0 to 2.0.
    // Map 1.0->0.5, 2.0->1.0
    await _service.setSpeechRate(rate * 0.5);
  }

  Future<void> testVoice(String message) async {
    await _service.speakNow(message);
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
