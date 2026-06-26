import '../../../../core/resources/data_state.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../model/climate_data.dart';
import '../../../repository/climate_repository.dart';

class GetMultiYearTrendUsecase
    implements UseCase<DataState<List<ClimateData>>, Map<String, dynamic>> {
  final ClimateRepository _repository;

  GetMultiYearTrendUsecase(this._repository);

  @override
  Future<DataState<List<ClimateData>>> call({Map<String, dynamic>? params}) {
    return _repository.getMultiYearTrend(
      params!['lat'] as double,
      params['lon'] as double,
      startDate: params['startDate'] as DateTime,
      endDate: params['endDate'] as DateTime,
    );
  }
}
