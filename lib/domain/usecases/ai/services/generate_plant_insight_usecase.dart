import '../../../../core/resources/data_state.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../model/plant_context_payload.dart';
import '../../../repository/ai_repository.dart';

class GeneratePlantInsightUsecase
    implements UseCase<DataState<String>, Map<String, dynamic>> {
  final AIRepository _repository;

  GeneratePlantInsightUsecase(this._repository);

  @override
  Future<DataState<String>> call({Map<String, dynamic>? params}) {
    return _repository.generatePlantInsight(
      context: params!['context'] as PlantContextPayload,
      isUserInitiated: params['isUserInitiated'] as bool? ?? false,
    );
  }
}
