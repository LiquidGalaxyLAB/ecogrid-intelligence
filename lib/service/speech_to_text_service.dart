import 'dart:developer';

import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Service wrapper for speech-to-text functionality.
///
/// Encapsulates all [stt.SpeechToText] lifecycle management.
/// Consumers provide callbacks for result updates and listening-state changes
/// rather than managing the STT instance themselves.
class SpeechToTextService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool get isListening => _speech.isListening;

  /// Returns true if the STT engine is available and initialized.
  bool get isAvailable => _speech.isAvailable;

  /// Ensures the engine is initialized. Returns [true] on success.
  Future<bool> _ensureInitialized({
    required Function(bool) onListening,
  }) async {
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

  /// Start listening. Invokes [onResult] with recognized words and
  /// [onListening] with the current listening state.
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
      onResult: (result) {
        onResult(result.recognizedWords);
        onListening(true);
      },
    );
    onListening(true);
  }

  /// Stop listening.
  Future<void> stopListening({Function(bool)? onListening}) async {
    if (_speech.isListening) {
      await _speech.stop();
    }
    onListening?.call(false);
  }
}
