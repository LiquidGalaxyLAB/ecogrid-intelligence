import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/repository/api_key_repository.dart';

/// Secure-storage backed implementation of [ApiKeyRepository].
///
/// On the first read of each key, if secure storage is empty the value is
/// auto-migrated from the `.env` file so existing users aren't disrupted.
class ApiKeyRepositoryImpl implements ApiKeyRepository {
  final FlutterSecureStorage _secureStorage;

  static const _geminiKeyName = 'gemini_api_key';
  static const _mapsKeyName = 'google_maps_api_key';

  /// Tracks whether we've already attempted the one-time migration.
  bool _migrationDone = false;

  ApiKeyRepositoryImpl({required FlutterSecureStorage secureStorage})
      : _secureStorage = secureStorage;

  // ─── Read ───────────────────────────────────────────────────────────────────

  @override
  Future<String?> getGeminiApiKey() async {
    await _migrateFromEnvIfNeeded();
    return _secureStorage.read(key: _geminiKeyName);
  }

  @override
  Future<String?> getGoogleMapsApiKey() async {
    await _migrateFromEnvIfNeeded();
    return _secureStorage.read(key: _mapsKeyName);
  }

  // ─── Write ──────────────────────────────────────────────────────────────────

  @override
  Future<void> saveGeminiApiKey(String key) async {
    await _secureStorage.write(key: _geminiKeyName, value: key);
  }

  @override
  Future<void> saveGoogleMapsApiKey(String key) async {
    await _secureStorage.write(key: _mapsKeyName, value: key);
  }

  // ─── Clear ──────────────────────────────────────────────────────────────────

  @override
  Future<void> clearKeys() async {
    await _secureStorage.delete(key: _geminiKeyName);
    await _secureStorage.delete(key: _mapsKeyName);
  }

  // ─── Validation ─────────────────────────────────────────────────────────────

  @override
  Future<KeyValidationResult> validateGeminiApiKey(String key) async {
    if (key.trim().isEmpty) {
      return const KeyValidationResult(isValid: false, message: 'API key cannot be empty.');
    }
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://generativelanguage.googleapis.com/v1/models',
        queryParameters: {'key': key.trim()},
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );
      dio.close();
      if (response.statusCode == 200) {
        return const KeyValidationResult(isValid: true, message: 'Gemini key is valid.');
      }
      return const KeyValidationResult(isValid: false, message: 'Gemini key is invalid.');
    } on DioException catch (e) {
      debugPrint('[EcoGrid] Gemini key validation failed: $e');
      if (e.response?.statusCode == 400 || e.response?.statusCode == 403) {
        return const KeyValidationResult(isValid: false, message: 'The provided API key is invalid or restricted.');
      }
      return const KeyValidationResult(isValid: false, message: 'Network error during validation.');
    } catch (e) {
      debugPrint('[EcoGrid] Gemini key validation error: $e');
      return const KeyValidationResult(isValid: false, message: 'Unknown error occurred.');
    }
  }

  @override
  Future<KeyValidationResult> validateGoogleMapsApiKey(String key) async {
    if (key.trim().isEmpty) {
      return const KeyValidationResult(isValid: false, message: 'API key cannot be empty.');
    }
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://maps.googleapis.com/maps/api/geocode/json',
        queryParameters: {
          'address': 'test',
          'key': key.trim(),
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );
      dio.close();
      
      if (response.statusCode != 200) {
        return const KeyValidationResult(isValid: false, message: 'Server returned an error.');
      }
      
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        return const KeyValidationResult(isValid: false, message: 'Invalid response format.');
      }
      
      final status = data['status'] as String?;
      
      // OK and ZERO_RESULTS mean the key works perfectly.
      if (status == 'OK' || status == 'ZERO_RESULTS') {
        return const KeyValidationResult(isValid: true, message: 'Maps key is valid.');
      }
      
      // If the key is restricted to Android or missing REST API permissions,
      // Google returns REQUEST_DENIED. We check the exact error.
      if (status == 'REQUEST_DENIED') {
        final errorMessage = data['error_message'] as String? ?? '';
        
        // Only fail if Google explicitly says the key itself is fake.
        if (errorMessage.contains('The provided API key is invalid')) {
          return const KeyValidationResult(
            isValid: false, 
            message: 'Invalid key. Please provide a valid API key with "Maps SDK for Android" enabled.',
          );
        }
        
        // If it's restricted or missing specific REST permissions, it's still a real Maps key.
        // We just tell the user it's valid to avoid confusing them.
        return const KeyValidationResult(isValid: true, message: 'Maps key is valid.');
      }
      
      return const KeyValidationResult(
        isValid: false, 
        message: 'Invalid key. Please provide a valid API key with "Maps SDK for Android" enabled.',
      );
    } on DioException catch (e) {
      debugPrint('[EcoGrid] Maps key validation failed: $e');
      return const KeyValidationResult(isValid: false, message: 'Network error during validation.');
    } catch (e) {
      debugPrint('[EcoGrid] Maps key validation error: $e');
      return const KeyValidationResult(isValid: false, message: 'Unknown error occurred.');
    }
  }

  // ─── Migration ──────────────────────────────────────────────────────────────

  /// One-time migration: copies `.env` values into secure storage when keys
  /// don't yet exist there. This ensures existing users keep working after
  /// the refactor without re-entering credentials.
  Future<void> _migrateFromEnvIfNeeded() async {
    if (_migrationDone) return;
    _migrationDone = true;

    try {
      final existingGemini = await _secureStorage.read(key: _geminiKeyName);
      if (existingGemini == null || existingGemini.isEmpty) {
        final envGemini = dotenv.env['GEMINI_API_KEY'] ?? '';
        if (envGemini.isNotEmpty) {
          await _secureStorage.write(key: _geminiKeyName, value: envGemini);
          debugPrint('[EcoGrid] Migrated Gemini key from .env → secure storage');
        }
      }

      final existingMaps = await _secureStorage.read(key: _mapsKeyName);
      if (existingMaps == null || existingMaps.isEmpty) {
        final envMaps = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
        if (envMaps.isNotEmpty) {
          await _secureStorage.write(key: _mapsKeyName, value: envMaps);
          debugPrint('[EcoGrid] Migrated Maps key from .env → secure storage');
        }
      }
    } catch (e) {
      debugPrint('[EcoGrid] .env → secure storage migration failed: $e');
    }
  }
}
