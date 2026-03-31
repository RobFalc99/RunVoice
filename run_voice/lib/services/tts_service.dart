import 'dart:async';
import 'dart:collection';
import 'package:flutter_tts/flutter_tts.dart';

/// TTS service with a non-overlapping FIFO queue
class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  final Queue<String> _queue = Queue<String>();
  bool _isSpeaking = false;
  bool _isInitialized = false;
  List<Map<String, String>> _availableVoices = [];
  String _selectedVoice = '';

  FlutterTts get tts => _flutterTts;

  List<Map<String, String>> get availableVoices => _availableVoices;
  String get selectedVoice => _selectedVoice;
  bool get isSpeaking => _isSpeaking;
  int get queueLength => _queue.length;

  Future<void> init() async {
    if (_isInitialized) return;

    await _flutterTts.setLanguage('it-IT');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    // Set up completion handler for queue processing
    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      _processQueue();
    });

    _flutterTts.setErrorHandler((msg) {
      _isSpeaking = false;
      _processQueue();
    });

    _flutterTts.setCancelHandler(() {
      _isSpeaking = false;
    });

    // Load available voices
    await _loadVoices();

    _isInitialized = true;
  }

  Future<void> _loadVoices() async {
    try {
      final voices = await _flutterTts.getVoices;
      if (voices != null) {
        _availableVoices = (voices as List<dynamic>)
            .map((v) => Map<String, String>.from(v as Map))
            .where(
              (v) =>
                  v['locale']?.startsWith('it') == true ||
                  v['locale']?.startsWith('en') == true,
            )
            .toList();
      }
    } catch (e) {
      _availableVoices = [];
    }
  }

  Future<void> setVoice(String voiceName) async {
    _selectedVoice = voiceName;
    final voice = _availableVoices.firstWhere(
      (v) => v['name'] == voiceName,
      orElse: () => {},
    );
    if (voice.isNotEmpty) {
      await _flutterTts.setVoice({
        'name': voice['name']!,
        'locale': voice['locale']!,
      });
    }
  }

  Future<void> setLanguage(String language) async {
    await _flutterTts.setLanguage(language);
  }

  Future<void> setSpeechRate(double rate) async {
    await _flutterTts.setSpeechRate(rate);
  }

  /// Add a message to the TTS queue (non-overlapping)
  void enqueue(String message) {
    _queue.add(message);
    if (!_isSpeaking) {
      _processQueue();
    }
  }

  /// Process next item in the queue
  Future<void> _processQueue() async {
    if (_queue.isEmpty || _isSpeaking) return;

    _isSpeaking = true;
    final message = _queue.removeFirst();
    await _flutterTts.speak(message);
  }

  /// Speak immediately (clears queue)
  Future<void> speakNow(String message) async {
    _queue.clear();
    await _flutterTts.stop();
    _isSpeaking = true;
    await _flutterTts.speak(message);
  }

  /// Stop all speech and clear queue
  Future<void> stop() async {
    _queue.clear();
    _isSpeaking = false;
    await _flutterTts.stop();
  }

  void dispose() {
    stop();
  }
}
