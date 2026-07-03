import '../../../../core/resources/data_state.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../repository/ai_repository.dart';

class GenerateRegionalInsightUsecase
    implements UseCase<DataState<String>, Map<String, dynamic>> {
  final AIRepository _repository;
  GenerateRegionalInsightUsecase(this._repository);
  @override
  Stream<DataState<String>> call({Map<String, dynamic>? params}) {
    return _repository.generateRegionalInsight(
      regionName: params!['regionName'] as String,
      riskFilterName: params['riskFilterName'] as String,
      totalPlants: params['totalPlants'] as int,
      riskBreakdown: Map<String, int>.from(params['riskBreakdown'] as Map),
      dominantRiskDimension: params['dominantRiskDimension'] as String,
      commonHighRiskType: params['commonHighRiskType'] as String,
      top3Plants: List<String>.from(params['top3Plants'] as List),
    );
  }
}
