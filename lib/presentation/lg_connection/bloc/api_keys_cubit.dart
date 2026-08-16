import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/api_constants.dart';
import '../../../domain/repository/api_key_repository.dart';

// ─── Validation status per key ──────────────────────────────────────────────

enum KeyValidationStatus { idle, validating, valid, invalid }

// ─── State ──────────────────────────────────────────────────────────────────

class ApiKeysState extends Equatable {
  final String geminiKey;
  final KeyValidationStatus geminiStatus;
  final bool isSaving;
  final bool isClearing;
  final String? message; // transient feedback (success / error text)

  const ApiKeysState({
    this.geminiKey = '',
    this.geminiStatus = KeyValidationStatus.idle,
    this.isSaving = false,
    this.isClearing = false,
    this.message,
  });

  /// Whether both keys have been validated successfully.
  bool get isValid =>
      geminiStatus == KeyValidationStatus.valid;

  /// Whether any validation is currently in-progress.
  bool get isValidating =>
      geminiStatus == KeyValidationStatus.validating;

  ApiKeysState copyWith({
    String? geminiKey,
    KeyValidationStatus? geminiStatus,
    KeyValidationStatus? mapsStatus,
    bool? isSaving,
    bool? isClearing,
    String? message,
    bool clearMessage = false,
  }) {
    return ApiKeysState(
      geminiKey: geminiKey ?? this.geminiKey,
      geminiStatus: geminiStatus ?? this.geminiStatus,
      isSaving: isSaving ?? this.isSaving,
      isClearing: isClearing ?? this.isClearing,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [
        geminiKey,
        geminiStatus,
        isSaving,
        isClearing,
        message,
      ];
}

// ─── Cubit ──────────────────────────────────────────────────────────────────

class ApiKeysCubit extends Cubit<ApiKeysState> {
  final ApiKeyRepository _repository;

  ApiKeysCubit({required ApiKeyRepository repository})
      : _repository = repository,
        super(const ApiKeysState()); // ignore: prefer_initializing_formals

  // ── Load previously saved keys ──────────────────────────────────────────

  Future<void> loadKeys() async {
    try {
      final gemini = await _repository.getGeminiApiKey() ?? '';
      emit(state.copyWith(geminiKey: gemini));
    } catch (e) {
      debugPrint('[EcoGrid] Failed to load API keys: $e');
    }
  }

  // ── Field updates (reset validation status on change) ───────────────────

  void updateGeminiKey(String value) {
    emit(state.copyWith(
      geminiKey: value,
      geminiStatus: KeyValidationStatus.idle,
      clearMessage: true,
    ));
  }

  // ── Independent validation ──────────────────────────────────────────────

  Future<void> validateGeminiKey() async {
    if (state.geminiKey.trim().isEmpty) {
      emit(state.copyWith(
        geminiStatus: KeyValidationStatus.invalid,
        message: 'Gemini API key cannot be empty.',
      ));
      return;
    }
    emit(state.copyWith(
      geminiStatus: KeyValidationStatus.validating,
      clearMessage: true,
    ));
    final result = await _repository.validateGeminiApiKey(state.geminiKey);
    emit(state.copyWith(
      geminiStatus:
          result.isValid ? KeyValidationStatus.valid : KeyValidationStatus.invalid,
      message: result.message,
    ));
  }


  // ── Save (validates first, only saves valid keys) ───────────────────────

  Future<void> saveKeys() async {
    // Validate both keys first if not already validated.
    if (state.geminiStatus != KeyValidationStatus.valid) {
      await validateGeminiKey();
    }

    // Block save if either key is invalid.
    if (!state.isValid) {
      emit(state.copyWith(
        message: 'Please fix invalid key before saving.',
      ));
      return;
    }

    emit(state.copyWith(isSaving: true, clearMessage: true));
    try {
      await _repository.saveGeminiApiKey(state.geminiKey.trim());
      // Update the runtime cache so services pick up new keys immediately.
      ApiConstants.setGeminiApiKey(state.geminiKey.trim());
      emit(state.copyWith(
        isSaving: false,
        message: 'API key saved successfully.',
      ));
    } catch (e) {
      debugPrint('[EcoGrid] Failed to save API key: $e');
      emit(state.copyWith(
        isSaving: false,
        message: 'Failed to save key. Please try again.',
      ));
    }
  }

  // ── Clear stored keys ───────────────────────────────────────────────────

  Future<void> clearKeys() async {
    emit(state.copyWith(isClearing: true, clearMessage: true));
    try {
      await _repository.clearKeys();

      // Clear runtime cache as well.
      ApiConstants.setGeminiApiKey('');
      emit(const ApiKeysState(message: 'API keys cleared.'));
    } catch (e) {
      debugPrint('[EcoGrid] Failed to clear API keys: $e');
      emit(state.copyWith(
        isClearing: false,
        message: 'Failed to clear keys.',
      ));
    }
  }
}
