import 'package:flutter_tts/flutter_tts.dart';

/// TTS service wrapper for AI-generated narration.
class TTSService {
  final FlutterTts _tts = FlutterTts();
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  TTSService() {
    _init();
  }

  Future<void> _init() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setCompletionHandler(() {
      _isPlaying = false;
    });
  }

  /// Speak the given text.
  Future<void> speak(String text) async {
    if (_isPlaying) await stop();
    _isPlaying = true;
    await _tts.speak(text);
  }

  /// Stop current narration.
  Future<void> stop() async {
    _isPlaying = false;
    await _tts.stop();
  }

  /// Pause narration.
  Future<void> pause() async {
    _isPlaying = false;
    await _tts.pause();
  }

  /// Dispose resources.
  Future<void> dispose() async {
    await _tts.stop();
  }
}
