import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io' show Platform;
import '../config/localization/locale_controller.dart';

class TTSService {
  final FlutterTts _tts = FlutterTts();
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;
  TTSService() {
    _init();
    LocaleController.instance.language.addListener(_applySelectedLanguage);
  }
  Future<void> _init() async {
    try {
      if (Platform.isAndroid) {
        await _tts.setEngine('com.google.android.tts');
      }
      await _applySelectedLanguage();
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
    } catch (e) {}
    _tts.setCompletionHandler(() {
      _isPlaying = false;
    });
  }

  Future<void> _applySelectedLanguage() =>
      _tts.setLanguage(LocaleController.instance.locale.toLanguageTag());

  Future<void> speak(String text) async {
    if (_isPlaying) await stop();
    await _applySelectedLanguage();
    _isPlaying = true;
    await _tts.speak(text);
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
