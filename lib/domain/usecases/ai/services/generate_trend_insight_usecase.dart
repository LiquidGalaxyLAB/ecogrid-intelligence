import '../../../../core/resources/data_state.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../model/plant_context_payload.dart';
import '../../../repository/ai_repository.dart';

class GenerateTrendInsightUsecase
    implements UseCase<DataState<String>, PlantContextPayload> {
  final AIRepository _repository;

  GenerateTrendInsightUsecase(this._repository);

  @override
  Future<DataState<String>> call({PlantContextPayload? params}) {
    return _repository.generateTrendInsight(context: params!);
  }
}
