import '../../../model/plant_context_payload.dart';
import '../../../repository/ai_repository.dart';

class StartPlantChatUsecase {
  final AIRepository repository;
  StartPlantChatUsecase(this.repository);
  String call({required PlantContextPayload context}) {
    return repository.startPlantChat(context: context);
  }
}
