import '../../../../core/resources/data_state.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../model/plant_context_payload.dart';
import '../../../repository/ai_repository.dart';

class GenerateScenarioAnalysisUsecase
    implements UseCase<DataState<String>, Map<String, dynamic>> {
  final AIRepository _repository;

  GenerateScenarioAnalysisUsecase(this._repository);

  @override
  Future<DataState<String>> call({Map<String, dynamic>? params}) {
    return _repository.generateScenarioAnalysis(
      context: params!['context'] as PlantContextPayload,
      projectedCvs: params['projectedCvs'] as double,
      scenarioType: params['scenarioType'] as String,
    );
  }
}
