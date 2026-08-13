import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io' show Platform;
import '../config/localization/locale_controller.dart';

class TTSService {
  final FlutterTts _tts = FlutterTts();
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;
  Future<void>? _initFuture;

  TTSService() {
    _initFuture = _init();
    LocaleController.instance.language.addListener(_applySelectedLanguage);
  }
  Future<void> _init() async {
    try {
      await _applySelectedLanguage();
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
      print('[TTSService] Initialized successfully with awaitSpeakCompletion(true)');
    } catch (e) {
      print('[TTSService] Error during _init: $e');
    }
    _tts.setCompletionHandler(() {
      _isPlaying = false;
    });
  }

  Future<void> _applySelectedLanguage() async {
    try {
      await _tts.setLanguage(LocaleController.instance.locale.toLanguageTag());
    } catch (e) {
      print('[TTSService] Error setting language: $e');
    }
  }

  Future<void> speak(String text) async {
    _initFuture ??= _init();
    await _initFuture;
    if (_isPlaying) await stop();
    await _applySelectedLanguage();
    _isPlaying = true;
    
    // Clean text for TTS (remove HTML tags and basic markdown symbols)
    String cleanText = text.replaceAll(RegExp(r'<[^>]*>'), '');
    cleanText = cleanText.replaceAll(RegExp(r'[*_#`~]'), '');
    
    print('[TTSService] Speaking: $cleanText');
    final result = await _tts.speak(cleanText);
    print('[TTSService] Speak result: $result');
  }

  Future<void> stop() async {
    _isPlaying = false;
    await _tts.stop();
  }

  Future<void> pause() async {
    _isPlaying = false;
    await _tts.pause();
  }

  Future<void> dispose() async {
    await _tts.stop();
  }
}
