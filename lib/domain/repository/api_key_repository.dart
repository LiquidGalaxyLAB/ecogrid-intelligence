/// Contract for securely storing, retrieving, validating, and clearing
/// API keys used by runtime services (Gemini AI, Google Maps geocoding, etc.).
///
/// Implementations must persist keys in a secure manner (e.g. Android Keystore
/// via `flutter_secure_storage`) and never fall back to plain-text storage.
class KeyValidationResult {
  final bool isValid;
  final String message;
  const KeyValidationResult({required this.isValid, required this.message});
}

abstract interface class ApiKeyRepository {
  /// Returns the stored Gemini API key, or `null` if none is saved.
  Future<String?> getGeminiApiKey();

  /// Persists the Gemini API key in secure storage.
  Future<void> saveGeminiApiKey(String key);

  /// Validates a Gemini API key by making a lightweight API call.
  /// Returns a structured result with status and user-facing feedback.
  Future<KeyValidationResult> validateGeminiApiKey(String key);

  /// Removes both stored API keys from secure storage.
  Future<void> clearKeys();
}
