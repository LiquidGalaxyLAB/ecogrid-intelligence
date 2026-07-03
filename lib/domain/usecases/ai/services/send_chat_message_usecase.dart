import '../../../../core/resources/data_state.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../repository/ai_repository.dart';

class SendChatMessageUsecase
    implements UseCase<DataState<String>, Map<String, dynamic>> {
  final AIRepository _repository;
  SendChatMessageUsecase(this._repository);
  @override
  Stream<DataState<String>> call({Map<String, dynamic>? params}) {
    return _repository.sendChatMessage(
      sessionId: params!['sessionId'] as String,
      message: params['message'] as String,
    );
  }
}
