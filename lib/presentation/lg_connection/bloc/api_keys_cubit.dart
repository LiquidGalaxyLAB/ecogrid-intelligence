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
  final String mapsKey;
  final KeyValidationStatus geminiStatus;
  final KeyValidationStatus mapsStatus;
  final bool isSaving;
  final bool isClearing;
  final String? message; // transient feedback (success / error text)

  const ApiKeysState({
    this.geminiKey = '',
    this.mapsKey = '',
    this.geminiStatus = KeyValidationStatus.idle,
    this.mapsStatus = KeyValidationStatus.idle,
    this.isSaving = false,
    this.isClearing = false,
    this.message,
  });

  /// Whether both keys have been validated successfully.
  bool get bothValid =>
      geminiStatus == KeyValidationStatus.valid &&
      mapsStatus == KeyValidationStatus.valid;

  /// Whether any validation is currently in-progress.
  bool get isValidating =>
      geminiStatus == KeyValidationStatus.validating ||
      mapsStatus == KeyValidationStatus.validating;

  ApiKeysState copyWith({
    String? geminiKey,
    String? mapsKey,
    KeyValidationStatus? geminiStatus,
    KeyValidationStatus? mapsStatus,
    bool? isSaving,
    bool? isClearing,
    String? message,
    bool clearMessage = false,
  }) {
    return ApiKeysState(
      geminiKey: geminiKey ?? this.geminiKey,
      mapsKey: mapsKey ?? this.mapsKey,
      geminiStatus: geminiStatus ?? this.geminiStatus,
      mapsStatus: mapsStatus ?? this.mapsStatus,
      isSaving: isSaving ?? this.isSaving,
      isClearing: isClearing ?? this.isClearing,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [
        geminiKey,
        mapsKey,
        geminiStatus,
        mapsStatus,
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
      final maps = await _repository.getGoogleMapsApiKey() ?? '';
      emit(state.copyWith(geminiKey: gemini, mapsKey: maps));
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

  void updateMapsKey(String value) {
    emit(state.copyWith(
      mapsKey: value,
      mapsStatus: KeyValidationStatus.idle,
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

  Future<void> validateMapsKey() async {
    if (state.mapsKey.trim().isEmpty) {
      emit(state.copyWith(
        mapsStatus: KeyValidationStatus.invalid,
        message: 'Google Maps API key cannot be empty.',
      ));
      return;
    }
    emit(state.copyWith(
      mapsStatus: KeyValidationStatus.validating,
      clearMessage: true,
    ));
    final result = await _repository.validateGoogleMapsApiKey(state.mapsKey);
    emit(state.copyWith(
      mapsStatus:
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
    if (state.mapsStatus != KeyValidationStatus.valid) {
      await validateMapsKey();
    }

    // Block save if either key is invalid.
    if (!state.bothValid) {
      emit(state.copyWith(
        message: 'Please fix invalid keys before saving.',
      ));
      return;
    }

    emit(state.copyWith(isSaving: true, clearMessage: true));
    try {
      await _repository.saveGeminiApiKey(state.geminiKey.trim());
      await _repository.saveGoogleMapsApiKey(state.mapsKey.trim());

      // Update the runtime cache so services pick up new keys immediately.
      ApiConstants.setGeminiApiKey(state.geminiKey.trim());
      ApiConstants.setGoogleMapsApiKey(state.mapsKey.trim());

      emit(state.copyWith(
        isSaving: false,
        message: 'API keys saved successfully.',
      ));
    } catch (e) {
      debugPrint('[EcoGrid] Failed to save API keys: $e');
      emit(state.copyWith(
        isSaving: false,
        message: 'Failed to save keys. Please try again.',
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
      ApiConstants.setGoogleMapsApiKey('');

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
