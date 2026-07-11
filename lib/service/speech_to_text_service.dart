import 'dart:developer';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../config/localization/locale_controller.dart';

class SpeechToTextService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool get isListening => _speech.isListening;
  bool get isAvailable => _speech.isAvailable;
  Future<bool> _ensureInitialized({required Function(bool) onListening}) async {
    if (_speech.isAvailable) return true;
    return await _speech.initialize(
      onStatus: (status) {
        log('SpeechToText status: $status');
        onListening(status == 'listening');
      },
      onError: (error) {
        log('SpeechToText error: $error');
        onListening(false);
      },
    );
  }

  Future<void> startListening({
    required Function(String) onResult,
    required Function(bool) onListening,
  }) async {
    final initialized = await _ensureInitialized(onListening: onListening);
    if (!initialized) {
      log('SpeechToText: could not initialize — microphone unavailable');
      return;
    }
    if (_speech.isListening) return;
    await _speech.listen(
      localeId: LocaleController.instance.locale.toLanguageTag(),
      onResult: (result) {
        onResult(result.recognizedWords);
        onListening(true);
      },
    );
    onListening(true);
  }

  Future<void> stopListening({Function(bool)? onListening}) async {
    if (_speech.isListening) {
      await _speech.stop();
    }
    onListening?.call(false);
  }
}
