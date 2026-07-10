import '../../../core/resources/network_state.dart';

abstract class AIDataSource {
  Stream<NetworkState<String>> generateInsight({
    required String prompt,
    required String source,
  });
  Stream<NetworkState<String>> sendChatMessage({
    required List<Map<String, String>> history,
    required String message,
    required String source,
  });
}
