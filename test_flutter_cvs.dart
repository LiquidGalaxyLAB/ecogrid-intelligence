import 'package:ecogrid_intelligence/data/repository/cvs_repository_impl.dart';
import 'package:ecogrid_intelligence/data/local/data_sources/power_plant_local_ds.dart';
import 'package:ecogrid_intelligence/domain/model/region.dart';
import 'package:ecogrid_intelligence/core/enums/risk_level.dart';
import 'package:flutter/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final ds = PowerPlantLocalDataSource();
  final plants = await ds.getPlantsByRegion(Region.quickRegions.firstWhere((r) => r.id == 'india'));
  
  final repo = CvsRepositoryImpl();
  await repo.preComputeAllScores(plants);
  
  int high = repo.countPlantsByRiskLevel(plants, RiskLevel.high);
  int med = repo.countPlantsByRiskLevel(plants, RiskLevel.medium);
  int low = repo.countPlantsByRiskLevel(plants, RiskLevel.low);
  
  print('TEST OUTPUT -> High: \$high, Med: \$med, Low: \$low');
}
