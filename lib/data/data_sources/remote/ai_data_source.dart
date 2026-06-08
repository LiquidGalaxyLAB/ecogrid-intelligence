/// Provider-agnostic interface for AI text generation.
///
/// All AI data sources (Groq, Gemini, OpenAI, etc.) must implement this
/// interface. Nothing outside of the data layer should import a specific
/// provider's package — everything goes through this abstraction.
abstract class AIDataSource {
  /// Generate a short, structured insight (uses the fast/small model).
  ///
  /// Used for: Insight Card, Scenario Explanation, Regional Analysis, Trend.
  Future<String> generateInsight({
    required String prompt,
    required String source,
  });

  /// Send a chat message with full conversation history (uses the large model).
  ///
  /// [history] is a list of messages in OpenAI-compatible format:
  /// `[{'role': 'system', 'content': '...'}, {'role': 'user', 'content': '...'}, ...]`
  ///
  /// Used for: Plant AI Chat.
  Future<String> sendChatMessage({
    required List<Map<String, String>> history,
    required String message,
    required String source,
  });
}
