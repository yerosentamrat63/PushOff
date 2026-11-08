import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.55);
      await _flutterTts.setVolume(1.0);
      _isInitialized = true;
    } catch (e) {
      debugPrint('TtsService init warning: $e');
    }
  }

  Future<void> speakRep(int repNumber, {bool enabled = true}) async {
    if (!enabled) return;
    await _speak('$repNumber');
  }

  Future<void> speakAlert(String message, {bool enabled = true}) async {
    if (!enabled) return;
    await _speak(message);
  }

  Future<void> _speak(String text) async {
    try {
      if (!_isInitialized) await initialize();
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('Tts speak error: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('Tts stop error: $e');
    }
  }
}

