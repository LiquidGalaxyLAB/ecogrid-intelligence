import 'dart:developer';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../config/localization/locale_controller.dart';

enum SttPermissionStatus { granted, denied, permanentlyDenied }

class SpeechToTextService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool get isListening => _speech.isListening;
  bool get isAvailable => _speech.isAvailable;
  
  Function(bool)? _currentOnListening;

  Future<SttPermissionStatus> _requestPermission() async {
    try {
      final status = await Permission.microphone.request();
      if (status.isGranted) return SttPermissionStatus.granted;
      if (status.isPermanentlyDenied) return SttPermissionStatus.permanentlyDenied;
      return SttPermissionStatus.denied;
    } catch (e) {
      log('Permission handler error (likely unsupported platform): $e');
      // If permission_handler fails, assume granted and let STT's initialize() handle it
      return SttPermissionStatus.granted;
    }
  }

  Future<bool> _ensureInitialized() async {
    if (_speech.isAvailable) return true;
    try {
      return await _speech.initialize(
        onStatus: (status) {
          log('SpeechToText status: $status');
          _currentOnListening?.call(status == 'listening');
        },
        onError: (error) {
          log('SpeechToText error: $error');
          _currentOnListening?.call(false);
        },
      );
    } catch (e) {
      log('SpeechToText initialize error: $e');
      return false;
    }
  }

  Future<SttPermissionStatus> startListening({
    required Function(String) onResult,
    required Function(bool) onListening,
    Function(double)? onSoundLevelChange,
  }) async {
    _currentOnListening = onListening;

    final permStatus = await _requestPermission();
    if (permStatus != SttPermissionStatus.granted) {
      return permStatus;
    }

    final initialized = await _ensureInitialized();
    if (!initialized) {
      log('SpeechToText: could not initialize — microphone unavailable');
      return SttPermissionStatus.denied;
    }

    if (_speech.isListening) return SttPermissionStatus.granted;

    _currentOnListening?.call(true);

    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(
        localeId: LocaleController.instance.locale.toLanguageTag(),
      ),
      onResult: (result) {
        onResult(result.recognizedWords);
      },
      onSoundLevelChange: onSoundLevelChange,
    );
    
    return SttPermissionStatus.granted;
  }

  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }
}
